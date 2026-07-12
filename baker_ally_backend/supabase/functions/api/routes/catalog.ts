import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, asc, desc, eq, inArray, ne, sql } from "npm:drizzle-orm";

import { rateLimitMiddleware } from "../middleware/rateLimit.ts";
import { db } from "../lib/db.ts";
import { categories, productImages, products, productVariants, subCategories } from "../db/schema.ts";

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

  const rows = await db
    .select()
    .from(products)
    .where(and(
      eq(products.subCategoryId, product.subCategoryId),
      eq(products.isActive, true),
      ne(products.id, id),
    ))
    .orderBy(desc(products.isTrending), desc(products.createdAt))
    .limit(10);

  const data = await attachDisplayInfo(rows);
  return c.json({ data });
});
