# Milestone 6 — Admin Web Panel

Status: **code complete and deployed live.** Built 2026-07-18 in one session, across all 8 sub-phases (6.1–6.8). Unlike most prior milestones, the backend pieces here were pushed to the live Supabase project and Edge Function *throughout* the build (each sub-phase: migration applied via `supabase db query -f ... --linked`, then `supabase functions deploy api`, then curl-verified). Plan file: `C:\Users\hemin\.claude\plans\gentle-drifting-parrot.md`.

Milestone 6 adds a brand-new third app — a Next.js admin/staff web panel — talking to the **same backend** the Flutter app uses, via a new `/v1/admin/*` route family.

## 1. What Was Built

**New app**: `baker_ally_admin/` — Next.js 16 (App Router, Turbopack), TypeScript, Tailwind, shadcn/ui (Base UI-backed "base-nova" style — components use a `render` prop, not Radix's `asChild`). See root `CLAUDE.md` for how this app fits into the 3-app repo (Flutter mobile / Hono backend / Next admin).

**Auth & access control (6.1–6.2)**:
- Email+password login (`app/login`) via Supabase Auth, session cookies handled by `@supabase/ssr`.
- `proxy.ts` (Next 16's renamed `middleware.ts`) refreshes the session on every request and redirects: no session → `/login`, wrong role → `/unauthorized`.
- Two roles: `admin` (full access) and `staff` (everything except Discounts and Users — see `lib/nav.ts`). Role is read from the JWT's `app_metadata`, stamped by the existing `custom_access_token_hook`.
- Backend: `middleware/auth.ts` refactored from a single `adminMiddleware` into a `requireRole(...roles)` factory — `adminMiddleware = requireRole("admin")`, `adminOrStaffMiddleware = requireRole("admin", "staff")`.
- CORS: `hono/cors` scoped to `/v1/admin/*` only (not global — the Flutter app's routes are untouched), validated against the `ADMIN_WEB_ORIGIN` secret.

**Product & catalog management (6.3)**:
- Categories & sub-categories: create/edit, active toggle.
- Products: list with search/category/sub-category/active filters, pagination; create/edit metadata (name, description, active, trending).
- Variants: CRUD with SKU uniqueness, inline stock updates kept as a **separate** endpoint from price edits (`PATCH /admin/variants/:id/stock`) so restocking stays a distinct, trigger-aware action (see 6.5).
- Images: multipart upload to Supabase Storage (`product-images` bucket, already existed from Milestone 1), delete.
- Wishlist Insights (`/insights/wishlist`): most-wishlisted variants first, to prioritize what to restock.

**Discount management (6.4)** — admin-only:
- List/create/edit discounts (percent, flat, free-shipping), min order value, usage caps, start/expiry windows.

**Back-in-stock push notifications (6.5)**:
- Wishlisting an out-of-stock item *is* the "notify me" request (no separate opt-in).
- DB trigger `trg_notify_restock` (migration 024) fires when a variant's `stock_qty` goes from 0/negative to positive (via the admin panel's stock endpoints), calling the Edge Function asynchronously via `pg_net`.
- `routes/internal.ts` (`POST /internal/notify-restock`, gated by an `x-internal-secret` header) looks up everyone who wishlisted that variant, sends a push via `lib/fcm.ts` (hand-rolled FCM HTTP v1 client with OAuth2 JWT signing), and stamps `wishlists.last_notified_at` — skips anyone notified in the last 24h.
- Flutter side: `WishlistHeart` moved onto catalog tiles (top-right, mirrors the badge row) so wishlisting is a one-tap action from browsing, not just product detail. `core/notifications/fcm_service.dart` registers the FCM token and shows local notifications when the app is foregrounded (added `flutter_local_notifications`).
- **Firebase wiring is deliberately incomplete** — see §3.

**Order management (6.6)**:
- List with status/date/customer-name filters, pagination.
- Order detail: items, address, bill breakdown.
- Guarded status transitions (e.g. can't go from `delivered` back to `pending`); cancelling an order restocks its items.

**User/role management (6.7)** — admin-only:
- List existing admin/staff users.
- Invite: generates a Supabase invite link and creates the user row. **No email provider is configured yet**, so the link is shown in the dialog for you to copy and send manually (Slack/WhatsApp/email) rather than auto-sent.
- Role changes take effect on the user's *next* sign-in (JWT claims are stamped at token-issue time, not live).

**Curated cross-sell (6.8)**:
- Every product's "You Might Also Like" list was 100% algorithmic before this. Now positions 5–7 of the 10-slot recommendation list prefer an admin-curated pick (`product_cross_sell` table, migration 025) if one exists for that source product, falling back to algorithmic. Positions 1–4 and 8–10 stay algorithmic either way.
- Applies to both `/products/:id/related` and `/checkout/recommendations` via a shared `buildRecommendations()` helper in `routes/catalog.ts`.
- Order Again's "Frequently Bought Together" is untouched — that's purchase-history-based, not in scope here.

## 2. New Tables / Columns (migrations 022–025)

| Migration | What |
|---|---|
| `022_AP_seed_staff_role.sql` | Seeds the `staff` role row (idempotent) |
| `023_AP_wishlists_notify_columns.sql` | `wishlists.last_notified_at`, index on `wishlists.variant_id` |
| `024_AP_restock_notify_trigger.sql` | `pg_net` extension, `notify_restock()` trigger function (`SECURITY DEFINER`, reads the shared secret from Supabase Vault, not a GUC), `trg_notify_restock` trigger |
| `025_AP_product_cross_sell.sql` | `product_cross_sell` table (`source_product_id`, `recommended_product_id`, `sort_order`, unique pair constraint) |

## 3. ⚠️ PENDING / Open Items

1. **Firebase push notifications aren't fully wired end-to-end.** Everything is built and deployed (trigger, `lib/fcm.ts`, `routes/internal.ts`, the Flutter `fcm_service.dart`) but three manual steps are still outstanding — see `Milestone 6 manual steps.md` §D. Until then, restocking an item just doesn't send a push; nothing errors (the trigger and `routes/internal.ts` both degrade gracefully if the secret/service-account key aren't set).
2. **No email provider for user invites (6.7).** Invite links are copy/paste-and-send-manually. A transactional email provider (Resend, Postmark, etc.) is a future addition, not blocking.
3. **No browser-driven UI testing this session** — no browser automation tool was available. Every route was curl-verified for the correct 401/403/CORS behavior after each deploy, and all static checks (`deno check`, `tsc --noEmit`, `next build`, `flutter analyze`) are clean, but the actual login → CRUD → logout flows in a browser haven't been walked through by an agent. You tested this yourself rather than a synthetic admin account being created.
4. **Admin panel isn't deployed anywhere public yet** — it currently only runs via `npm run dev` locally. See `Milestone 6 manual steps.md` §E for deploying it to Vercel.

## 4. Deviations From the Plan (all deliberate)

1. **6.1 CORS** — no pivot needed, `hono/cors` scoped to `/v1/admin/*` worked exactly as planned.
2. **6.5 secret delivery pivot** — the plan's `ALTER DATABASE ... SET app.foo` custom GUC for the trigger's shared secret **failed live**: Supabase's managed `postgres` role isn't a real superuser (`permission denied to set parameter`). Switched to Supabase Vault (`vault.create_secret` / `vault.decrypted_secrets`, already enabled on the project). `notify_restock()` is `SECURITY DEFINER` so it can read the vault regardless of which role's `UPDATE` fired the trigger.
3. **6.5 `main.dart` wiring deferred** — `Firebase.initializeApp()` was **not** added to `main.dart` yet (your explicit call when asked, to avoid breaking the Flutter build before `flutterfire configure` has been run and `firebase_options.dart` exists). See §3.1.

## 5. Also Found and Fixed Mid-Build

`lib/api.ts` originally imported both the server-only Supabase client (`next/headers`) and the browser client in the same file — this broke the Turbopack build the instant a Client Component imported it. Split into three files:
- `lib/api-core.ts` — shared fetch logic (FormData-aware), zero Supabase imports.
- `lib/api.ts` — server-only (`apiFetch`), for Server Components.
- `lib/api-client.ts` — browser-only (`apiFetchClient`), for Client Components.

**Any new Client Component must import from `api-client.ts`, not `api.ts`.**

## 6. Verification Done

- `deno check` clean throughout every sub-phase.
- `npx tsc --noEmit` + `npm run build` clean after every sub-phase.
- `flutter analyze` clean (only pre-existing baseline info lints).
- Every new backend route curl-verified live for correct 401/CORS behavior after each deploy.
- **No browser-driven UI testing** (see §3.3).

## 7. Known Gaps / Deliberate Non-Scope

- Firebase push notifications need 3 manual steps before they fire (§3.1).
- No transactional email for invites (§3.2).
- Admin panel not yet deployed to a public URL (§3.4) — see the manual steps doc.
- Discount and Users sections are admin-only; staff cannot see or touch them (by design, per `lib/nav.ts`).

See `Milestone 6 manual steps.md` for exactly what to run/click before this is fully live, including how to deploy the admin panel to Vercel.
