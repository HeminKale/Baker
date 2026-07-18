import { createClient as createServerSupabaseClient } from "./supabase/server";
import { createClient as createBrowserSupabaseClient } from "./supabase/client";

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
  ) {
    super(message);
  }
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL!;

async function request<T>(path: string, accessToken: string | undefined, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
      ...init?.headers,
    },
  });

  const body = await res.json().catch(() => null);

  if (!res.ok) {
    throw new ApiError(res.status, body?.error?.code ?? "UNKNOWN", body?.error?.message ?? res.statusText);
  }

  return body as T;
}

/** Server Components / Server Actions -- pulls the bearer token off the
 *  current cookie-backed session. */
export async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const supabase = await createServerSupabaseClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  return request<T>(path, session?.access_token, init);
}

/** Client Components -- same shape, browser-side session lookup. */
export async function apiFetchClient<T>(path: string, init?: RequestInit): Promise<T> {
  const supabase = createBrowserSupabaseClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  return request<T>(path, session?.access_token, init);
}
