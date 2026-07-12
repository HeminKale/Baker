import { and, eq, sql } from "npm:drizzle-orm";

import { db } from "./db.ts";
import { discounts } from "../db/schema.ts";

// Server-side discount validation + calculation, shared by
// POST /v1/discounts/validate (live bill update) and POST /v1/cart/checkout
// (authoritative recompute). The client never computes the discount itself
// (05_cart_and_checkout.md §9, "Discount code validation: Server-side only").

export type DiscountResult = {
  discountId: string;
  code: string;
  type: string; // 'percent' | 'flat' | 'free_shipping'
  value: number;
  discountValue: number; // paise taken off the subtotal (0 for free_shipping)
  freeShipping: boolean;
};

export type DiscountError =
  | { ok: false; code: "DISCOUNT_NOT_FOUND"; message: string }
  | { ok: false; code: "DISCOUNT_INACTIVE"; message: string }
  | { ok: false; code: "DISCOUNT_MIN_ORDER"; message: string };

export type DiscountOutcome = ({ ok: true } & DiscountResult) | DiscountError;

/** Looks up an active, in-window discount by code and computes what it takes
 *  off a `cartTotal` (subtotal in paise). Pure lookup + arithmetic -- callers
 *  decide the HTTP shape / whether to persist uses_count. */
export async function evaluateDiscount(code: string, cartTotal: number): Promise<DiscountOutcome> {
  const [row] = await db.select().from(discounts).where(eq(discounts.code, code)).limit(1);

  if (!row) {
    return { ok: false, code: "DISCOUNT_NOT_FOUND", message: "Invalid or expired code" };
  }

  const now = new Date();
  const notStarted = row.startsAt != null && row.startsAt > now;
  const expired = row.expiresAt != null && row.expiresAt < now;
  const usedUp = row.maxUses != null && row.usesCount >= row.maxUses;
  if (!row.isActive || notStarted || expired || usedUp) {
    return { ok: false, code: "DISCOUNT_INACTIVE", message: "Invalid or expired code" };
  }

  if (cartTotal < row.minOrderValue) {
    return {
      ok: false,
      code: "DISCOUNT_MIN_ORDER",
      message: `Minimum order of ₹${(row.minOrderValue / 100).toFixed(0)} required for this code`,
    };
  }

  let discountValue = 0;
  let freeShipping = false;
  if (row.type === "percent") {
    discountValue = Math.round((cartTotal * row.value) / 100);
  } else if (row.type === "flat") {
    discountValue = Math.min(row.value, cartTotal); // never discount below zero
  } else if (row.type === "free_shipping") {
    freeShipping = true;
  }

  return {
    ok: true,
    discountId: row.id,
    code: row.code!,
    type: row.type,
    value: row.value,
    discountValue,
    freeShipping,
  };
}

/** Best-effort increment of uses_count after an order that used the code is
 *  confirmed. Bounded by max_uses so a race can't over-consume a limited code. */
export async function incrementDiscountUses(discountId: string): Promise<void> {
  await db
    .update(discounts)
    .set({ usesCount: sql`${discounts.usesCount} + 1` })
    .where(
      and(
        eq(discounts.id, discountId),
        sql`(${discounts.maxUses} IS NULL OR ${discounts.usesCount} < ${discounts.maxUses})`,
      ),
    );
}
