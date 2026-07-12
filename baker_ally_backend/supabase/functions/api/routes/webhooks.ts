import { Hono } from "npm:hono";
import { and, eq } from "npm:drizzle-orm";

import { db } from "../lib/db.ts";
import { verifyWebhookSignature } from "../lib/razorpay.ts";
import { orders, webhookEvents } from "../db/schema.ts";

export const webhooksRoute = new Hono();

// Razorpay webhook (backend_stack.md §8). NOT behind authMiddleware -- it's
// authenticated by HMAC signature over the raw body instead. This is the one
// route that must read c.req.text() (raw) rather than parse via zValidator,
// since re-serializing the JSON would break the signature.
//
// IP allowlisting is deferred to Phase 7 hardening (Phase_Plan_Technical.md
// risk register); the signature check is the security boundary this milestone.
webhooksRoute.post("/webhooks/razorpay", async (c) => {
  const signature = c.req.header("x-razorpay-signature");
  const rawBody = await c.req.text();

  if (!signature || !verifyWebhookSignature(rawBody, signature)) {
    return c.json({ error: { code: "INVALID_SIGNATURE", message: "Webhook signature verification failed" } }, 400);
  }

  let event: {
    event?: string;
    payload?: { payment?: { entity?: { id?: string; order_id?: string } } };
  };
  try {
    event = JSON.parse(rawBody);
  } catch {
    return c.json({ error: { code: "BAD_PAYLOAD", message: "Malformed webhook body" } }, 400);
  }

  // Dedup: (source, event_id) UNIQUE. Razorpay's own event id header is the
  // stable key; fall back to payment id if absent.
  const eventId = c.req.header("x-razorpay-event-id") ?? event.payload?.payment?.entity?.id ?? crypto.randomUUID();

  const inserted = await db
    .insert(webhookEvents)
    .values({ source: "razorpay", eventId, payload: event as unknown as Record<string, unknown> })
    .onConflictDoNothing({ target: [webhookEvents.source, webhookEvents.eventId] })
    .returning({ id: webhookEvents.id });

  if (inserted.length === 0) {
    // Already processed -- ack without re-processing.
    return c.json({ data: { ok: true, deduped: true } });
  }

  // payment.failed -> mark a still-pending order cancelled. (Success is handled
  // by the client-driven POST /orders/:id/confirm, not the webhook.)
  if (event.event === "payment.failed") {
    const razorpayOrderId = event.payload?.payment?.entity?.order_id;
    if (razorpayOrderId) {
      await db
        .update(orders)
        .set({ status: "cancelled", updatedAt: new Date() })
        .where(and(eq(orders.razorpayOrderId, razorpayOrderId), eq(orders.status, "pending")));
    }
  }

  return c.json({ data: { ok: true } });
});
