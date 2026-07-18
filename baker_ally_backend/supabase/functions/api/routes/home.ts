import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, asc, desc, eq, inArray, sql } from "npm:drizzle-orm";

import { rateLimitMiddleware } from "../middleware/rateLimit.ts";
import { db } from "../lib/db.ts";
import { productImages, products, productVariants } from "../db/schema.ts";
import { attachDisplayInfo } from "./catalog.ts";

export const homeRoute = new Hono();

// Public discovery routes -- Planning docs/Architecture/01_home_tab.md. No
// authMiddleware, same as catalog.ts.

const PREVIEW_LIMIT = 10;

async function getNewlyLaunched(limit: number, offset: number) {
  const rows = await db
    .select()
    .from(products)
    .where(eq(products.isActive, true))
    .orderBy(desc(products.createdAt))
    .limit(limit)
    .offset(offset);
  return attachDisplayInfo(rows);
}

async function getTrending(limit: number, offset: number) {
  const rows = await db
    .select()
    .from(products)
    .where(and(eq(products.isActive, true), eq(products.isTrending, true)))
    .orderBy(desc(products.createdAt))
    .limit(limit)
    .offset(offset);
  return attachDisplayInfo(rows);
}

// Deliberately not attachDisplayInfo() -- that helper always picks each
// product's lowest-sortOrder active variant as the display variant, which is
// correct for Newly Launched/Trending (any variant is representative) but
// WRONG here: a product can have a full-price variant at sortOrder 0 and the
// actual discounted variant at sortOrder 1, and attachDisplayInfo would show
// the tile at full price. Query variant-first instead and attach that exact
// discounted variant. See 01_home_tab.md §10.
async function getNewOffers(limit: number, offset: number) {
  const rows = await db
    .select({ product: products, variant: productVariants })
    .from(productVariants)
    .innerJoin(products, eq(productVariants.productId, products.id))
    .where(and(
      eq(products.isActive, true),
      eq(productVariants.isActive, true),
      sql`${productVariants.currentPrice} < ${productVariants.originalPrice}`,
    ))
    .orderBy(
      desc(sql`(${productVariants.originalPrice} - ${productVariants.currentPrice})::float / ${productVariants.originalPrice}`),
    )
    .limit(limit)
    .offset(offset);

  if (rows.length === 0) return [];

  const productIds = [...new Set(rows.map((r) => r.product.id))];
  const images = await db
    .select()
    .from(productImages)
    .where(inArray(productImages.productId, productIds))
    .orderBy(asc(productImages.sortOrder));

  const displayImageByProduct = new Map<string, typeof productImages.$inferSelect>();
  for (const image of images) {
    const existing = displayImageByProduct.get(image.productId);
    if (!existing || (image.isPrimary && !existing.isPrimary)) {
      displayImageByProduct.set(image.productId, image);
    }
  }

  // Deduplicate by productId, keeping only the highest-discount variant (first
  // in the ordered result set). Multiple variants per product is fine in the
  // catalog, but Drift's CachedHomeSections uses (section, productId) as the
  // primary key -- one row per product per section. The best-discount variant
  // is already first due to the ORDER BY discount % DESC in the query.
  const seenProductIds = new Set<string>();
  return rows
    .filter(({ product }) => {
      if (seenProductIds.has(product.id)) return false;
      seenProductIds.add(product.id);
      return true;
    })
    .map(({ product, variant }) => ({
      ...product,
      displayVariant: variant,
      displayImageUrl: displayImageByProduct.get(product.id)?.publicUrl ?? null,
    }));
}

homeRoute.get("/home", rateLimitMiddleware, async (c) => {
  const [newlyLaunched, newOffers, trending] = await Promise.all([
    getNewlyLaunched(PREVIEW_LIMIT, 0),
    getNewOffers(PREVIEW_LIMIT, 0),
    getTrending(PREVIEW_LIMIT, 0),
  ]);

  return c.json({ data: { newlyLaunched, newOffers, trending } });
});

const sectionQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

homeRoute.get(
  "/home/newly-launched",
  rateLimitMiddleware,
  zValidator("query", sectionQuerySchema),
  async (c) => {
    const { page, limit } = c.req.valid("query");
    const data = await getNewlyLaunched(limit, (page - 1) * limit);
    return c.json({ data, meta: { page, limit } });
  },
);

homeRoute.get(
  "/home/new-offers",
  rateLimitMiddleware,
  zValidator("query", sectionQuerySchema),
  async (c) => {
    const { page, limit } = c.req.valid("query");
    const data = await getNewOffers(limit, (page - 1) * limit);
    return c.json({ data, meta: { page, limit } });
  },
);

homeRoute.get(
  "/home/trending",
  rateLimitMiddleware,
  zValidator("query", sectionQuerySchema),
  async (c) => {
    const { page, limit } = c.req.valid("query");
    const data = await getTrending(limit, (page - 1) * limit);
    return c.json({ data, meta: { page, limit } });
  },
);
