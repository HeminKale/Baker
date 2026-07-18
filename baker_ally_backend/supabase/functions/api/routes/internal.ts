import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, eq, isNotNull } from "npm:drizzle-orm";

import { db } from "../lib/db.ts";
import { sendPushNotification } from "../lib/fcm.ts";
import { products, productVariants, users, wishlists } from "../db/schema.ts";

export const internalRoute = new Hono();

const NOTIFY_COOLDOWN_MS = 24 * 60 * 60 * 1000;

// Called by the AFTER UPDATE trigger in 024_AP_restock_notify_trigger.sql via
// pg_net when a variant's stock_qty goes 0 -> positive. Shared-secret header,
// not a user JWT -- same posture as webhooks.ts's HMAC check, just a static
// secret since this is internal-only (never called by the client or a
// third-party). pg_net is fire-and-forget with no retry -- accepted tradeoff
// for v1 (Milestone 6 plan §6.5).
internalRoute.use("/internal/*", async (c, next) => {
  const secret = c.req.header("x-internal-secret");
  if (!secret || secret !== Deno.env.get("INTERNAL_NOTIFY_SECRET")) {
    return c.json({ error: { code: "UNAUTHORIZED", message: "Invalid internal secret" } }, 401);
  }
  await next();
});

const notifyRestockSchema = z.object({ variantId: z.string().uuid() });

internalRoute.post("/internal/notify-restock", zValidator("json", notifyRestockSchema), async (c) => {
  const { variantId } = c.req.valid("json");

  const rows = await db
    .select({
      wishlistId: wishlists.id,
      lastNotifiedAt: wishlists.lastNotifiedAt,
      fcmToken: users.fcmToken,
      productName: products.name,
      variantName: productVariants.name,
    })
    .from(wishlists)
    .innerJoin(users, eq(wishlists.userId, users.id))
    .innerJoin(productVariants, eq(wishlists.variantId, productVariants.id))
    .innerJoin(products, eq(productVariants.productId, products.id))
    .where(and(eq(wishlists.variantId, variantId), isNotNull(users.fcmToken)));

  const now = new Date();
  let sent = 0;

  for (const row of rows) {
    if (!row.fcmToken) continue;
    if (row.lastNotifiedAt && now.getTime() - row.lastNotifiedAt.getTime() < NOTIFY_COOLDOWN_MS) continue;

    try {
      const result = await sendPushNotification({
        fcmToken: row.fcmToken,
        title: "Back in stock!",
        body: `${row.productName} (${row.variantName}) is back in stock.`,
        data: { type: "restock", variantId },
      });

      if (result.ok) {
        sent++;
        await db.update(wishlists).set({ lastNotifiedAt: now }).where(eq(wishlists.id, row.wishlistId));
      } else {
        console.error(`FCM send failed for wishlist ${row.wishlistId}: ${result.error}`);
      }
    } catch (err) {
      // FIREBASE_SERVICE_ACCOUNT_KEY not configured yet, or a transient
      // network error -- degrade gracefully rather than 500 the whole
      // request (pg_net has no retry, but other wishlisters in this loop
      // should still get their turn).
      console.error(`FCM send threw for wishlist ${row.wishlistId}:`, err);
    }
  }

  return c.json({ data: { candidates: rows.length, sent } });
});
