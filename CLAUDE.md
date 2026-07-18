# Baker Ally — repo map

Three separate apps in this repo, sharing one Supabase project (`bpmtnsaebrnuoujwxfea`). Full architecture: `Plan.md` and `Planning docs/Architecture/`. Per-milestone status/manual-steps docs: `Milestone readme/`.

| Path | What it is | Stack |
|---|---|---|
| `baker_ally_flutter/` | Customer mobile app (iOS + Android). **Zero admin code.** | Flutter/Dart, Riverpod, GoRouter, Dio, Drift |
| `baker_ally_backend/` | Shared backend, one Hono app deployed as a single Supabase Edge Function (`api`). Serves both the mobile app and the admin panel. | Deno, Hono, Zod, Drizzle ORM |
| `baker_ally_admin/` | Admin/staff web panel (Milestone 6). Talks to the same backend via `/v1/admin/*` routes, gated by `requireRole("admin"\|"staff")` in `baker_ally_backend/supabase/functions/api/middleware/auth.ts`. | Next.js 16 (App Router, Turbopack), TypeScript, Tailwind, shadcn/ui |
| `migrations/` | All SQL migrations for the one shared Postgres database, sequentially numbered. `AP_` in the filename = Admin Panel / Milestone 6. | Plain numbered `.sql` files |

## How migrations actually get applied

There is no `supabase/migrations/` dir and no `supabase db push` workflow here — migration files in `/migrations/` are applied by hand against the linked project:
```
cd baker_ally_backend
supabase db query -f "../migrations/0NN_name.sql" --linked
```
(A `Timeout while shutting down PostHog` line after a successful query is CLI telemetry noise, not a failure — check the `rows`/result above it.)

## Backend deploys

`baker_ally_backend` is one Edge Function serving both frontends — `cd baker_ally_backend && supabase functions deploy api`. A change here can affect the live Flutter app, so keep new admin-only behavior scoped (e.g. CORS is only enabled on `/v1/admin/*`, not globally).

## Next.js 16 note

`baker_ally_admin` is on Next.js 16, which renamed `middleware.ts`/`middleware()` to `proxy.ts`/`proxy()` (Node runtime only, no Edge) and made `cookies()`/`headers()` async-only. Its own `AGENTS.md` flags this — don't assume Next.js 14/15 patterns from training data.

## Environments

Both `baker_ally_flutter/.env` and `baker_ally_admin/.env.local` point at the same real staging Supabase project (per `Developer Environment Setup.md`, staging doubles as the dev environment — no local Supabase stack). Never commit either file; use the `.env.example`/`.env.local.example` templates.
