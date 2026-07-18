import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, desc, eq, gte, ilike, lte, or, sql } from "npm:drizzle-orm";

import { adminOrStaffMiddleware, authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { addresses, orderItems, orders, productVariants, users } from "../db/schema.ts";

export const adminOrdersRoute = new Hono<AuthEnv>();

// Staff scope (6.6 plan) -- same as admin-catalog.ts.
adminOrdersRoute.use("/admin/orders*", authMiddleware, adminOrStaffMiddleware);

const CUSTOMER_NAME = sql<string>`coalesce(${users.fullName}, ${users.email}, ${users.phone})`;

const listOrdersQuerySchema = z.object({
  status: z.string().optional(),
  from: z.string().datetime().optional(),
  to: z.string().datetime().optional(),
  q: z.string().min(1).max(200).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// All users' orders -- no ownership filter, unlike routes/orders.ts.
// Customer search/name falls back email -> phone since users.fullName can be
// NULL for Google-only accounts (6.6 plan gotcha).
adminOrdersRoute.get("/admin/orders", zValidator("query", listOrdersQuerySchema), async (c) => {
  const { status, from, to, q, page, limit } = c.req.valid("query");
  const offset = (page - 1) * limit;

  const conditions = [];
  if (status) conditions.push(eq(orders.status, status));
  if (from) conditions.push(gte(orders.createdAt, new Date(from)));
  if (to) conditions.push(lte(orders.createdAt, new Date(to)));
  if (q) {
    conditions.push(
      or(ilike(users.fullName, `%${q}%`), ilike(users.email, `%${q}%`), ilike(users.phone, `%${q}%`)),
    );
  }
  const whereClause = conditions.length ? and(...conditions) : undefined;

  const rows = await db
    .select({ order: orders, customerName: CUSTOMER_NAME })
    .from(orders)
    .innerJoin(users, eq(orders.userId, users.id))
    .where(whereClause)
    .orderBy(desc(orders.createdAt))
    .limit(limit)
    .offset(offset);

  const [{ count }] = await db
    .select({ count: sql<number>`count(*)::int` })
    .from(orders)
    .innerJoin(users, eq(orders.userId, users.id))
    .where(whereClause);

  return c.json({
    data: rows.map((r) => ({ ...r.order, customerName: r.customerName })),
    meta: { page, limit, total: count },
  });
});

adminOrdersRoute.get("/admin/orders/:id", async (c) => {
  const orderId = c.req.param("id");

  const [row] = await db
    .select({
      order: orders,
      customerName: CUSTOMER_NAME,
      customerEmail: users.email,
      customerPhone: users.phone,
    })
    .from(orders)
    .innerJoin(users, eq(orders.userId, users.id))
    .where(eq(orders.id, orderId))
    .limit(1);

  if (!row) {
    return c.json({ error: { code: "ORDER_NOT_FOUND", message: "Order not found" } }, 404);
  }

  const items = await db.select().from(orderItems).where(eq(orderItems.orderId, orderId));
  const [address] = await db.select().from(addresses).where(eq(addresses.id, row.order.addressId)).limit(1);

  return c.json({
    data: {
      ...row.order,
      customerName: row.customerName,
      customerEmail: row.customerEmail,
      customerPhone: row.customerPhone,
      items,
      address: address ?? null,
    },
  });
});

// Admin acts on orders starting from "confirmed" -- "pending" means payment
// hasn't been verified yet, not admin's concern (orders.ts comment: status
// realistically only pending/confirmed/cancelled until Phase 4/6 advance it).
// delivered/cancelled are terminal.
const ALLOWED_TRANSITIONS: Record<string, string[]> = {
  confirmed: ["processing", "cancelled"],
  processing: ["shipped", "cancelled"],
  shipped: ["delivered"],
};

const updateStatusSchema = z.object({
  status: z.enum(["processing", "shipped", "delivered", "cancelled"]),
});

adminOrdersRoute.patch("/admin/orders/:id/status", zValidator("json", updateStatusSchema), async (c) => {
  const orderId = c.req.param("id");
  const { status: newStatus } = c.req.valid("json");

  const [order] = await db.select().from(orders).where(eq(orders.id, orderId)).limit(1);
  if (!order) {
    return c.json({ error: { code: "ORDER_NOT_FOUND", message: "Order not found" } }, 404);
  }

  const allowedNext = ALLOWED_TRANSITIONS[order.status] ?? [];
  if (!allowedNext.includes(newStatus)) {
    return c.json(
      { error: { code: "INVALID_TRANSITION", message: `Cannot move an order from ${order.status} to ${newStatus}` } },
      409,
    );
  }

  const isCancelling = newStatus === "cancelled";

  try {
    const updated = await db.transaction(async (tx) => {
      // Guarded transition -- compare current status in the WHERE, same
      // pattern as checkout.ts's confirm handler. A concurrent admin action
      // that already moved this order makes .returning() come back empty.
      const [row] = await tx
        .update(orders)
        .set({ status: newStatus, updatedAt: new Date() })
        .where(and(eq(orders.id, orderId), eq(orders.status, order.status)))
        .returning();
      if (!row) throw new Error("STATUS_CONFLICT");

      if (isCancelling) {
        // Restock decremented stock_qty in the same transaction -- otherwise
        // stock silently leaks on every admin cancellation. Interacts with
        // 6.5: restocking the last unit fires the back-in-stock push.
        const items = await tx
          .select({ variantId: orderItems.variantId, quantity: orderItems.quantity })
          .from(orderItems)
          .where(eq(orderItems.orderId, orderId));
        for (const item of items) {
          await tx
            .update(productVariants)
            .set({ stockQty: sql`${productVariants.stockQty} + ${item.quantity}` })
            .where(eq(productVariants.id, item.variantId));
        }
      }

      return row;
    });

    return c.json({ data: updated });
  } catch (err) {
    if (err instanceof Error && err.message === "STATUS_CONFLICT") {
      return c.json({ error: { code: "STATUS_CONFLICT", message: "Order status changed concurrently" } }, 409);
    }
    throw err;
  }
});
