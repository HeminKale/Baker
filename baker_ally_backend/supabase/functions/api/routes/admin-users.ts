import { Hono } from "npm:hono";
import { zValidator } from "npm:@hono/zod-validator";
import { z } from "npm:zod";
import { and, desc, eq, ilike, or, sql } from "npm:drizzle-orm";

import { adminMiddleware, authMiddleware, type AuthEnv } from "../middleware/auth.ts";
import { db } from "../lib/db.ts";
import { supabaseAdmin } from "../lib/supabaseAdmin.ts";
import { roles, users } from "../db/schema.ts";

export const adminUsersRoute = new Hono<AuthEnv>();

// Admin only -- not building the Privilege Level editor this milestone
// (privilege_levels/privilege_level_permissions stay untouched, ready for
// later). This is a simple Admin/Staff assignment tool.
adminUsersRoute.use("/admin/users*", authMiddleware, adminMiddleware);

const ADMIN_ROLE_NAMES = ["admin", "staff"] as const;

const listUsersQuerySchema = z.object({
  role: z.enum(ADMIN_ROLE_NAMES).optional(),
  q: z.string().min(1).max(200).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// This is the admin-panel user list (who has admin/staff access), not a
// customer directory -- always scoped to admin/staff roles.
adminUsersRoute.get("/admin/users", zValidator("query", listUsersQuerySchema), async (c) => {
  const { role, q, page, limit } = c.req.valid("query");
  const offset = (page - 1) * limit;

  const conditions = [role ? eq(roles.name, role) : or(eq(roles.name, "admin"), eq(roles.name, "staff"))];
  if (q) conditions.push(or(ilike(users.email, `%${q}%`), ilike(users.fullName, `%${q}%`)));
  const whereClause = and(...conditions);

  const rows = await db
    .select({ user: users, roleName: roles.name })
    .from(users)
    .innerJoin(roles, eq(users.roleId, roles.id))
    .where(whereClause)
    .orderBy(desc(users.createdAt))
    .limit(limit)
    .offset(offset);

  const [{ count }] = await db
    .select({ count: sql<number>`count(*)::int` })
    .from(users)
    .innerJoin(roles, eq(users.roleId, roles.id))
    .where(whereClause);

  return c.json({ data: rows.map((r) => ({ ...r.user, role: r.roleName })), meta: { page, limit, total: count } });
});

const inviteSchema = z.object({
  email: z.string().email(),
  role: z.enum(ADMIN_ROLE_NAMES),
});

// Creates the auth user + matching public.users row with role_id resolved up
// front -- deliberately bypasses the customer-only POST /v1/auth/me
// self-provisioning path, whose fallback role is hardcoded to
// customer_individual (6.2 plan gotcha). No transactional email provider is
// configured anywhere in this codebase, so this generates a Supabase invite
// link (equivalent to a recovery link for a brand-new user -- sets their
// password on first click) and returns it for the admin to copy/send
// manually, rather than emailing it.
adminUsersRoute.post("/admin/users/invite", zValidator("json", inviteSchema), async (c) => {
  const { email, role } = c.req.valid("json");

  const [roleRow] = await db.select().from(roles).where(eq(roles.name, role)).limit(1);
  if (!roleRow) {
    return c.json({ error: { code: "ROLE_NOT_FOUND", message: `Role '${role}' is not seeded` } }, 500);
  }

  const { data, error } = await supabaseAdmin.auth.admin.generateLink({ type: "invite", email });
  if (error || !data?.user) {
    return c.json({ error: { code: "INVITE_FAILED", message: error?.message ?? "Could not create user" } }, 500);
  }

  await db
    .insert(users)
    .values({ id: data.user.id, email, roleId: roleRow.id })
    .onConflictDoNothing({ target: users.id });

  return c.json({ data: { userId: data.user.id, actionLink: data.properties.action_link } }, 201);
});

const patchRoleSchema = z.object({ role: z.enum(ADMIN_ROLE_NAMES) });

// Role changes take effect on the user's next token refresh (the JWT hook
// stamps the role at issuance), not instantly -- expected, not a bug.
adminUsersRoute.patch("/admin/users/:id/role", zValidator("json", patchRoleSchema), async (c) => {
  const userId = c.req.param("id");
  const { role } = c.req.valid("json");

  const [roleRow] = await db.select().from(roles).where(eq(roles.name, role)).limit(1);
  if (!roleRow) {
    return c.json({ error: { code: "ROLE_NOT_FOUND", message: `Role '${role}' is not seeded` } }, 500);
  }

  const [updated] = await db.update(users).set({ roleId: roleRow.id }).where(eq(users.id, userId)).returning();
  if (!updated) {
    return c.json({ error: { code: "USER_NOT_FOUND", message: "User not found" } }, 404);
  }
  return c.json({ data: updated });
});
