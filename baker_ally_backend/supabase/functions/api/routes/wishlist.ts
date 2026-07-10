import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, desc, eq, inArray } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { productImages, products, productVariants, wishlists } from "../db/schema.ts";

export const wishlistRoute = new Hono<AuthEnv>();

wishlistRoute.use("/wishlist*", authMiddleware);

// Per-login wishlist, synced across devices (00_common_architecture.md §17
// decision #9). Heart toggle UI lands in Phase 2 (this milestone); the full
// wishlist grid screen is Phase 5.

wishlistRoute.get("/wishlist", async (c) => {
  const authUser = c.get("user");

  const rows = await db
    .select({
      variantId: wishlists.variantId,
      variantName: productVariants.name,
      currentPrice: productVariants.currentPrice,
      originalPrice: productVariants.originalPrice,
      stockQty: productVariants.stockQty,
      productId: products.id,
      productName: products.name,
      addedAt: wishlists.createdAt,
    })
    .from(wishlists)
    .innerJoin(productVariants, eq(wishlists.variantId, productVariants.id))
    .innerJoin(products, eq(productVariants.productId, products.id))
    .where(eq(wishlists.userId, authUser.id))
    .orderBy(desc(wishlists.createdAt));

  const productIds = [...new Set(rows.map((r) => r.productId))];
  const images = productIds.length
    ? await db
        .select()
        .from(productImages)
        .where(and(inArray(productImages.productId, productIds), eq(productImages.isPrimary, true)))
    : [];
  const imageByProduct = new Map(images.map((img) => [img.productId, img.publicUrl]));

  return c.json({
    data: rows.map((row) => ({ ...row, imageUrl: imageByProduct.get(row.productId) ?? null })),
  });
});

const addWishlistSchema = z.object({ variantId: z.string().uuid() });

wishlistRoute.post("/wishlist", zValidator("json", addWishlistSchema), async (c) => {
  const authUser = c.get("user");
  const { variantId } = c.req.valid("json");

  const [variant] = await db.select().from(productVariants).where(eq(productVariants.id, variantId)).limit(1);
  if (!variant) {
    return c.json({ error: { code: "VARIANT_NOT_FOUND", message: "Variant not found" } }, 404);
  }

  await db
    .insert(wishlists)
    .values({ userId: authUser.id, variantId })
    .onConflictDoNothing({ target: [wishlists.userId, wishlists.variantId] });

  return c.json({ data: { ok: true } }, 201);
});

wishlistRoute.delete("/wishlist/:variantId", async (c) => {
  const authUser = c.get("user");
  const variantId = c.req.param("variantId");

  await db
    .delete(wishlists)
    .where(and(eq(wishlists.userId, authUser.id), eq(wishlists.variantId, variantId)));

  return c.json({ data: { ok: true } });
});
