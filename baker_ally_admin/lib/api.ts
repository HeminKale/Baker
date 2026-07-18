import { createClient as createServerSupabaseClient } from "./supabase/server";
import { request, ApiError } from "./api-core";

export { ApiError };

/** Server Components / Server Actions -- pulls the bearer token off the
 *  current cookie-backed session. Server-only (imports next/headers via
 *  supabase/server.ts) -- client components must use apiFetchClient from
 *  lib/api-client.ts instead. */
export async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const supabase = await createServerSupabaseClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  return request<T>(path, session?.access_token, init);
}
