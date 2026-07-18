import { createBrowserClient } from "@supabase/ssr";

// Used from Client Components (login form, etc.) -- same NEXT_PUBLIC_
// env vars as server.ts/proxy.ts.
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
