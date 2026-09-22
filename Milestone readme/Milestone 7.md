# Milestone 7 — Projects (Per-Job Equipment Lists)

> Plan file: `Planning docs/Architecture/07_projects.md`. Built 2026-09-22.

Status: **code complete, not yet live.** Backend (schema + routes) and Flutter (models, repository, providers, screens, widgets) are all written and statically verified (`deno check`, `flutter analyze`, `flutter test`, `dart run build_runner build`). The migration has **not** been applied and the Edge Function has **not** been redeployed this session — the linked Supabase CLI account hit a `403` ("does not have the necessary privileges") against the `bpmtnsaebrnuoujwxfea` project, so those two steps are manual. See `Milestone 7 manual steps.md`.

Chefs can now create named Projects ("Hero's Birthday", "Superhero's Engagement") — per-job shopping lists distinct from the single Wishlist and the single Cart. Any product can be added to one or more Projects via a new icon next to the wishlist heart; a new top-bar icon opens the full Projects list (Active/Completed tabs); each Project shows its items with live pricing, an aggregate estimated total (struck-through original total when something's on sale), and an "Add All to Cart" action that sends the whole list to checkout in one tap.

## 1. What Was Built

**Database** (`migrations/027_AP_create_projects.sql`, not yet applied live):
- `projects` — `user_id`, `name`, `status` (`active`/`completed`, CHECK), `event_date`, `client_name`, `client_phone`, `notes` (all four nullable), `created_at`, `completed_at`.
- `project_items` — `project_id`, `variant_id`, `quantity`, `added_at`, `UNIQUE(project_id, variant_id)` (same upsert-friendly shape as `cart_items`).
- Prices are **not** snapshotted onto `project_items` — same live-join philosophy as `wishlists` (a Project is a running plan, not a receipt like `order_items`).

**Backend** (`baker_ally_backend/supabase/functions/api/`):
- `db/schema.ts` — `projects` and `projectItems` Drizzle tables, mirroring `wishlists`/`cartItems` conventions.
- `routes/projects.ts` (new) — full CRUD, all strictly authed and scoped to the caller's own projects:
  - `GET /v1/projects?status=` — list with item count, best-effort cover image, and estimated total (single batched query, no N+1).
  - `POST /v1/projects`, `PATCH /v1/projects/:id` (rename/edit/mark-complete/reopen in one endpoint — `completedAt` is set/cleared automatically on a status transition), `DELETE /v1/projects/:id`.
  - `GET /v1/projects/:id` — items joined to live variant/product/image data, plus server-computed `estimatedTotal`/`originalTotal` (same "server is the source of truth for money" rule `discountEngine.ts` follows for cart/checkout — quantity discounts are deliberately **not** applied here, per the plan's decision 3).
  - `POST/PATCH/DELETE /v1/projects/:id/items[/:itemId]` — add (upsert-increment)/update-quantity (0 = remove, matching cart's convention)/remove.
  - `GET /v1/projects/item-variant-ids` — flattened variantId set across active projects, backs the on-product icon's filled/outline state.
  - Two endpoints added during implementation, beyond the original plan sketch (needed to actually build the Add-to-Project dialog's per-row checkbox UI): `GET /v1/projects/item-membership/:variantId` (which of the caller's active projects already contain this variant) and `DELETE /v1/projects/:id/items/by-variant/:variantId` (toggle-off by variantId, mirroring wishlist's variant-keyed delete, since the dialog never has an item id handy).
- `index.ts` — `projectsRoute` mounted at `/v1`.

**Flutter** (`baker_ally_flutter/lib/features/projects/` — new module):
- Models: `Project`, `ProjectItem`, `ProjectDetail` (`data/models/`).
- `ProjectRepository` (`data/`) — thin Dio wrapper, network-first for list/detail (no Drift fallback — Projects list/detail are browse/manage surfaces, not a hot render path). The one thing that *is* Drift-cached is the flattened active-project variantId set (`CachedProjectItemVariantIds`, new Drift table, schema v5→v6 additive `onUpgrade`), for the same reason `CachedWishlistItems` exists: it's read on every tile render for the icon's fill state.
- `project_providers.dart` — `projectsProvider` (autoDispose list), `projectDetailProvider` (autoDispose family), `projectItemVariantIdsProvider` (`StateNotifierProvider`, seeded from cache then refreshed from server — mirrors `wishlistIdsProvider` exactly).
- Widgets: `AddToProjectIcon` (mirrors `WishlistHeart`'s placement/login-gating), `AddToProjectDialog` (bottom sheet: search → active-projects checkbox list → "+ New Project" pinned last, multi-select toggle per row), `ProjectsTopBarIcon` (mirrors `_AvatarButton`'s login-gating).
- Screens: `ProjectsListScreen` (`/projects` — Active/Completed `TabBar`, search, `[+ New]`, per-row delete + cover image + item count/estimate/event date), `ProjectDetailScreen` (`/projects/:id` — event/client subtitle with `[Edit]` sheet, item rows with strikethrough pricing + `[-] N [+]` stepper + per-row delete, AppBar delete + Mark Complete/Reopen toggle, totals footer with "Add All to Cart").
- `app_router.dart` — `/projects` and `/projects/:id` routes, both added to `_protectedPaths` (guest taps are gated the same way `/wishlist` already is).
- `app_shell.dart` — `ProjectsTopBarIcon` inserted between the address label and the avatar in `_TopBar`.
- `product_tile.dart` / `product_detail_screen.dart` — `AddToProjectIcon` placed next to `WishlistHeart` in both. **Note:** the actual current code keeps the heart next to the product name on the detail screen, not on the gallery image as `Milestone 6.5.md`'s changelog describes — the Add-to-Project icon was placed to match the real code, not the aspirational doc text. Worth reconciling separately; not in this milestone's scope.

## 2. Add All to Cart (§6a) — No New Cart Endpoint

`ProjectDetailScreen._addAllToCart()` maps every item to `(variantId, quantity)` and calls `cartProvider.notifier.addBatch(items)` — the exact same method Order Again's `group_detail_sheet.dart` already uses, backed by the already-built `POST /v1/cart/items/batch`. Nothing new needed on the cart side. Sends unconditionally (no per-item select step, unlike Order Again's sheet) and does **not** auto-mark the project Complete — confirmed as independent actions in the plan.

## 3. Scope Decisions (confirmed with you during planning, §10 of the plan doc)

1. Reopen a Completed project — allowed, AppBar action swaps Mark Complete ↔ Reopen.
2. Delete a project — allowed, direct icon tap (list row + detail AppBar), behind a confirmation dialog.
3. M6.5 quantity-discount promo — **not** folded into Project totals in v1; plain original-vs-current strikethrough only.
4. Project → Cart conversion — in scope (reversed from an earlier "out of scope" call), built as "Add All to Cart".
5. Icon glyph — non-blocking; shipped as `Icons.folder_special_outlined` / `Icons.folder_special`.
6. Event date / client name / phone / notes — added to schema, creation flow stays name-only (speed), full field set editable later via `[Edit]`.

## 4. Verification Done

- `deno check supabase/functions/api/index.ts` — clean.
- `dart run build_runner build --delete-conflicting-outputs` — clean, Drift v6 codegen regenerated successfully (173 outputs written).
- `flutter analyze` — 0 errors, 0 warnings in touched files (only the same category of pre-existing style `info` lints already present elsewhere in the codebase).
- `flutter test` — passing.

**Not done this session:**
- **Migration not applied** — `supabase db query -f "../migrations/027_AP_create_projects.sql" --linked` failed with a `403` (CLI account lacks privileges on `bpmtnsaebrnuoujwxfea`). See manual steps doc.
- **Edge Function not redeployed** — blocked on the same permissions gap; `/v1/projects/*` will 404 until `supabase functions deploy api` runs successfully.
- **No live device/browser testing** — couldn't reach a live backend this session to exercise the flow end-to-end.

## 5. Known Gaps / Deliberate Non-Scope

- **No badge count on the top-bar Projects icon.** The plan flagged this as optional ("cheap to add"); it wasn't actually cheap without a dedicated project-count fetch (the flattened variantId set doesn't give a project count), so it was left out rather than adding an extra request for a nice-to-have. Easy follow-up if wanted.
- **Multi-user sharing, PDF export** — explicitly out of scope per the plan (§11).
- **Wishlist heart's real position vs. `Milestone 6.5.md`'s claim** — see the note at the end of §1. Not a Projects bug, but worth a separate look.
