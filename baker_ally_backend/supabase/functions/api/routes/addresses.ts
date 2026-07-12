import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, desc, eq, ne } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { addresses } from "../db/schema.ts";

export const addressesRoute = new Hono<AuthEnv>();

addressesRoute.use("/addresses*", authMiddleware);

// Milestone 3 builds only list + add -- just enough to unblock checkout
// (05_cart_and_checkout.md §6 address selector). PATCH/DELETE and the full
// "Delivery Addresses" management screen are Phase 5 (06_profile_and_account.md).

addressesRoute.get("/addresses", async (c) => {
  const authUser = c.get("user");
  const rows = await db
    .select()
    .from(addresses)
    .where(eq(addresses.userId, authUser.id))
    .orderBy(desc(addresses.isDefault), desc(addresses.createdAt));
  return c.json({ data: rows });
});

const createAddressSchema = z.object({
  label: z.string().max(50).optional(),
  line1: z.string().min(1).max(200),
  line2: z.string().max(200).optional(),
  city: z.string().min(1).max(100),
  state: z.string().min(1).max(100),
  pincode: z.string().min(4).max(10),
  isDefault: z.boolean().optional(),
});

addressesRoute.post("/addresses", zValidator("json", createAddressSchema), async (c) => {
  const authUser = c.get("user");
  const body = c.req.valid("json");

  const existing = await db
    .select({ id: addresses.id })
    .from(addresses)
    .where(eq(addresses.userId, authUser.id));

  // First address is always default so checkout has one to preselect.
  const makeDefault = existing.length === 0 ? true : body.isDefault === true;

  if (makeDefault && existing.length > 0) {
    // Server enforces a single default (06_profile_and_account.md Key Rules).
    await db
      .update(addresses)
      .set({ isDefault: false })
      .where(and(eq(addresses.userId, authUser.id), ne(addresses.isDefault, false)));
  }

  const [created] = await db
    .insert(addresses)
    .values({
      userId: authUser.id,
      label: body.label ?? null,
      line1: body.line1,
      line2: body.line2 ?? null,
      city: body.city,
      state: body.state,
      pincode: body.pincode,
      isDefault: makeDefault,
    })
    .returning();

  return c.json({ data: created }, 201);
});
