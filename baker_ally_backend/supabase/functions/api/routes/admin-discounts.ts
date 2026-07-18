import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { desc, eq } from "npm:drizzle-orm";

import { adminMiddleware, authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { discounts } from "../db/schema.ts";

export const adminDiscountsRoute = new Hono<AuthEnv>();

// Admin only -- Staff doesn't get discount management (6.4 plan).
adminDiscountsRoute.use("/admin/discounts*", authMiddleware, adminMiddleware);

adminDiscountsRoute.get("/admin/discounts", async (c) => {
  const rows = await db.select().from(discounts).orderBy(desc(discounts.createdAt));
  return c.json({ data: rows });
});

// Fields match the `discounts` table / evaluateDiscount() in
// lib/discountEngine.ts exactly -- v1 stays cart-wide-by-code, no new logic
// needed there. Codes are stored uppercase to match evaluateDiscount's
// callers (checkout.ts, discounts.ts), which always uppercase before lookup.
const discountSchema = z.object({
  code: z.string().min(1).max(50).optional(),
  name: z.string().min(1).max(200),
  type: z.enum(["percent", "flat", "free_shipping"]),
  value: z.number().int().min(0),
  minOrderValue: z.number().int().min(0).optional(),
  maxUses: z.number().int().min(1).optional(),
  isActive: z.boolean().optional(),
  startsAt: z.string().datetime().optional(),
  expiresAt: z.string().datetime().optional(),
});

function isDuplicateCodeError(err: unknown): boolean {
  return err instanceof Error && err.message.includes("discounts_code_key");
}

adminDiscountsRoute.post("/admin/discounts", zValidator("json", discountSchema), async (c) => {
  const body = c.req.valid("json");

  try {
    const [created] = await db
      .insert(discounts)
      .values({
        code: body.code ? body.code.trim().toUpperCase() : null,
        name: body.name,
        type: body.type,
        value: body.value,
        minOrderValue: body.minOrderValue ?? 0,
        maxUses: body.maxUses ?? null,
        isActive: body.isActive ?? true,
        startsAt: body.startsAt ? new Date(body.startsAt) : null,
        expiresAt: body.expiresAt ? new Date(body.expiresAt) : null,
      })
      .returning();
    return c.json({ data: created }, 201);
  } catch (err) {
    if (isDuplicateCodeError(err)) {
      return c.json({ error: { code: "DUPLICATE_CODE", message: "A discount with this code already exists" } }, 409);
    }
    throw err;
  }
});

const updateDiscountSchema = discountSchema.partial();

// No DELETE -- discounts.id is FK'd from historical orders.discount_id.
// Deactivate via PUT {isActive: false} instead.
adminDiscountsRoute.put("/admin/discounts/:id", zValidator("json", updateDiscountSchema), async (c) => {
  const id = c.req.param("id");
  const body = c.req.valid("json");

  try {
    const [updated] = await db
      .update(discounts)
      .set({
        ...(body.code !== undefined ? { code: body.code ? body.code.trim().toUpperCase() : null } : {}),
        ...(body.name !== undefined ? { name: body.name } : {}),
        ...(body.type !== undefined ? { type: body.type } : {}),
        ...(body.value !== undefined ? { value: body.value } : {}),
        ...(body.minOrderValue !== undefined ? { minOrderValue: body.minOrderValue } : {}),
        ...(body.maxUses !== undefined ? { maxUses: body.maxUses } : {}),
        ...(body.isActive !== undefined ? { isActive: body.isActive } : {}),
        ...(body.startsAt !== undefined ? { startsAt: new Date(body.startsAt) } : {}),
        ...(body.expiresAt !== undefined ? { expiresAt: new Date(body.expiresAt) } : {}),
      })
      .where(eq(discounts.id, id))
      .returning();

    if (!updated) {
      return c.json({ error: { code: "DISCOUNT_NOT_FOUND", message: "Discount not found" } }, 404);
    }
    return c.json({ data: updated });
  } catch (err) {
    if (isDuplicateCodeError(err)) {
      return c.json({ error: { code: "DUPLICATE_CODE", message: "A discount with this code already exists" } }, 409);
    }
    throw err;
  }
});
