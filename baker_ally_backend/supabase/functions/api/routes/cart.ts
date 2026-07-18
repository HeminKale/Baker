import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, asc, eq, inArray, sql } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { buildRecommendations } from "./catalog.ts";
import {
  cartItems,
  carts,
  productImages,
  products,
  productVariants,
} from "../db/schema.ts";

export const cartRoute = new Hono<AuthEnv>();

// Server cart is the source of truth (00_common_architecture.md §8). Guests
// never hit these routes -- they build a cart in Drift locally and only sync
// via POST /cart/merge after login. So everything here is strictly authed.
cartRoute.use("/cart*", authMiddleware);

/** One active cart per user (carts.user_id UNIQUE). Idempotent create. */
async function getOrCreateCartId(userId: string): Promise<string> {
  await db.insert(carts).values({ userId }).onConflictDoNothing({ target: carts.userId });
  const [row] = await db.select({ id: carts.id }).from(carts).where(eq(carts.userId, userId)).limit(1);
  return row.id;
}

/** Loads a cart's lines joined to live variant/product/image data, shaped for
 *  the Flutter cart + checkout screens. Batch image fetch avoids N+1 (same
 *  pattern as wishlist.ts). */
async function loadCartItems(cartId: string) {
  const rows = await db
    .select({
      id: cartItems.id,
      variantId: cartItems.variantId,
      quantity: cartItems.quantity,
      variantName: productVariants.name,
      currentPrice: productVariants.currentPrice,
      originalPrice: productVariants.originalPrice,
      stockQty: productVariants.stockQty,
      isActive: productVariants.isActive,
      productId: products.id,
      productName: products.name,
      addedAt: cartItems.addedAt,
    })
    .from(cartItems)
    .innerJoin(productVariants, eq(cartItems.variantId, productVariants.id))
    .innerJoin(products, eq(productVariants.productId, products.id))
    .where(eq(cartItems.cartId, cartId))
    .orderBy(asc(cartItems.addedAt));

  const productIds = [...new Set(rows.map((r) => r.productId))];
  const images = productIds.length
    ? await db
        .select()
        .from(productImages)
        .where(and(inArray(productImages.productId, productIds), eq(productImages.isPrimary, true)))
    : [];
  const imageByProduct = new Map(images.map((img) => [img.productId, img.publicUrl]));

  return rows.map((row) => ({ ...row, imageUrl: imageByProduct.get(row.productId) ?? null }));
}

cartRoute.get("/cart", async (c) => {
  const authUser = c.get("user");
  const cartId = await getOrCreateCartId(authUser.id);
  const items = await loadCartItems(cartId);
  return c.json({ data: { items } });
});

const addItemSchema = z.object({
  variantId: z.string().uuid(),
  quantity: z.coerce.number().int().min(1).default(1),
});

cartRoute.post("/cart/items", zValidator("json", addItemSchema), async (c) => {
  const authUser = c.get("user");
  const { variantId, quantity } = c.req.valid("json");

  const [variant] = await db
    .select()
    .from(productVariants)
    .where(eq(productVariants.id, variantId))
    .limit(1);
  if (!variant || !variant.isActive) {
    return c.json({ error: { code: "VARIANT_NOT_FOUND", message: "Variant not found" } }, 404);
  }

  const cartId = await getOrCreateCartId(authUser.id);

  // Upsert-add: increment if the line already exists, then clamp to stock.
  await db
    .insert(cartItems)
    .values({ cartId, variantId, quantity })
    .onConflictDoUpdate({
      target: [cartItems.cartId, cartItems.variantId],
      set: { quantity: sql`LEAST(${cartItems.quantity} + ${quantity}, ${variant.stockQty})` },
    });

  const items = await loadCartItems(cartId);
  return c.json({ data: { items } }, 201);
});

const batchAddSchema = z.object({
  items: z
    .array(z.object({ variantId: z.string().uuid(), quantity: z.coerce.number().int().min(1) }))
    .min(1)
    .max(50),
});

// Order Again's "Add All" / "Add Selected Items" (Milestone 5 plan §Backend)
// -- loops the same upsert-add-clamped-to-stock logic /cart/items and
// /cart/merge already use, skipping unknown/inactive variants silently
// rather than failing the whole batch.
cartRoute.post("/cart/items/batch", zValidator("json", batchAddSchema), async (c) => {
  const authUser = c.get("user");
  const { items: itemsToAdd } = c.req.valid("json");

  const variantIds = itemsToAdd.map((i) => i.variantId);
  const variants = await db
    .select({ id: productVariants.id, stockQty: productVariants.stockQty, isActive: productVariants.isActive })
    .from(productVariants)
    .where(inArray(productVariants.id, variantIds));
  const stockById = new Map(variants.filter((v) => v.isActive).map((v) => [v.id, v.stockQty]));

  const cartId = await getOrCreateCartId(authUser.id);

  for (const item of itemsToAdd) {
    const stock = stockById.get(item.variantId);
    if (stock === undefined) continue; // unknown or inactive -- skip
    await db
      .insert(cartItems)
      .values({ cartId, variantId: item.variantId, quantity: item.quantity })
      .onConflictDoUpdate({
        target: [cartItems.cartId, cartItems.variantId],
        set: { quantity: sql`LEAST(${cartItems.quantity} + ${item.quantity}, ${stock})` },
      });
  }

  const items = await loadCartItems(cartId);
  return c.json({ data: { items } }, 201);
});

const updateItemSchema = z.object({
  quantity: z.coerce.number().int().min(0),
});

cartRoute.patch("/cart/items/:id", zValidator("json", updateItemSchema), async (c) => {
  const authUser = c.get("user");
  const cartItemId = c.req.param("id");
  const { quantity } = c.req.valid("json");

  const cartId = await getOrCreateCartId(authUser.id);

  const [item] = await db
    .select({ id: cartItems.id, variantId: cartItems.variantId })
    .from(cartItems)
    .where(and(eq(cartItems.id, cartItemId), eq(cartItems.cartId, cartId)))
    .limit(1);
  if (!item) {
    return c.json({ error: { code: "CART_ITEM_NOT_FOUND", message: "Cart item not found" } }, 404);
  }

  if (quantity === 0) {
    // Qty 0 = removal (05_cart_and_checkout.md Key Rules).
    await db.delete(cartItems).where(eq(cartItems.id, cartItemId));
  } else {
    const [variant] = await db
      .select({ stockQty: productVariants.stockQty })
      .from(productVariants)
      .where(eq(productVariants.id, item.variantId))
      .limit(1);
    const capped = variant ? Math.min(quantity, variant.stockQty) : quantity;
    await db.update(cartItems).set({ quantity: capped }).where(eq(cartItems.id, cartItemId));
  }

  const items = await loadCartItems(cartId);
  return c.json({ data: { items } });
});

cartRoute.delete("/cart/items/:id", async (c) => {
  const authUser = c.get("user");
  const cartItemId = c.req.param("id");
  const cartId = await getOrCreateCartId(authUser.id);

  await db.delete(cartItems).where(and(eq(cartItems.id, cartItemId), eq(cartItems.cartId, cartId)));

  const items = await loadCartItems(cartId);
  return c.json({ data: { items } });
});

cartRoute.delete("/cart", async (c) => {
  const authUser = c.get("user");
  const cartId = await getOrCreateCartId(authUser.id);
  await db.delete(cartItems).where(eq(cartItems.cartId, cartId));
  return c.json({ data: { items: [] } });
});

const mergeSchema = z.object({
  items: z
    .array(z.object({ variantId: z.string().uuid(), quantity: z.coerce.number().int().min(1) }))
    .max(200),
});

// Guest -> login merge (00_common_architecture.md §8). Adds each local item's
// quantity to the server cart, clamped to stock. Skips unknown/inactive
// variants silently rather than failing the whole merge.
cartRoute.post("/cart/merge", zValidator("json", mergeSchema), async (c) => {
  const authUser = c.get("user");
  const { items } = c.req.valid("json");
  const cartId = await getOrCreateCartId(authUser.id);

  if (items.length > 0) {
    const variantIds = items.map((i) => i.variantId);
    const variants = await db
      .select({ id: productVariants.id, stockQty: productVariants.stockQty, isActive: productVariants.isActive })
      .from(productVariants)
      .where(inArray(productVariants.id, variantIds));
    const stockById = new Map(variants.filter((v) => v.isActive).map((v) => [v.id, v.stockQty]));

    for (const item of items) {
      const stock = stockById.get(item.variantId);
      if (stock === undefined) continue; // unknown or inactive -- skip
      await db
        .insert(cartItems)
        .values({ cartId, variantId: item.variantId, quantity: item.quantity })
        .onConflictDoUpdate({
          target: [cartItems.cartId, cartItems.variantId],
          set: { quantity: sql`LEAST(${cartItems.quantity} + ${item.quantity}, ${stock})` },
        });
    }
  }

  const merged = await loadCartItems(cartId);
  return c.json({ data: { items: merged } });
});

// "You Might Also Like" (05_cart_and_checkout.md §8) -- other active products
// from the same subcategories as the cart's variants, excluding products
// already in the cart. Public (catalog-like data). Slotting (algorithmic +
// admin-curated cross-sell) lives in catalog.ts's buildRecommendations,
// shared with /products/:id/related (Milestone 6 / 6.8).
const recommendationsSchema = z.object({
  variantIds: z.string().optional(), // comma-separated
});

cartRoute.get("/checkout/recommendations", zValidator("query", recommendationsSchema), async (c) => {
  const { variantIds } = c.req.valid("query");
  const ids = (variantIds ?? "").split(",").map((s) => s.trim()).filter(Boolean);
  if (ids.length === 0) return c.json({ data: [] });

  const cartVariants = await db
    .select({ productId: productVariants.productId, subCategoryId: products.subCategoryId })
    .from(productVariants)
    .innerJoin(products, eq(productVariants.productId, products.id))
    .where(inArray(productVariants.id, ids));

  const subCategoryIds = [...new Set(cartVariants.map((r) => r.subCategoryId))];
  const sourceProductIds = [...new Set(cartVariants.map((r) => r.productId))];
  if (subCategoryIds.length === 0) return c.json({ data: [] });

  const data = await buildRecommendations({ subCategoryIds, sourceProductIds });
  return c.json({ data });
});
