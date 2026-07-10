import { drizzle } from "npm:drizzle-orm/postgres-js";
import postgres from "npm:postgres";

import * as schema from "../db/schema.ts";

// Supavisor transaction-mode pooler (port 6543) -- required in Edge Functions,
// see backend_stack.md §6. Direct 5432 is for the CLI/migrations only.
const client = postgres(Deno.env.get("DB_POOL_URL")!, { prepare: false });

export const db = drizzle(client, { schema });
