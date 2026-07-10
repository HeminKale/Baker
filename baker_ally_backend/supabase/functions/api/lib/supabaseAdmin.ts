import { createClient } from "npm:@supabase/supabase-js";

// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-provided inside every
// Edge Function -- do not set them manually (backend_stack.md §16).
export const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
