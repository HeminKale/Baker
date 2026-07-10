import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { eq } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { roles, users } from "../db/schema.ts";

export const usersRoute = new Hono<AuthEnv>();

usersRoute.use("/users/*", authMiddleware);

usersRoute.get("/users/me", async (c) => {
  const authUser = c.get("user");

  const [row] = await db
    .select({ user: users, roleName: roles.name })
    .from(users)
    .innerJoin(roles, eq(users.roleId, roles.id))
    .where(eq(users.id, authUser.id))
    .limit(1);

  if (!row) {
    return c.json({ error: { code: "USER_NOT_FOUND", message: "Call POST /v1/auth/me first" } }, 404);
  }

  return c.json({ data: { user: row.user, role: row.roleName } });
});

const updateProfileSchema = z.object({
  fullName: z.string().min(1).max(200).optional(),
  businessName: z.string().max(200).optional(),
  gstin: z.string().max(20).optional(),
});

usersRoute.patch("/users/me", zValidator("json", updateProfileSchema), async (c) => {
  const authUser = c.get("user");
  const body = c.req.valid("json");

  const [updated] = await db
    .update(users)
    .set({
      ...(body.fullName !== undefined ? { fullName: body.fullName } : {}),
      ...(body.businessName !== undefined ? { businessName: body.businessName } : {}),
      ...(body.gstin !== undefined ? { gstin: body.gstin } : {}),
    })
    .where(eq(users.id, authUser.id))
    .returning();

  if (!updated) {
    return c.json({ error: { code: "USER_NOT_FOUND", message: "Call POST /v1/auth/me first" } }, 404);
  }

  return c.json({ data: { user: updated } });
});

const fcmTokenSchema = z.object({
  fcmToken: z.string().min(1),
});

usersRoute.post("/users/fcm-token", zValidator("json", fcmTokenSchema), async (c) => {
  const authUser = c.get("user");
  const { fcmToken } = c.req.valid("json");

  const [updated] = await db
    .update(users)
    .set({ fcmToken })
    .where(eq(users.id, authUser.id))
    .returning();

  if (!updated) {
    return c.json({ error: { code: "USER_NOT_FOUND", message: "Call POST /v1/auth/me first" } }, 404);
  }

  return c.json({ data: { ok: true } });
});
