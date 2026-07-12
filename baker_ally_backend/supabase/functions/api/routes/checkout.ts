import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, eq, sql } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { evaluateDiscount, incrementDiscountUses } from "../lib/discountEngine.ts";
import { createRazorpayOrder, razorpayKeyId, verifyPaymentSignature } from "../lib/razorpay.ts";
import {
  addresses,
  cartItems,
  carts,
  orderItems,
  orders,
  productVariants,
} from "../db/schema.ts";

export const checkoutRoute = new Hono<AuthEnv>();

checkoutRoute.use("/cart/checkout", authMiddleware);
checkoutRoute.use("/orders/*", authMiddleware);

// Flat delivery fee -- PLACEHOLDER pending the Porter integration / free-shipping
// threshold decision (00_common_architecture.md §17 open decision A). ₹49 in
// paise, matching the Phase_Plan_Business.md checkout mockup.
const FLAT_SHIPPING_PAISE = 4900;

const checkoutSchema = z.object({
  addressId: z.string().uuid(),
  discountCode: z.string().min(1).max(50).optional(),
  expectedTotal: z.coerce.number().int().min(0),
});

// Two-step payment (00_common_architecture.md §9). Step 1 creates the pending
// order + Razorpay order after re-validating prices/stock server-side.
checkoutRoute.post("/cart/checkout", zValidator("json", checkoutSchema), async (c) => {
  const authUser = c.get("user");
  const { addressId, discountCode, expectedTotal } = c.req.valid("json");

  // Address must belong to the caller.
  const [address] = await db
    .select({ id: addresses.id })
    .from(addresses)
    .where(and(eq(addresses.id, addressId), eq(addresses.userId, authUser.id)))
    .limit(1);
  if (!address) {
    return c.json({ error: { code: "ADDRESS_NOT_FOUND", message: "Delivery address not found" } }, 404);
  }

  // Load cart lines joined to LIVE variant data -- never a stale snapshot.
  const [cart] = await db.select({ id: carts.id }).from(carts).where(eq(carts.userId, authUser.id)).limit(1);
  if (!cart) {
    return c.json({ error: { code: "CART_EMPTY", message: "Your cart is empty" } }, 400);
  }

  const lines = await db
    .select({
      variantId: cartItems.variantId,
      quantity: cartItems.quantity,
      currentPrice: productVariants.currentPrice,
      stockQty: productVariants.stockQty,
      isActive: productVariants.isActive,
      variantName: productVariants.name,
      productName: sql<string>`(SELECT name FROM products WHERE id = ${productVariants.productId})`,
    })
    .from(cartItems)
    .innerJoin(productVariants, eq(cartItems.variantId, productVariants.id))
    .where(eq(cartItems.cartId, cart.id));

  if (lines.length === 0) {
    return c.json({ error: { code: "CART_EMPTY", message: "Your cart is empty" } }, 400);
  }

  // Stock re-check at checkout (05_cart_and_checkout.md Key Rules) -- surfaces
  // any item that went out of stock between add and checkout before payment.
  const outOfStock = lines.filter((l) => !l.isActive || l.quantity > l.stockQty);
  if (outOfStock.length > 0) {
    return c.json(
      {
        error: {
          code: "OUT_OF_STOCK",
          message: "Some items are no longer available in the requested quantity",
          items: outOfStock.map((l) => ({ variantId: l.variantId, available: l.stockQty })),
        },
      },
      409,
    );
  }

  const subtotal = lines.reduce((sum, l) => sum + l.currentPrice * l.quantity, 0);

  // Recompute the discount server-side; the client's value is never trusted.
  let discountId: string | null = null;
  let discountValue = 0;
  let freeShipping = false;
  if (discountCode) {
    const result = await evaluateDiscount(discountCode.trim().toUpperCase(), subtotal);
    if (!result.ok) {
      return c.json({ error: { code: result.code, message: result.message } }, 409);
    }
    discountId = result.discountId;
    discountValue = result.discountValue;
    freeShipping = result.freeShipping;
  }

  const shippingCost = freeShipping ? 0 : FLAT_SHIPPING_PAISE;
  const total = subtotal - discountValue + shippingCost;

  // Price re-validation (00_common_architecture.md §18) -- if what we compute
  // differs from what the user was shown, don't create an order; return the
  // corrected breakdown so Flutter updates the bill and the user re-confirms.
  if (total !== expectedTotal) {
    return c.json(
      {
        error: {
          code: "PRICE_CHANGED",
          message: "Prices changed since your cart was built",
          breakdown: { subtotal, discountValue, shippingCost, total },
        },
      },
      409,
    );
  }

  // Create the pending order + snapshot items in one transaction.
  const orderId = await db.transaction(async (tx) => {
    const [order] = await tx
      .insert(orders)
      .values({
        userId: authUser.id,
        addressId,
        status: "pending",
        subtotal,
        discountId,
        discountValue,
        shippingCost,
        total,
      })
      .returning({ id: orders.id });

    await tx.insert(orderItems).values(
      lines.map((l) => ({
        orderId: order.id,
        variantId: l.variantId,
        productName: l.productName,
        variantName: l.variantName,
        quantity: l.quantity,
        unitPrice: l.currentPrice,
      })),
    );

    return order.id;
  });

  // External call, outside the DB transaction: create the Razorpay order, then
  // record its id on our row.
  let razorpayOrderId: string;
  try {
    const rzpOrder = await createRazorpayOrder(total, `receipt_${orderId}`);
    razorpayOrderId = rzpOrder.id;
  } catch (err) {
    // Roll our order back to a clean state if Razorpay rejected it.
    await db.delete(orders).where(eq(orders.id, orderId));
    throw err;
  }

  await db.update(orders).set({ razorpayOrderId, updatedAt: new Date() }).where(eq(orders.id, orderId));

  return c.json({
    data: { orderId, razorpayOrderId, amount: total, keyId: razorpayKeyId() },
  });
});

const confirmSchema = z.object({
  razorpayPaymentId: z.string().min(1),
  razorpaySignature: z.string().min(1),
});

// Step 2: verify payment, confirm order, decrement stock -- all atomically
// (00_common_architecture.md §9 + §18 "Stock goes negative" mitigation).
checkoutRoute.post("/orders/:id/confirm", zValidator("json", confirmSchema), async (c) => {
  const authUser = c.get("user");
  const orderId = c.req.param("id");
  const { razorpayPaymentId, razorpaySignature } = c.req.valid("json");

  const [order] = await db
    .select()
    .from(orders)
    .where(and(eq(orders.id, orderId), eq(orders.userId, authUser.id)))
    .limit(1);
  if (!order) {
    return c.json({ error: { code: "ORDER_NOT_FOUND", message: "Order not found" } }, 404);
  }

  // Idempotent replay: same order already confirmed with the same payment id.
  if (order.status === "confirmed" && order.razorpayPaymentId === razorpayPaymentId) {
    return c.json({ data: { orderId, status: "confirmed" } });
  }
  if (order.status !== "pending") {
    return c.json(
      { error: { code: "ORDER_NOT_PENDING", message: `Order is already ${order.status}` } },
      409,
    );
  }
  if (!order.razorpayOrderId) {
    return c.json({ error: { code: "ORDER_NOT_INITIATED", message: "Order has no Razorpay order id" } }, 409);
  }

  // Verify the HMAC signature Razorpay/Flutter returned.
  if (!verifyPaymentSignature(order.razorpayOrderId, razorpayPaymentId, razorpaySignature)) {
    return c.json({ error: { code: "INVALID_PAYMENT", message: "Payment signature verification failed" } }, 400);
  }

  const items = await db
    .select({ variantId: orderItems.variantId, quantity: orderItems.quantity })
    .from(orderItems)
    .where(eq(orderItems.orderId, orderId));

  try {
    await db.transaction(async (tx) => {
      // Conditional decrement -- the WHERE stock_qty >= qty guard means two
      // concurrent last-unit checkouts can't both succeed. Zero rows updated
      // for any item throws, rolling the whole transaction back.
      for (const item of items) {
        const updated = await tx
          .update(productVariants)
          .set({ stockQty: sql`${productVariants.stockQty} - ${item.quantity}` })
          .where(
            and(
              eq(productVariants.id, item.variantId),
              sql`${productVariants.stockQty} >= ${item.quantity}`,
            ),
          )
          .returning({ id: productVariants.id });
        if (updated.length === 0) {
          throw new Error(`OUT_OF_STOCK:${item.variantId}`);
        }
      }

      // Flip to confirmed. The status='pending' guard + razorpay_payment_id
      // UNIQUE make a double-confirm impossible even under a race.
      const confirmed = await tx
        .update(orders)
        .set({ status: "confirmed", razorpayPaymentId, updatedAt: new Date() })
        .where(and(eq(orders.id, orderId), eq(orders.status, "pending")))
        .returning({ id: orders.id });
      if (confirmed.length === 0) {
        throw new Error("ALREADY_CONFIRMED");
      }

      if (order.discountId) {
        await incrementDiscountUses(order.discountId);
      }

      // Clear the user's cart now that it's an order.
      const [cart] = await tx.select({ id: carts.id }).from(carts).where(eq(carts.userId, authUser.id)).limit(1);
      if (cart) {
        await tx.delete(cartItems).where(eq(cartItems.cartId, cart.id));
      }
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg.startsWith("OUT_OF_STOCK")) {
      return c.json(
        { error: { code: "OUT_OF_STOCK", message: "An item sold out before payment could be confirmed" } },
        409,
      );
    }
    if (msg === "ALREADY_CONFIRMED") {
      return c.json({ data: { orderId, status: "confirmed" } });
    }
    throw err;
  }

  return c.json({ data: { orderId, status: "confirmed" } }, 201);
});
