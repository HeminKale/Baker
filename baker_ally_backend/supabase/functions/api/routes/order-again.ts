import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, desc, eq, inArray, notInArray, sql } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { orderItems, orders, productImages, products, productVariants } from "../db/schema.ts";

export const orderAgainRoute = new Hono<AuthEnv>();

orderAgainRoute.use("/order-again*", authMiddleware);

// Frequently Bought Together is on-request computed here, not the nightly
// -cron order_group_cache materialized table 00_common_architecture.md §9/
// Phase 5.5 designed -- near-zero real order volume makes precomputing over
// an empty table pointless right now (same reasoning already used for the
// reviews rating average). Revisit if real usage or Phase 7 load testing
// shows this query is too slow. Also returns only the user's own groups --
// no platform-wide fill, for the same near-zero-volume reason.
const EXCLUDED_STATUSES = ["pending", "cancelled"];

/** Loads live product/variant/image display data for a set of variant ids,
 *  keyed by variant (Order Again cares about the exact variant bought, not
 *  just the product's default display variant like catalog.ts's
 *  attachDisplayInfo does). Same batch-join-by-product-id pattern. */
async function loadVariantDisplayInfo(variantIds: string[]) {
  if (variantIds.length === 0) return new Map<string, Record<string, unknown>>();

  const rows = await db
    .select({
      variantId: productVariants.id,
      variantName: productVariants.name,
      currentPrice: productVariants.currentPrice,
      originalPrice: productVariants.originalPrice,
      stockQty: productVariants.stockQty,
      isActive: productVariants.isActive,
      productId: products.id,
      productName: products.name,
    })
    .from(productVariants)
    .innerJoin(products, eq(productVariants.productId, products.id))
    .where(inArray(productVariants.id, variantIds));

  const productIds = [...new Set(rows.map((r) => r.productId))];
  const images = productIds.length
    ? await db
        .select()
        .from(productImages)
        .where(and(inArray(productImages.productId, productIds), eq(productImages.isPrimary, true)))
    : [];
  const imageByProduct = new Map(images.map((img) => [img.productId, img.publicUrl]));

  return new Map(
    rows.map((row) => [row.variantId, { ...row, imageUrl: imageByProduct.get(row.productId) ?? null }]),
  );
}

orderAgainRoute.get("/order-again/frequently-bought", async (c) => {
  const authUser = c.get("user");

  const userOrders = await db
    .select({ id: orders.id })
    .from(orders)
    .where(and(eq(orders.userId, authUser.id), notInArray(orders.status, EXCLUDED_STATUSES)));
  const orderIds = userOrders.map((o) => o.id);
  if (orderIds.length === 0) return c.json({ data: [] });

  const items = await db
    .select({ orderId: orderItems.orderId, variantId: orderItems.variantId })
    .from(orderItems)
    .where(inArray(orderItems.orderId, orderIds));

  const variantIdsByOrder = new Map<string, string[]>();
  for (const item of items) {
    const list = variantIdsByOrder.get(item.orderId) ?? [];
    list.push(item.variantId);
    variantIdsByOrder.set(item.orderId, list);
  }

  // Dedupe identical variant-id sets ("groups") and count how often that
  // exact combination was ordered -- Frequently Bought Together is about
  // repeated multi-item combos, not single SKUs.
  const groupByKey = new Map<string, { variantIds: string[]; count: number }>();
  for (const variantIds of variantIdsByOrder.values()) {
    const unique = [...new Set(variantIds)];
    if (unique.length < 2) continue; // single-item orders aren't a "combo"
    const key = [...unique].sort().join(",");
    const existing = groupByKey.get(key);
    if (existing) {
      existing.count += 1;
    } else {
      groupByKey.set(key, { variantIds: unique, count: 1 });
    }
  }

  const groups = [...groupByKey.values()]
    .filter((g) => g.count >= 2) // "frequently" -- ordered together more than once
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  const allVariantIds = [...new Set(groups.flatMap((g) => g.variantIds))];
  const displayByVariant = await loadVariantDisplayInfo(allVariantIds);

  const data = groups.map((g) => ({
    variantIds: g.variantIds,
    orderCount: g.count,
    items: g.variantIds.map((id) => displayByVariant.get(id)).filter((v) => v !== undefined),
  }));

  return c.json({ data });
});

const previouslyBoughtQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

orderAgainRoute.get(
  "/order-again/previously-bought",
  zValidator("query", previouslyBoughtQuerySchema),
  async (c) => {
    const authUser = c.get("user");
    const { page, limit } = c.req.valid("query");
    const offset = (page - 1) * limit;

    const rows = await db
      .select({
        variantId: orderItems.variantId,
        lastOrderedAt: sql<string>`MAX(${orders.createdAt})`,
      })
      .from(orderItems)
      .innerJoin(orders, eq(orderItems.orderId, orders.id))
      .where(and(eq(orders.userId, authUser.id), notInArray(orders.status, EXCLUDED_STATUSES)))
      .groupBy(orderItems.variantId)
      .orderBy(desc(sql`MAX(${orders.createdAt})`))
      .limit(limit)
      .offset(offset);

    const displayByVariant = await loadVariantDisplayInfo(rows.map((r) => r.variantId));
    const data = rows
      .map((r) => {
        const display = displayByVariant.get(r.variantId);
        return display ? { ...display, lastOrderedAt: r.lastOrderedAt } : null;
      })
      .filter((v) => v !== null);

    return c.json({ data, meta: { page, limit } });
  },
);
