import { Hono } from "npm:hono";
import { eq } from "npm:drizzle-orm";

import { authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { rateLimitMiddleware } from "../middleware/rateLimit.ts";
import { db } from "../lib/db.ts";
import { roles, users } from "../db/schema.ts";

export const authRoute = new Hono<AuthEnv>();

// Signup-hook replacement (Phase 1.5): idempotently creates the public.users
// row with the default role on first call after a Google login, then returns
// {user, role} either way. Flutter calls this once per login to hydrate
// authProvider/profileProvider (Phase 1.4).
authRoute.post("/auth/me", rateLimitMiddleware, authMiddleware, async (c) => {
  const authUser = c.get("user");

  const existing = await db
    .select({ user: users, roleName: roles.name })
    .from(users)
    .innerJoin(roles, eq(users.roleId, roles.id))
    .where(eq(users.id, authUser.id))
    .limit(1);

  if (existing.length > 0) {
    const { user, roleName } = existing[0];
    return c.json({ data: { user, role: roleName } });
  }

  const [defaultRole] = await db
    .select()
    .from(roles)
    .where(eq(roles.name, "customer_individual"))
    .limit(1);

  if (!defaultRole) {
    return c.json(
      { error: { code: "ROLE_NOT_SEEDED", message: "customer_individual role is missing -- run migrations" } },
      500,
    );
  }

  const [created] = await db
    .insert(users)
    .values({
      id: authUser.id,
      email: authUser.email ?? null,
      phone: authUser.phone ?? null,
      roleId: defaultRole.id,
    })
    .returning();

  return c.json({ data: { user: created, role: defaultRole.name } }, 201);
});
