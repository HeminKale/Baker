import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, asc, desc, eq, inArray, notInArray, sql } from "npm:drizzle-orm";

import { rateLimitMiddleware } from "../middleware/rateLimit.ts";
import { db } from "../lib/db.ts";
import {
  categories,
  productCrossSell,
  productImages,
  products,
  productVariants,
  subCategories,
} from "../db/schema.ts";

export const catalogRoute = new Hono();

// Public browsing routes (00_common_architecture.md §16) -- no authMiddleware.
// Cart/wishlist-specific routes live in routes/wishlist.ts behind auth.

catalogRoute.get("/categories", async (c) => {
  const cats = await db
    .select()
    .from(categories)
    .where(eq(categories.isActive, true))
    .orderBy(asc(categories.sortOrder));

  const counts = await db
    .select({ categoryId: subCategories.categoryId, count: sql<number>`count(*)::int` })
    .from(subCategories)
    .where(eq(subCategories.isActive, true))
    .groupBy(subCategories.categoryId);

  const countByCategory = new Map(counts.map((row) => [row.categoryId, row.count]));

  return c.json({
    data: cats.map((cat) => ({ ...cat, subCategoryCount: countByCategory.get(cat.id) ?? 0 })),
  });
});

catalogRoute.get("/categories/:id/subcategories", async (c) => {
  const categoryId = c.req.param("id");

  const subs = await db
    .select()
    .from(subCategories)
    .where(and(eq(subCategories.categoryId, categoryId), eq(subCategories.isActive, true)))
    .orderBy(asc(subCategories.sortOrder));

  return c.json({ data: subs });
});

// Attaches each product's "display" variant (lowest sort_order active
// variant) and "display" image (primary product-level image, else first by
// sort_order) so list/related responses render tiles without N+1 calls --
// see Planning docs/Architecture/02_catalog_tab.md §5 (Product Tile spec).
export async function attachDisplayInfo(productRows: (typeof products.$inferSelect)[]) {
  if (productRows.length === 0) return [];
  const productIds = productRows.map((p) => p.id);

  const variants = await db
    .select()
    .from(productVariants)
    .where(and(inArray(productVariants.productId, productIds), eq(productVariants.isActive, true)))
    .orderBy(asc(productVariants.sortOrder));

  const images = await db
    .select()
    .from(productImages)
    .where(inArray(productImages.productId, productIds))
    .orderBy(asc(productImages.sortOrder));

  const displayVariantByProduct = new Map<string, typeof productVariants.$inferSelect>();
  for (const variant of variants) {
    if (!displayVariantByProduct.has(variant.productId)) {
      displayVariantByProduct.set(variant.productId, variant);
    }
  }

  const displayImageByProduct = new Map<string, typeof productImages.$inferSelect>();
  for (const image of images) {
    const existing = displayImageByProduct.get(image.productId);
    if (!existing || (image.isPrimary && !existing.isPrimary)) {
      displayImageByProduct.set(image.productId, image);
    }
  }

  return productRows.map((product) => ({
    ...product,
    displayVariant: displayVariantByProduct.get(product.id) ?? null,
    displayImageUrl: displayImageByProduct.get(product.id)?.publicUrl ?? null,
  }));
}

// "You Might Also Like" slotting (Milestone 6 / 6.8) -- shared by this
// file's own /products/:id/related and cart.ts's /checkout/recommendations.
// Positions 1-4: algorithmic (same subcategory pool, trending/recency).
// Positions 5-7: curated product_cross_sell picks for sourceProductIds,
// round-robin across sources by sort_order; backfilled algorithmically if
// fewer than 3 curated picks exist. Positions 8-10: algorithmic continuation.
// Total stays capped at 10 -- when no curation exists this reproduces the
// old single top-10-by-trending/recency query exactly (fully backward
// compatible), since backfill/continuation walk the same ordered pool
// without skipping anything but already-picked ids.
export async function buildRecommendations(params: {
  subCategoryIds: string[];
  sourceProductIds: string[];
}) {
  const { subCategoryIds, sourceProductIds } = params;
  if (subCategoryIds.length === 0) return [];

  const selected = new Set<string>(sourceProductIds);

  const algoPool = await db
    .select()
    .from(products)
    .where(
      and(
        inArray(products.subCategoryId, subCategoryIds),
        eq(products.isActive, true),
        notInArray(products.id, sourceProductIds),
      ),
    )
    .orderBy(desc(products.isTrending), desc(products.createdAt))
    .limit(50);

  const take = (from: (typeof algoPool)[number][], count: number) => {
    const picked: (typeof algoPool)[number][] = [];
    for (const p of from) {
      if (picked.length >= count) break;
      if (selected.has(p.id)) continue;
      picked.push(p);
      selected.add(p.id);
    }
    return picked;
  };

  const positions1to4 = take(algoPool, 4);

  // Round-robin curated picks across every source product (checkout can have
  // several cart items each with their own curation) -- judgment call from
  // the 6.8 plan, deduped against the cart and against each other.
  const curatedRows = sourceProductIds.length
    ? await db
        .select()
        .from(productCrossSell)
        .where(inArray(productCrossSell.sourceProductId, sourceProductIds))
        .orderBy(asc(productCrossSell.sortOrder))
    : [];
  const bySource = new Map<string, typeof curatedRows>();
  for (const row of curatedRows) {
    const list = bySource.get(row.sourceProductId) ?? [];
    list.push(row);
    bySource.set(row.sourceProductId, list);
  }
  const sourceOrder = sourceProductIds.filter((id) => bySource.has(id));

  const curatedIds: string[] = [];
  for (let round = 0; curatedIds.length < 3 && sourceOrder.some((id) => round < bySource.get(id)!.length); round++) {
    for (const srcId of sourceOrder) {
      if (curatedIds.length >= 3) break;
      const list = bySource.get(srcId)!;
      if (round >= list.length) continue;
      const candidateId = list[round].recommendedProductId;
      if (selected.has(candidateId)) continue;
      curatedIds.push(candidateId);
      selected.add(candidateId);
    }
  }

  const curatedProductRows = curatedIds.length
    ? await db.select().from(products).where(inArray(products.id, curatedIds))
    : [];
  const curatedById = new Map(curatedProductRows.map((p) => [p.id, p]));
  const positions5to7 = curatedIds.map((id) => curatedById.get(id)).filter((p): p is typeof products.$inferSelect => !!p);

  const backfill = take(algoPool, 3 - positions5to7.length);
  const positions8to10 = take(algoPool, 3);

  return attachDisplayInfo([...positions1to4, ...positions5to7, ...backfill, ...positions8to10]);
}

const listProductsQuerySchema = z.object({
  categoryId: z.string().uuid().optional(),
  subCategoryId: z.string().uuid().optional(),
  q: z.string().min(1).max(200).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

catalogRoute.get(
  "/products",
  rateLimitMiddleware,
  zValidator("query", listProductsQuerySchema),
  async (c) => {
    const { categoryId, subCategoryId, q, page, limit: limitParam } = c.req.valid("query");
    // categoryId gets a higher default limit so Level 2 (02_catalog_tab.md §3)
    // can render every subcategory's products in one call without having to
    // stitch cross-subcategory pagination back together client-side.
    const limit = limitParam ?? (categoryId ? 40 : 20);
    const offset = (page - 1) * limit;

    let rows: (typeof products.$inferSelect)[];
    let total: number;

    if (q) {
      const whereClause = and(
        eq(products.isActive, true),
        sql`search_vector @@ plainto_tsquery('english', ${q})`,
      );
      rows = await db
        .select()
        .from(products)
        .where(whereClause)
        .orderBy(sql`ts_rank(search_vector, plainto_tsquery('english', ${q})) DESC`, desc(products.isTrending))
        .limit(limit)
        .offset(offset);
      const [{ count }] = await db.select({ count: sql<number>`count(*)::int` }).from(products).where(whereClause);
      total = count;
    } else if (subCategoryId) {
      const whereClause = and(eq(products.subCategoryId, subCategoryId), eq(products.isActive, true));
      rows = await db.select().from(products).where(whereClause).orderBy(asc(products.sortOrder)).limit(limit).offset(offset);
      const [{ count }] = await db.select({ count: sql<number>`count(*)::int` }).from(products).where(whereClause);
      total = count;
    } else if (categoryId) {
      const whereClause = and(eq(subCategories.categoryId, categoryId), eq(products.isActive, true));
      rows = await db
        .select({
          id: products.id,
          subCategoryId: products.subCategoryId,
          name: products.name,
          description: products.description,
          isActive: products.isActive,
          isTrending: products.isTrending,
          sortOrder: products.sortOrder,
          createdAt: products.createdAt,
          updatedAt: products.updatedAt,
        })
        .from(products)
        .innerJoin(subCategories, eq(products.subCategoryId, subCategories.id))
        .where(whereClause)
        .orderBy(asc(subCategories.sortOrder), asc(products.sortOrder))
        .limit(limit)
        .offset(offset);
      const [{ count }] = await db
        .select({ count: sql<number>`count(*)::int` })
        .from(products)
        .innerJoin(subCategories, eq(products.subCategoryId, subCategories.id))
        .where(whereClause);
      total = count;
    } else {
      return c.json(
        { error: { code: "MISSING_FILTER", message: "One of categoryId, subCategoryId or q is required" } },
        400,
      );
    }

    const data = await attachDisplayInfo(rows);
    return c.json({ data, meta: { page, limit, total } });
  },
);

catalogRoute.get("/products/:id", async (c) => {
  const id = c.req.param("id");

  const [row] = await db
    .select({
      product: products,
      subCategoryName: subCategories.name,
      categoryName: categories.name,
    })
    .from(products)
    .innerJoin(subCategories, eq(products.subCategoryId, subCategories.id))
    .innerJoin(categories, eq(subCategories.categoryId, categories.id))
    .where(and(eq(products.id, id), eq(products.isActive, true)))
    .limit(1);

  if (!row) {
    return c.json({ error: { code: "PRODUCT_NOT_FOUND", message: "Product not found" } }, 404);
  }

  const variants = await db
    .select()
    .from(productVariants)
    .where(and(eq(productVariants.productId, id), eq(productVariants.isActive, true)))
    .orderBy(asc(productVariants.sortOrder));

  const images = await db
    .select()
    .from(productImages)
    .where(eq(productImages.productId, id))
    .orderBy(asc(productImages.sortOrder));

  return c.json({
    data: {
      ...row.product,
      subCategoryName: row.subCategoryName,
      categoryName: row.categoryName,
      variants,
      images,
    },
  });
});

catalogRoute.get("/products/:id/related", async (c) => {
  const id = c.req.param("id");

  const [product] = await db.select().from(products).where(eq(products.id, id)).limit(1);
  if (!product) {
    return c.json({ error: { code: "PRODUCT_NOT_FOUND", message: "Product not found" } }, 404);
  }

  const data = await buildRecommendations({
    subCategoryIds: [product.subCategoryId],
    sourceProductIds: [id],
  });
  return c.json({ data });
});
