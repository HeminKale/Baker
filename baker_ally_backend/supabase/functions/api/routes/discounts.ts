import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";

import { evaluateDiscount } from "../lib/discountEngine.ts";

export const discountsRoute = new Hono();

// Public -- validating a code against a total touches no user-owned data, same
// posture as the public catalog browse routes. The authoritative recompute
// still happens server-side at POST /v1/cart/checkout; this endpoint only
// drives the live bill preview (05_cart_and_checkout.md §9).

const validateSchema = z.object({
  code: z.string().min(1).max(50),
  cartTotal: z.coerce.number().int().min(0),
});

discountsRoute.post("/discounts/validate", zValidator("json", validateSchema), async (c) => {
  const { code, cartTotal } = c.req.valid("json");

  const result = await evaluateDiscount(code.trim().toUpperCase(), cartTotal);
  if (!result.ok) {
    const status = result.code === "DISCOUNT_NOT_FOUND" ? 404 : 409;
    return c.json({ error: { code: result.code, message: result.message } }, status);
  }

  return c.json({
    data: {
      code: result.code,
      type: result.type,
      value: result.value,
      discountValue: result.discountValue,
      freeShipping: result.freeShipping,
    },
  });
});
