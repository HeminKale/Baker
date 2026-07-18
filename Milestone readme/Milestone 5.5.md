# Milestone 5.5 — Home Tab

Status: **code complete, backend deployed.** Added after Milestone 5 as a small addendum — see `Planning docs/Architecture/01_home_tab.md` for the full design this was built from, and `Planning docs/Phase_Plan_Business.md` / `Phase_Plan_Technical.md` for the Milestone 5.5 / Phase 5.5 entries added alongside it.

Milestone 5.5 replaces the Home tab's `PlaceholderScreen` with a real discovery page: an always-visible search bar and three horizontal product sections (Newly Launched, New Offers, Trending Now), each with a paginated "See all" screen.

## 1. What Was Built

**Backend** (`baker_ally_backend/`):
- `routes/home.ts` (new) — `GET /v1/home` (top-10 preview of all three sections) and three paginated section endpoints: `GET /v1/home/newly-launched`, `GET /v1/home/new-offers`, `GET /v1/home/trending`. Public, no `authMiddleware`, same as `catalog.ts`.
- Newly Launched and Trending reuse `attachDisplayInfo()` (exported from `catalog.ts`) verbatim — same batch-join, N+1-safe pattern already established in Milestone 2.
- New Offers is queried variant-first, not via `attachDisplayInfo()` — see §5 below, this was the one real bug caught during planning.
- `index.ts` — registered `homeRoute`.
- **Zero new Postgres migrations.** Reuses `products` / `productVariants` / `productImages` as-is.

**Flutter** (`baker_ally_flutter/`):
- `shared/local_db/app_database.dart` — Drift schema bumped **v4 → v5**, adds `CachedHomeSections` (additive `onUpgrade`, existing installs migrate automatically). Regenerated via `dart run build_runner build --delete-conflicting-outputs`.
- `features/home/` — `HomeSections` model, `HomeRepository` (network-first + Drift fallback for the preview, network-only pagination for "See all"), `homeSectionsProvider` / `homeSectionPageProvider`, `HomeScreen`, `HomeSectionScreen`.
- `shared/widgets/search_results_grid.dart` (new) — extracted from Catalog's previously-private `_CatalogSearchResults` so Home's always-visible search bar and Catalog's icon-toggled search share one implementation instead of two copies. `catalog_screen.dart` now imports and uses it too.
- Router (`core/router/app_router.dart`) — `/` now renders `HomeScreen` (was `PlaceholderScreen(title: 'Home')`); added `/home/section/:slug` as a sibling inside the Home branch (bottom nav stays visible, same treatment as Catalog's Level 2/3 routes).
- `shared/widgets/app_shell.dart` — the top bar's default-address label is now tappable, opening the existing `AddressSelectorSheet` (built for checkout in Milestone 3), reused as-is. See §4 for the scope note on what this does and doesn't wire up.

No new tile widget, no new search implementation, no new cart logic — `ProductTile`, `cartProvider`, `searchProvider`, and `AddressSelectorSheet` are all reused exactly as they were.

## 2. Scope Decisions (locked with you before/while building)

- **Notification bell excluded.** The reference mockup shows one, but there's no `notifications` table or Dio-polling infra (`00_common_architecture.md` §12) — building it now means building that whole unscoped feature. Top bar stays address + avatar only.
- **Voice search deferred again.** `speech_to_text` was already pulled from the project in Milestone 1 over a Kotlin 2.0 build incompatibility and explicitly flagged "deferred to Phase 5" for re-evaluation. The call here was to defer once more rather than re-litigate a native build-tooling issue mid-milestone — the search bar works text-only with no functional gap, just no mic icon.
- **Workmanager background refresh not built.** Same Kotlin 2.0 deferral. Home's Drift fallback is read-through only (refreshes on next successful network call), not proactively synced in the background — matches Catalog's existing behaviour.
- **A section with zero qualifying products is hidden, not shown empty.** Matches Order Again's existing "hide, don't apologize" convention for sparse sections.

## 3. Section Definitions

| Section | Definition | Sort |
|---|---|---|
| Newly Launched | Active products, most recent first | `createdAt DESC` |
| New Offers | Active products with ≥1 active variant where `currentPrice < originalPrice` | Discount % `DESC` |
| Trending Now | Active products with `isTrending = true` | `createdAt DESC` |

Preview (`GET /v1/home`) returns top 10 per section. "See all" (`GET /v1/home/:slug?page&limit`) is fully paginated, default `limit=20`, max `50`.

## 4. Address Label — What It Does and Doesn't Do

Tapping the top bar's address label opens `AddressSelectorSheet`, and picking an address there writes to `selectedAddressProvider`. That provider is checkout-scoped state (it decides what checkout defaults to) — the label now prefers showing that selection when one exists, falling back to the account's default/first address otherwise. This is **not** a fully wired global address switcher (matches the "best-effort" scope note already in `app_shell.dart` from Milestone 5) — there's no server-side "currently active address" concept, it's local UI state that resets on app restart.

## 5. Bugs Found & Fixed During Testing

**Backend — Multiple Variants Per Product in New Offers:**
`getNewOffers()` queried variant-first to avoid `attachDisplayInfo()`'s lowest-sortOrder picker bug (see below), but when a product had multiple discounted variants, it returned the product once per variant. The Drift cache's primary key `(section, productId)` only allows one row per product per section, causing a UNIQUE constraint violation on INSERT.

Fixed by deduplicating on the backend: keeping only the highest-discount variant per product (first in the `ORDER BY discount % DESC` result set), then filtering duplicates before returning. The best-discount variant was already sorted first by the query; the filter just removes subsequent occurrences of the same `productId`. See `routes/home.ts`'s `getNewOffers()` deduplication logic.

**Frontend — Product Tile Overflow on Long Names:**
When product names wrapped to 2+ lines, the tile content (name + variant + price + button) exceeded the card's height, causing a "bottom overflowed by 8 pixels" layout warning. The tile's inner Column used `mainAxisSize: MainAxisSize.min`, which didn't leave enough breathing room.

Fixed by reducing spacer heights from 4px to 2px (total 4px reduction per tile, eliminating the 8px overflow). See `product_tile.dart` lines 73, 75.

**Original Design Bug (Not Code) — attachDisplayInfo() for New Offers:**
`attachDisplayInfo()` (used by Newly Launched and Trending) always picks each product's *lowest-sortOrder active variant* as the display variant. That's correct when any variant is representative of the product, but it's **wrong for New Offers**: a product can have variant A (sortOrder 0, full price) and variant B (sortOrder 1, discounted). The product qualifies for New Offers because variant B exists, but `attachDisplayInfo()` would still attach variant A — the tile would render in the "New Offers" section at full, non-discounted price.

Fixed by querying `productVariants` directly (not product-first) for New Offers: `WHERE currentPrice < originalPrice AND variant.isActive AND product.isActive`, ordered by discount percentage descending, then attaching *that exact variant* as the display variant — bypassing `attachDisplayInfo()`'s generic picker entirely for this one endpoint.

## 6. Drift Caching — Why a New Table, Not a Reused One

Reusing `CachedProducts` for Home's offline cache was considered and rejected. That table's primary key is `{id}` (one row per real product), and its `categoryId` column holds the product's *genuine* category — used by Catalog's own offline fallback query. Tagging rows with a synthetic `categoryId: 'home:trending'` to scope them for Home would silently overwrite that real category value the next time the same product got cached from an actual Catalog browse (or vice versa) — a correctness bug in the *existing* Catalog offline fallback, not just a Home concern.

`CachedHomeSections` is a new table instead, keyed by `(section, productId)` so the same product can appear in multiple sections without collision. Schema bump v4 → v5, same additive-migration mechanics as `CachedOrders` in Milestone 5.

## 7. Verification

- `deno check supabase/functions/api/index.ts` — exit 0
- `flutter analyze` — 0 errors (38 pre-existing style infos, unrelated to this work)
- `flutter test` — all tests passing
- `dart run build_runner build --delete-conflicting-outputs` — Drift codegen regenerated cleanly for `CachedHomeSections`
- `supabase functions deploy api` — deployed successfully to project `bpmtnsaebrnuoujwxfea`

No live end-to-end run yet — same caveat as every other milestone in this project, verified by static checks + generated code, not a live device session against seeded data.

## 8. Deviations From the Plan (all deliberate)

- **`search_results_grid.dart` extraction wasn't in the original plan doc**, which only said Home would "reuse the same provider and results grid." Since Catalog's version was a private, unexported class, reuse required either duplicating ~30 lines or extracting a shared widget. Extracted, since it's now used identically (same layout, same provider) in two places — this is reuse, not premature abstraction.
- **The address-label tap wiring (§4) went slightly further than the plan's one-line mention** ("adds a tap handler that opens the existing AddressSelectorSheet") — the label itself now also reads `selectedAddressProvider` so a pick is actually visible, not just a sheet that opens and does nothing observable from the tab bar.
