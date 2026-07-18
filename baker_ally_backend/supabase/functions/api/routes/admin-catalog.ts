import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, asc, desc, eq, ilike, sql } from "npm:drizzle-orm";

import { adminOrStaffMiddleware, authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { supabaseAdmin } from "../lib/supabaseAdmin.ts";
import {
  categories,
  productCrossSell,
  productImages,
  products,
  productVariants,
  subCategories,
  wishlists,
} from "../db/schema.ts";

export const adminCatalogRoute = new Hono<AuthEnv>();

// Product/Category/Stock management -- Staff scope (6.3 plan). Discounts and
// Users get their own admin-only route files.
adminCatalogRoute.use("/admin/*", authMiddleware, adminOrStaffMiddleware);

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

// Not in the original endpoint list, but the categories management page
// (6.3 Next.js) can't list rows to edit without this -- the public
// GET /categories filters isActive=true, which would hide inactive ones from
// admin. Kept minimal (no pagination -- category counts are small).
adminCatalogRoute.get("/admin/categories", async (c) => {
  const rows = await db.select().from(categories).orderBy(asc(categories.sortOrder));
  return c.json({ data: rows });
});

const categorySchema = z.object({
  name: z.string().min(1).max(200),
  imageUrl: z.string().url().max(500).optional(),
  sortOrder: z.number().int().optional(),
  isActive: z.boolean().optional(),
});

adminCatalogRoute.post("/admin/categories", zValidator("json", categorySchema), async (c) => {
  const body = c.req.valid("json");
  const [created] = await db
    .insert(categories)
    .values({
      name: body.name,
      imageUrl: body.imageUrl ?? null,
      sortOrder: body.sortOrder ?? 0,
      isActive: body.isActive ?? true,
    })
    .returning();
  return c.json({ data: created }, 201);
});

const updateCategorySchema = categorySchema.partial();

adminCatalogRoute.put("/admin/categories/:id", zValidator("json", updateCategorySchema), async (c) => {
  const id = c.req.param("id");
  const body = c.req.valid("json");

  const [updated] = await db
    .update(categories)
    .set({
      ...(body.name !== undefined ? { name: body.name } : {}),
      ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
      ...(body.sortOrder !== undefined ? { sortOrder: body.sortOrder } : {}),
      ...(body.isActive !== undefined ? { isActive: body.isActive } : {}),
    })
    .where(eq(categories.id, id))
    .returning();

  if (!updated) {
    return c.json({ error: { code: "CATEGORY_NOT_FOUND", message: "Category not found" } }, 404);
  }
  return c.json({ data: updated });
});

// ---------------------------------------------------------------------------
// Sub-categories
// ---------------------------------------------------------------------------

const subCategoryQuerySchema = z.object({ categoryId: z.string().uuid().optional() });

adminCatalogRoute.get(
  "/admin/sub-categories",
  zValidator("query", subCategoryQuerySchema),
  async (c) => {
    const { categoryId } = c.req.valid("query");
    const rows = await db
      .select()
      .from(subCategories)
      .where(categoryId ? eq(subCategories.categoryId, categoryId) : undefined)
      .orderBy(asc(subCategories.sortOrder));
    return c.json({ data: rows });
  },
);

const subCategorySchema = z.object({
  categoryId: z.string().uuid(),
  name: z.string().min(1).max(200),
  imageUrl: z.string().url().max(500).optional(),
  sortOrder: z.number().int().optional(),
  isActive: z.boolean().optional(),
});

adminCatalogRoute.post("/admin/sub-categories", zValidator("json", subCategorySchema), async (c) => {
  const body = c.req.valid("json");
  const [created] = await db
    .insert(subCategories)
    .values({
      categoryId: body.categoryId,
      name: body.name,
      imageUrl: body.imageUrl ?? null,
      sortOrder: body.sortOrder ?? 0,
      isActive: body.isActive ?? true,
    })
    .returning();
  return c.json({ data: created }, 201);
});

const updateSubCategorySchema = subCategorySchema.partial();

adminCatalogRoute.put(
  "/admin/sub-categories/:id",
  zValidator("json", updateSubCategorySchema),
  async (c) => {
    const id = c.req.param("id");
    const body = c.req.valid("json");

    const [updated] = await db
      .update(subCategories)
      .set({
        ...(body.categoryId !== undefined ? { categoryId: body.categoryId } : {}),
        ...(body.name !== undefined ? { name: body.name } : {}),
        ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
        ...(body.sortOrder !== undefined ? { sortOrder: body.sortOrder } : {}),
        ...(body.isActive !== undefined ? { isActive: body.isActive } : {}),
      })
      .where(eq(subCategories.id, id))
      .returning();

    if (!updated) {
      return c.json({ error: { code: "SUBCATEGORY_NOT_FOUND", message: "Sub-category not found" } }, 404);
    }
    return c.json({ data: updated });
  },
);

// ---------------------------------------------------------------------------
// Products
// ---------------------------------------------------------------------------

const listProductsQuerySchema = z.object({
  categoryId: z.string().uuid().optional(),
  subCategoryId: z.string().uuid().optional(),
  q: z.string().min(1).max(200).optional(),
  active: z
    .enum(["true", "false"])
    .optional()
    .transform((v) => (v === undefined ? undefined : v === "true")),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// Unlike the public /products list, no filter is required here -- admin can
// browse everything -- and inactive products are included (active=undefined
// means "don't filter by status" so both show up).
adminCatalogRoute.get(
  "/admin/products",
  zValidator("query", listProductsQuerySchema),
  async (c) => {
    const { categoryId, subCategoryId, q, active, page, limit } = c.req.valid("query");
    const offset = (page - 1) * limit;

    const conditions = [];
    if (subCategoryId) conditions.push(eq(products.subCategoryId, subCategoryId));
    if (active !== undefined) conditions.push(eq(products.isActive, active));
    if (q) conditions.push(ilike(products.name, `%${q}%`));

    const needsCategoryJoin = Boolean(categoryId);
    if (categoryId) conditions.push(eq(subCategories.categoryId, categoryId));
    const whereClause = conditions.length ? and(...conditions) : undefined;

    const baseQuery = needsCategoryJoin
      ? db.select({ product: products }).from(products).innerJoin(subCategories, eq(products.subCategoryId, subCategories.id))
      : db.select({ product: products }).from(products);

    const rows = await baseQuery
      .where(whereClause)
      .orderBy(desc(products.createdAt))
      .limit(limit)
      .offset(offset);

    const countQuery = needsCategoryJoin
      ? db.select({ count: sql<number>`count(*)::int` }).from(products).innerJoin(subCategories, eq(products.subCategoryId, subCategories.id))
      : db.select({ count: sql<number>`count(*)::int` }).from(products);
    const [{ count }] = await countQuery.where(whereClause);

    return c.json({ data: rows.map((r) => r.product), meta: { page, limit, total: count } });
  },
);

adminCatalogRoute.get("/admin/products/:id", async (c) => {
  const id = c.req.param("id");

  const [row] = await db
    .select({ product: products, subCategoryName: subCategories.name, categoryName: categories.name })
    .from(products)
    .innerJoin(subCategories, eq(products.subCategoryId, subCategories.id))
    .innerJoin(categories, eq(subCategories.categoryId, categories.id))
    .where(eq(products.id, id))
    .limit(1);

  if (!row) {
    return c.json({ error: { code: "PRODUCT_NOT_FOUND", message: "Product not found" } }, 404);
  }

  // Unlike the public endpoint, admin sees inactive variants/images too.
  const variants = await db
    .select()
    .from(productVariants)
    .where(eq(productVariants.productId, id))
    .orderBy(asc(productVariants.sortOrder));

  const images = await db
    .select()
    .from(productImages)
    .where(eq(productImages.productId, id))
    .orderBy(asc(productImages.sortOrder));

  return c.json({
    data: { ...row.product, subCategoryName: row.subCategoryName, categoryName: row.categoryName, variants, images },
  });
});

const createProductSchema = z.object({
  subCategoryId: z.string().uuid(),
  name: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  isActive: z.boolean().optional(),
  isTrending: z.boolean().optional(),
  sortOrder: z.number().int().optional(),
});

adminCatalogRoute.post("/admin/products", zValidator("json", createProductSchema), async (c) => {
  const body = c.req.valid("json");
  const [created] = await db
    .insert(products)
    .values({
      subCategoryId: body.subCategoryId,
      name: body.name,
      description: body.description ?? null,
      isActive: body.isActive ?? true,
      isTrending: body.isTrending ?? false,
      sortOrder: body.sortOrder ?? 0,
    })
    .returning();
  return c.json({ data: created }, 201);
});

const updateProductSchema = createProductSchema.partial();

adminCatalogRoute.put("/admin/products/:id", zValidator("json", updateProductSchema), async (c) => {
  const id = c.req.param("id");
  const body = c.req.valid("json");

  const [updated] = await db
    .update(products)
    .set({
      ...(body.subCategoryId !== undefined ? { subCategoryId: body.subCategoryId } : {}),
      ...(body.name !== undefined ? { name: body.name } : {}),
      ...(body.description !== undefined ? { description: body.description } : {}),
      ...(body.isActive !== undefined ? { isActive: body.isActive } : {}),
      ...(body.isTrending !== undefined ? { isTrending: body.isTrending } : {}),
      ...(body.sortOrder !== undefined ? { sortOrder: body.sortOrder } : {}),
      updatedAt: new Date(),
    })
    .where(eq(products.id, id))
    .returning();

  if (!updated) {
    return c.json({ error: { code: "PRODUCT_NOT_FOUND", message: "Product not found" } }, 404);
  }
  return c.json({ data: updated });
});

// ---------------------------------------------------------------------------
// Variants
// ---------------------------------------------------------------------------

const createVariantSchema = z.object({
  name: z.string().min(1).max(200),
  sku: z.string().min(1).max(100),
  originalPrice: z.number().int().min(0),
  currentPrice: z.number().int().min(0),
  stockQty: z.number().int().min(0).optional(),
  isActive: z.boolean().optional(),
  sortOrder: z.number().int().optional(),
});

adminCatalogRoute.post(
  "/admin/products/:id/variants",
  zValidator("json", createVariantSchema),
  async (c) => {
    const productId = c.req.param("id");
    const body = c.req.valid("json");

    const [product] = await db.select({ id: products.id }).from(products).where(eq(products.id, productId)).limit(1);
    if (!product) {
      return c.json({ error: { code: "PRODUCT_NOT_FOUND", message: "Product not found" } }, 404);
    }

    try {
      const [created] = await db
        .insert(productVariants)
        .values({
          productId,
          name: body.name,
          sku: body.sku,
          originalPrice: body.originalPrice,
          currentPrice: body.currentPrice,
          stockQty: body.stockQty ?? 0,
          isActive: body.isActive ?? true,
          sortOrder: body.sortOrder ?? 0,
        })
        .returning();
      return c.json({ data: created }, 201);
    } catch (err) {
      if (err instanceof Error && err.message.includes("product_variants_sku")) {
        return c.json({ error: { code: "DUPLICATE_SKU", message: "SKU already in use" } }, 409);
      }
      throw err;
    }
  },
);

// name/sku/prices/isActive/sortOrder only -- stock_qty is deliberately not
// editable here, it goes through PATCH .../stock below (kept separate so
// stock changes always follow the same restock-trigger-aware path).
const updateVariantSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  sku: z.string().min(1).max(100).optional(),
  originalPrice: z.number().int().min(0).optional(),
  currentPrice: z.number().int().min(0).optional(),
  isActive: z.boolean().optional(),
  sortOrder: z.number().int().optional(),
});

adminCatalogRoute.put("/admin/variants/:id", zValidator("json", updateVariantSchema), async (c) => {
  const id = c.req.param("id");
  const body = c.req.valid("json");

  try {
    const [updated] = await db
      .update(productVariants)
      .set({
        ...(body.name !== undefined ? { name: body.name } : {}),
        ...(body.sku !== undefined ? { sku: body.sku } : {}),
        ...(body.originalPrice !== undefined ? { originalPrice: body.originalPrice } : {}),
        ...(body.currentPrice !== undefined ? { currentPrice: body.currentPrice } : {}),
        ...(body.isActive !== undefined ? { isActive: body.isActive } : {}),
        ...(body.sortOrder !== undefined ? { sortOrder: body.sortOrder } : {}),
      })
      .where(eq(productVariants.id, id))
      .returning();

    if (!updated) {
      return c.json({ error: { code: "VARIANT_NOT_FOUND", message: "Variant not found" } }, 404);
    }
    return c.json({ data: updated });
  } catch (err) {
    if (err instanceof Error && err.message.includes("product_variants_sku")) {
      return c.json({ error: { code: "DUPLICATE_SKU", message: "SKU already in use" } }, 409);
    }
    throw err;
  }
});

const stockSchema = z.object({ stockQty: z.number().int().min(0) });

// Plain SET, not a decrement -- checkout.ts's guarded decrement is a
// different concern (concurrent-safe purchase). This is an admin correcting
// the count directly. Going 0 -> positive fires the restock trigger (6.5).
adminCatalogRoute.patch("/admin/variants/:id/stock", zValidator("json", stockSchema), async (c) => {
  const id = c.req.param("id");
  const { stockQty } = c.req.valid("json");

  const [updated] = await db
    .update(productVariants)
    .set({ stockQty })
    .where(eq(productVariants.id, id))
    .returning();

  if (!updated) {
    return c.json({ error: { code: "VARIANT_NOT_FOUND", message: "Variant not found" } }, 404);
  }
  return c.json({ data: updated });
});

const bulkStockSchema = z.object({
  updates: z.array(z.object({ variantId: z.string().uuid(), stockQty: z.number().int().min(0) })).min(1).max(200),
});

adminCatalogRoute.post("/admin/variants/bulk-stock", zValidator("json", bulkStockSchema), async (c) => {
  const { updates } = c.req.valid("json");

  const results = await db.transaction(async (tx) => {
    const updated = [];
    for (const u of updates) {
      const [row] = await tx
        .update(productVariants)
        .set({ stockQty: u.stockQty })
        .where(eq(productVariants.id, u.variantId))
        .returning({ id: productVariants.id, stockQty: productVariants.stockQty });
      if (row) updated.push(row);
    }
    return updated;
  });

  return c.json({ data: { updated: results.length, variants: results } });
});

// ---------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------

const IMAGES_BUCKET = "product-images";

adminCatalogRoute.post("/admin/products/:id/images", async (c) => {
  const productId = c.req.param("id");

  const [product] = await db.select({ id: products.id }).from(products).where(eq(products.id, productId)).limit(1);
  if (!product) {
    return c.json({ error: { code: "PRODUCT_NOT_FOUND", message: "Product not found" } }, 404);
  }

  const body = await c.req.parseBody();
  const file = body["file"];
  if (!(file instanceof File) || !file.type.startsWith("image/")) {
    return c.json({ error: { code: "INVALID_FILE", message: "A file field with an image is required" } }, 400);
  }
  const variantId = typeof body["variantId"] === "string" && body["variantId"] ? body["variantId"] : null;
  const isPrimary = body["isPrimary"] === "true";
  const sortOrder = typeof body["sortOrder"] === "string" ? Number(body["sortOrder"]) || 0 : 0;

  const ext = file.name.includes(".") ? file.name.split(".").pop() : "jpg";
  const storagePath = `${productId}/${crypto.randomUUID()}.${ext}`;

  const { error: uploadError } = await supabaseAdmin.storage
    .from(IMAGES_BUCKET)
    .upload(storagePath, file, { contentType: file.type, upsert: false });
  if (uploadError) {
    return c.json({ error: { code: "UPLOAD_FAILED", message: uploadError.message } }, 500);
  }

  const { data: publicUrlData } = supabaseAdmin.storage.from(IMAGES_BUCKET).getPublicUrl(storagePath);

  if (isPrimary) {
    // Single primary image per product, same enforced-single-default pattern
    // as addresses.isDefault.
    await db.update(productImages).set({ isPrimary: false }).where(eq(productImages.productId, productId));
  }

  const [created] = await db
    .insert(productImages)
    .values({
      productId,
      variantId,
      storagePath,
      publicUrl: publicUrlData.publicUrl,
      sortOrder,
      isPrimary,
    })
    .returning();

  return c.json({ data: created }, 201);
});

adminCatalogRoute.delete("/admin/products/:id/images/:imgId", async (c) => {
  const productId = c.req.param("id");
  const imgId = c.req.param("imgId");

  const [image] = await db
    .select()
    .from(productImages)
    .where(and(eq(productImages.id, imgId), eq(productImages.productId, productId)))
    .limit(1);
  if (!image) {
    return c.json({ error: { code: "IMAGE_NOT_FOUND", message: "Image not found" } }, 404);
  }

  await db.delete(productImages).where(eq(productImages.id, imgId));
  await supabaseAdmin.storage.from(IMAGES_BUCKET).remove([image.storagePath]);

  return c.json({ data: { ok: true } });
});

// ---------------------------------------------------------------------------
// Wishlist insights
// ---------------------------------------------------------------------------

const wishlistInsightsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// Most-wishlisted variants, most in-demand first -- surfaces which
// out-of-stock items are worth restocking first (ties into 6.5's back-in-stock
// push). No separate endpoint needed for "admin analyzes wishlist data".
adminCatalogRoute.get(
  "/admin/wishlist-insights",
  zValidator("query", wishlistInsightsQuerySchema),
  async (c) => {
    const { page, limit } = c.req.valid("query");
    const offset = (page - 1) * limit;

    const rows = await db
      .select({
        variantId: wishlists.variantId,
        wishlistCount: sql<number>`count(*)::int`,
        variantName: productVariants.name,
        stockQty: productVariants.stockQty,
        productId: products.id,
        productName: products.name,
      })
      .from(wishlists)
      .innerJoin(productVariants, eq(wishlists.variantId, productVariants.id))
      .innerJoin(products, eq(productVariants.productId, products.id))
      .groupBy(wishlists.variantId, productVariants.name, productVariants.stockQty, products.id, products.name)
      .orderBy(desc(sql`count(*)`))
      .limit(limit)
      .offset(offset);

    return c.json({ data: rows, meta: { page, limit } });
  },
);

// ---------------------------------------------------------------------------
// Curated cross-sell ("You Might Also Like" admin overrides, 6.8)
// ---------------------------------------------------------------------------

adminCatalogRoute.get("/admin/products/:id/cross-sell", async (c) => {
  const productId = c.req.param("id");
  const rows = await db
    .select({
      id: productCrossSell.id,
      recommendedProductId: productCrossSell.recommendedProductId,
      recommendedProductName: products.name,
      sortOrder: productCrossSell.sortOrder,
    })
    .from(productCrossSell)
    .innerJoin(products, eq(productCrossSell.recommendedProductId, products.id))
    .where(eq(productCrossSell.sourceProductId, productId))
    .orderBy(asc(productCrossSell.sortOrder));

  return c.json({ data: rows });
});

const crossSellSchema = z.object({
  recommendedProductId: z.string().uuid(),
  sortOrder: z.number().int().optional(),
});

adminCatalogRoute.post(
  "/admin/products/:id/cross-sell",
  zValidator("json", crossSellSchema),
  async (c) => {
    const sourceProductId = c.req.param("id");
    const { recommendedProductId, sortOrder } = c.req.valid("json");

    if (sourceProductId === recommendedProductId) {
      return c.json(
        { error: { code: "INVALID_CROSS_SELL", message: "A product can't be its own cross-sell pick" } },
        400,
      );
    }

    const [source] = await db.select({ id: products.id }).from(products).where(eq(products.id, sourceProductId)).limit(1);
    if (!source) {
      return c.json({ error: { code: "PRODUCT_NOT_FOUND", message: "Source product not found" } }, 404);
    }
    const [recommended] = await db
      .select({ id: products.id })
      .from(products)
      .where(eq(products.id, recommendedProductId))
      .limit(1);
    if (!recommended) {
      return c.json({ error: { code: "PRODUCT_NOT_FOUND", message: "Recommended product not found" } }, 404);
    }

    try {
      const [created] = await db
        .insert(productCrossSell)
        .values({ sourceProductId, recommendedProductId, sortOrder: sortOrder ?? 0 })
        .returning();
      return c.json({ data: created }, 201);
    } catch (err) {
      if (err instanceof Error && err.message.includes("product_cross_sell_source_product_id_recommended_product_id")) {
        return c.json(
          { error: { code: "DUPLICATE_CROSS_SELL", message: "This product is already curated for this source" } },
          409,
        );
      }
      throw err;
    }
  },
);

adminCatalogRoute.delete("/admin/products/:id/cross-sell/:linkId", async (c) => {
  const sourceProductId = c.req.param("id");
  const linkId = c.req.param("linkId");

  const deleted = await db
    .delete(productCrossSell)
    .where(and(eq(productCrossSell.id, linkId), eq(productCrossSell.sourceProductId, sourceProductId)))
    .returning({ id: productCrossSell.id });

  if (deleted.length === 0) {
    return c.json({ error: { code: "CROSS_SELL_NOT_FOUND", message: "Cross-sell link not found" } }, 404);
  }
  return c.json({ data: { ok: true } });
});
