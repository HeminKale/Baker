import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, desc, eq, inArray, sql } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { supabaseAdmin } from "../lib/supabaseAdmin.ts";
import { generateInvoicePdf } from "../lib/invoice.ts";
import { addresses, orderItems, orders, productImages } from "../db/schema.ts";

export const ordersRoute = new Hono<AuthEnv>();

// Self-contained authMiddleware on /orders* -- same accepted double-guard
// pattern as cart.ts/checkout.ts's existing overlap (checkout.ts also guards
// /orders/:id/confirm), noted in Milestone 3.md §5 as harmless.
ordersRoute.use("/orders*", authMiddleware);

// Order-listing endpoints pulled forward from Phase 4 §4.7, minus shipment
// fields (that table doesn't exist yet). Status will realistically only
// ever be pending/confirmed/cancelled until Phase 4 or 6 can advance it
// further -- these filters are still written against the full state machine
// so nothing here needs to change once that happens.
const ACTIVE_STATUSES = ["confirmed", "processing", "shipped"];
const PAID_STATUSES = ["confirmed", "processing", "shipped", "delivered"];

const listOrdersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  status: z.enum(["active"]).optional(),
  paid: z.coerce.boolean().optional(),
});

ordersRoute.get("/orders", zValidator("query", listOrdersQuerySchema), async (c) => {
  const authUser = c.get("user");
  const { page, limit, status, paid } = c.req.valid("query");
  const offset = (page - 1) * limit;

  const conditions = [eq(orders.userId, authUser.id)];
  if (status === "active") conditions.push(inArray(orders.status, ACTIVE_STATUSES));
  if (paid === true) conditions.push(inArray(orders.status, PAID_STATUSES));
  const whereClause = and(...conditions);

  const rows = await db
    .select()
    .from(orders)
    .where(whereClause)
    .orderBy(desc(orders.createdAt))
    .limit(limit)
    .offset(offset);

  const [{ count }] = await db.select({ count: sql<number>`count(*)::int` }).from(orders).where(whereClause);

  // order_items already has denormalized product_name/variant_name, so the
  // list view needs no product/variant join -- just an item count and one
  // thumbnail via a single batch join to product_images by variant_id.
  const orderIds = rows.map((o) => o.id);
  const items = orderIds.length
    ? await db
        .select({ orderId: orderItems.orderId, variantId: orderItems.variantId })
        .from(orderItems)
        .where(inArray(orderItems.orderId, orderIds))
    : [];

  const itemsByOrder = new Map<string, typeof items>();
  for (const item of items) {
    const list = itemsByOrder.get(item.orderId) ?? [];
    list.push(item);
    itemsByOrder.set(item.orderId, list);
  }

  const variantIds = [...new Set(items.map((i) => i.variantId))];
  const images = variantIds.length
    ? await db
        .select()
        .from(productImages)
        .where(and(inArray(productImages.variantId, variantIds), eq(productImages.isPrimary, true)))
    : [];
  const imageByVariant = new Map(images.map((img) => [img.variantId, img.publicUrl]));

  const data = rows.map((order) => {
    const orderLines = itemsByOrder.get(order.id) ?? [];
    const thumbnailUrl = orderLines.length ? imageByVariant.get(orderLines[0].variantId) ?? null : null;
    return { ...order, itemCount: orderLines.length, thumbnailUrl };
  });

  return c.json({ data, meta: { page, limit, total: count } });
});

ordersRoute.get("/orders/:id", async (c) => {
  const authUser = c.get("user");
  const orderId = c.req.param("id");

  const [order] = await db
    .select()
    .from(orders)
    .where(and(eq(orders.id, orderId), eq(orders.userId, authUser.id)))
    .limit(1);
  if (!order) {
    return c.json({ error: { code: "ORDER_NOT_FOUND", message: "Order not found" } }, 404);
  }

  const items = await db.select().from(orderItems).where(eq(orderItems.orderId, orderId));
  const [address] = await db.select().from(addresses).where(eq(addresses.id, order.addressId)).limit(1);

  return c.json({ data: { ...order, items, address: address ?? null } });
});

ordersRoute.get("/orders/:id/invoice", async (c) => {
  const authUser = c.get("user");
  const orderId = c.req.param("id");

  const [order] = await db
    .select()
    .from(orders)
    .where(and(eq(orders.id, orderId), eq(orders.userId, authUser.id)))
    .limit(1);
  if (!order) {
    return c.json({ error: { code: "ORDER_NOT_FOUND", message: "Order not found" } }, 404);
  }

  const storagePath = `${orderId}.pdf`;
  const bucket = supabaseAdmin.storage.from("invoices");

  // createSignedUrl errors if the object doesn't exist yet -- use that as
  // the "generate on first request" check rather than a separate list call.
  let signed = await bucket.createSignedUrl(storagePath, 60 * 10);

  if (signed.error) {
    const items = await db.select().from(orderItems).where(eq(orderItems.orderId, orderId));
    const [address] = await db.select().from(addresses).where(eq(addresses.id, order.addressId)).limit(1);
    const pdfBytes = await generateInvoicePdf({ order, items, address: address ?? null });

    const { error: uploadError } = await bucket.upload(storagePath, pdfBytes, {
      contentType: "application/pdf",
      upsert: true,
    });
    if (uploadError) throw uploadError;

    signed = await bucket.createSignedUrl(storagePath, 60 * 10);
    if (signed.error || !signed.data) {
      return c.json({ error: { code: "INVOICE_UNAVAILABLE", message: "Could not generate invoice" } }, 500);
    }
  }

  return c.json({ data: { url: signed.data!.signedUrl } });
});
