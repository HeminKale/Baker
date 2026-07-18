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

// Shared by lib/api.ts (server) and lib/api-client.ts (browser) -- kept free
// of any Supabase import so client components importing apiFetchClient don't
// pull in the server-only "next/headers" dependency through this module.
export async function request<T>(path: string, accessToken: string | undefined, init?: RequestInit): Promise<T> {
  // FormData bodies (image upload) must NOT get a manual Content-Type -- the
  // browser sets its own multipart boundary. JSON bodies get it explicitly
  // since callers pass already-stringified strings, not object literals.
  const isFormData = init?.body instanceof FormData;

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: {
      ...(isFormData ? {} : { "Content-Type": "application/json" }),
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
