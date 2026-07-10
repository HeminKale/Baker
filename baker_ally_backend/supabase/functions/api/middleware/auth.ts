import { createMiddleware } from "npm:hono/factory";
import type { User } from "npm:@supabase/supabase-js";

import { supabaseAdmin } from "../lib/supabaseAdmin.ts";

export type AuthEnv = { Variables: { user: User } };

// Google Sign-In is native to Supabase Auth (Milestone 1 scope -- phone OTP
// via Firebase is a deferred fast-follow, see Milestone readme/Milestone 1.md),
// so the JWT reaching every route here is a real Supabase-issued token.
// supabase.auth.getUser() verifies its signature and looks the user up by
// `sub` -- exactly the pattern in backend_stack.md §5.
export const authMiddleware = createMiddleware<AuthEnv>(async (c, next) => {
  const token = c.req.header("Authorization")?.replace("Bearer ", "");
  if (!token) {
    return c.json({ error: { code: "UNAUTHORIZED", message: "Missing bearer token" } }, 401);
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) {
    return c.json({ error: { code: "UNAUTHORIZED", message: "Invalid or expired token" } }, 401);
  }

  c.set("user", data.user);
  await next();
});

// Not attached to any route yet -- Phase 1 has no admin routes (those land in
// Phase 6). Reads the role claim written by migrations/006's JWT hook.
export const adminMiddleware = createMiddleware<AuthEnv>(async (c, next) => {
  const user = c.get("user");
  if (user.app_metadata?.role !== "admin") {
    return c.json({ error: { code: "FORBIDDEN", message: "Admin role required" } }, 403);
  }
  await next();
});
