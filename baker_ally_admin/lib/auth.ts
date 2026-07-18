import { redirect } from "next/navigation";
import { apiFetch, ApiError } from "./api";
import type { MeResponse } from "./types";

// Server-side re-check, on top of proxy.ts's cookie-level gate (defense in
// depth per the 6.2 plan). Pages that are admin-only (discounts, users) call
// requireAdmin() instead so Staff is rejected server-side, not just
// nav-hidden.
export async function requireUser(): Promise<MeResponse["data"]> {
  let me: MeResponse["data"];
  try {
    me = (await apiFetch<MeResponse>("/v1/users/me")).data;
  } catch (err) {
    if (err instanceof ApiError) {
      redirect("/login");
    }
    throw err;
  }

  if (me.role !== "admin" && me.role !== "staff") {
    redirect("/unauthorized");
  }

  return me;
}

export async function requireAdmin(): Promise<MeResponse["data"]> {
  const me = await requireUser();
  if (me.role !== "admin") {
    redirect("/unauthorized");
  }
  return me;
}
