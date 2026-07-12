# Milestone 2 — Browse the Catalog

Status: **deployed and running live.** Built and verified locally first (`deno check`, `flutter analyze`, `flutter test`, `dart run build_runner build`), then deployed by the user to a live Supabase project (`bpmtnsaebrnuoujwxfea`) and tested on an Android emulator/device per `Milestone 2 manual steps.md`. Two post-deploy layout bugs (bottom-row overflow on the product tile, missing cart-count badge) were found during live testing and fixed in the same branch — see §6.

## 1. Scope Decisions

Three decisions were made explicitly before building, since the friend's brief (20-30 products/category) didn't match what's practical to hand-author in one pass:

- **Add to Cart is a local-only stub.** Cart itself is Milestone 3. The button/stepper UI (idle → stepper → out-of-stock, `AnimatedSwitcher` 150ms) works exactly per spec, backed by an in-memory Riverpod notifier (`localCartStubProvider`, `lib/features/catalog/presentation/providers/catalog_providers.dart`) rather than a server cart. It does **not** persist across app restarts. Milestone 3 replaces the notifier's internals with the real server-synced `cartProvider` without touching any widget code, since the shape (`Map<variantId, quantity>`) is the same either way.
- **Seed images are deterministic placeholders.** Every category/subcategory/product image is a `picsum.photos/seed/<slug>/400` URL — a real, loadable image for testing `cached_network_image`, the manual shimmer placeholder, and the product gallery, without needing real product photography yet.
- **Seed volume is lean, not the literal 20-30/category from the brief.** See §2 below for exactly what's dummy and how to grow it.

## 2. Dummy / Placeholder Data — Full List

Everything a real admin would eventually replace, in one place:

| What | Where | Detail |
|---|---|---|
| **Categories** (6) | `migrations/013_seed_catalog.sql` | Real names from the locked list in `00_common_architecture.md` §5 (Ingredients, Packaging, Tools & Equipment, Cake Decorations, Seasonal & New Collections, Bakeware) — names are correct/final, but every category's `image_url` is a placeholder. |
| **Sub-categories** (27) | same file | Same deal — names are the locked final list, images are placeholders. |
| **Products** (~104) | same file | **Fictional.** Plausible bakery-supply product names/descriptions I authored (e.g. "Fresh Cream 25% Fat", "Round Cake Mould"), not real Baker Ally SKUs or copy. 4 per subcategory, except **Packaging → Festive Packaging**, which is deliberately left at 0 products to exercise the "Coming soon" empty state. |
| **Variants** (~310) | same file | Names (e.g. "500ml", "Pack of 25") are realistic size/pack patterns per product type, not sourced from a real price list. |
| **SKUs** | same file | Generated as `<IMAGE-SEED-SLUG>-<VARIANT-INDEX>` (e.g. `PROD-FRESHCREAM-1`) purely to satisfy the `UNIQUE` constraint — **not real SKU codes**, don't reuse this format for actual inventory. |
| **Prices** (`original_price`, `current_price`) | same file | Estimated INR figures I picked to look plausible (paise). Not real pricing. |
| **Stock quantities** | same file | Procedurally assigned by row index (40 = normal, 3 = low stock, 0 = out of stock on the smallest variant of every 7th product) — not real inventory counts. |
| **`is_trending` / "New" recency** | same file | Every 5th product flagged trending; every 9th backdated to 3 days old (so it reads as "New"), the rest backdated 200 days. Synthetic, purely to exercise every badge — not a real trending signal. |
| **Product images (2 per product)** | same file | `picsum.photos` placeholder photos — literally random stock photography, not pictures of the actual products. |
| **Product descriptions** | same file | One-line descriptions I wrote to sound plausible, not real marketing copy. |

**Nothing in Flutter or the backend is hardcoded to this dummy data** — it's all read from the DB through the same endpoints real data would use. Deleting and re-seeding the tables is enough to replace it.

**How to go from lean to full volume (or to real data) later:**
1. Write another seed SQL file in the same shape as `migrations/013_seed_catalog.sql` (the `_seed_products` temp-table + `DO`-block pattern) and run it.
2. Once the Milestone 6 admin panel ships, add real products through its UI instead of SQL.

Either way, no app or schema changes are needed — see `Planning docs/Architecture/02_catalog_tab.md`'s "Key Rules": *"No hardcoded categories in Flutter — all driven from DB."*

## 3. What Was Built

**Database** (`migrations/007-013`):
- `categories`, `sub_categories`, `products` (with a generated `search_vector tsvector` column + GIN index for full-text search), `product_variants`, `product_images`, `wishlists` — schema matches `00_common_architecture.md` §4 and §19's required indexes.
- `013_seed_catalog.sql` — the dummy seed described in §2, procedurally expanded via a PL/pgSQL `DO` block rather than ~104 hand-written product blocks.

**Backend** (`baker_ally_backend/`):
- `db/schema.ts` — Drizzle tables for all 6 new tables.
- `routes/catalog.ts` — public (no auth) routes: `GET /v1/categories`, `GET /v1/categories/:id/subcategories`, `GET /v1/products` (branches on `categoryId` / `subCategoryId` / `q`, each product row carries its "display" variant + image so tiles render without N+1 calls), `GET /v1/products/:id`, `GET /v1/products/:id/related`. Rate-limited via the existing `middleware/rateLimit.ts`.
- `routes/wishlist.ts` — behind `authMiddleware`: `GET /v1/wishlist`, `POST /v1/wishlist`, `DELETE /v1/wishlist/:variantId`.

**Flutter** (`baker_ally_flutter/`):
- `shared/local_db/app_database.dart` — Drift schema bumped to v2 (`CachedCategories`, `CachedSubCategories`, `CachedProducts` — denormalized with the display variant/image embedded directly, `CachedWishlistItems`), with a proper `MigrationStrategy.onUpgrade` since v1 already shipped in Milestone 1.
- `features/catalog/` — models, `CatalogRepository` (network-first with Drift fallback on list endpoints; product detail is network-only, never cached, per `00_common_architecture.md` §15), Riverpod providers per `02_catalog_tab.md` §10, plus `relatedProductsProvider`, `searchProvider` (plain-`Timer` debounce, no new package), and `localCartStubProvider`.
- `features/catalog/presentation/screens/` — `CatalogScreen` (Level 1), `SubcategoryProductsScreen` (Level 2: left subcategory strip + product grid, bidirectional scroll-spy via `GlobalKey` render-box positions), `ProductDetailScreen` (Level 3: gallery, variant chips, pricing, description, related products, fixed CTA).
- `features/wishlist/` — `WishlistRepository` + `WishlistNotifier`, optimistic add/remove against Drift + background Dio call; `WishlistHeart` widget on product detail, login-gated via a new shared `showLoginRequiredSheet` (reusable by Cart's guest-checkout flow in Milestone 3).
- Router (`core/router/app_router.dart`) — `/catalog`, `/catalog/:categoryId/:subId`, `/product/:productId` all wired inside the existing Catalog `StatefulShellBranch` so the bottom nav stays visible.

## 4. Validation Against the Spec

Two validation passes were done after the initial build, checked against `Phase_Plan_Technical.md`, the approved plan (`C:\Users\hemin\.claude\plans\federated-seeking-piglet.md`), and every file in `Planning docs/Architecture/` (`00_common_architecture.md`, `02_catalog_tab.md`, `03_order_again_tab.md`, `05_cart_and_checkout.md`, `06_profile_and_account.md`).

**Two real bugs found and fixed:**
- `CatalogFilter.inStockOnly` defaulted to `true`, silently hiding out-of-stock products by default — contradicts the explicit "not hidden" Key Rule in `02_catalog_tab.md` §5/§8. Fixed: now defaults to `false`.
- The Add to Cart stepper (`localCartStubProvider`) had no ceiling — tapping `+` could increment past `stock_qty` indefinitely, contradicting `05_cart_and_checkout.md` §1: *"Tap + beyond stock_qty → + button disabled, shows 'Max stock reached' tooltip."* Fixed: `LocalCartStubNotifier.add()` now takes `maxQty`, refuses to increment past it, and both call sites (catalog tile, product detail CTA) show a "Max stock reached" snackbar when capped.

**Similarities found (forward-compatible design confirmed, not built yet but ready):**
- `05_cart_and_checkout.md` §1's exact add-to-cart tile interaction (button → stepper, `AnimatedSwitcher` 150ms, qty 0 reverts) is what `ProductTile` implements — Milestone 3's real cart can reuse the same widget.
- `06_profile_and_account.md`'s wishlist section expects `GET /v1/wishlist` and `DELETE /v1/wishlist/:variantId` — exactly what was built; the future Phase 5 wishlist screen can consume it directly.
- `03_order_again_tab.md` says "Previously Bought" tiles must be "the same catalog product tile" — `ProductTile` takes a generic `Product` model, so Phase 5 can reuse it as-is.

**Deviations (acceptable, documented):**
- Full-text search covers `name + description` only, not `+ sub_categories.name` as the prose in `Phase_Plan_Technical.md` §2.2 mentions (the architecture doc's own SQL snippet in §21 only covers name+description too — the two docs disagree with each other; the SQL snippet was followed).
- The global search icon (spec: "on all pages except Home") only exists on the Catalog tab — Home/Order Again/Brownie Points/Cart are still Milestone 1 placeholder screens, so there was nothing to add it to yet.
- Level 2's left strip is a fixed 44px width, not literally "5%" of screen width as worded in `02_catalog_tab.md` §3.

**Planning doc gap found and fixed (not a Milestone 2 code issue — a spec gap):** neither `Phase_Plan_Technical.md` Phase 3 nor `00_common_architecture.md` §9's order lifecycle mentioned decrementing `product_variants.stock_qty` on order confirmation — only a one-line risk-register mitigation note existed, with no actual task or acceptance criterion assigned to it. Both docs updated (see `Phase_Plan_Technical.md` Phase 3.3 + Acceptance Criteria, and `00_common_architecture.md` §9) so stock decrement is now an explicit, spec'd requirement for Milestone 3's `POST /v1/orders/:id/confirm`, done atomically in the same DB transaction as the status update.

## 5. Acceptance Criteria (from `Phase_Plan_Technical.md`)

- [x] All 6 categories + subcategories render from DB — no hardcoded values in Flutter
- [x] Left strip ↔ product grid scroll-spy sync works in both directions — code complete, not device-tested
- [x] Product tile badges render correctly based on DB flags
- [x] Variant selection updates price, stock status, and Add button correctly
- [ ] Search returns relevant results within 800ms (p99) — code complete; **cannot verify the latency target without a live deployment to load-test**
- [ ] Voice search — **out of scope**, deferred to Phase 5 per the Milestone 1 update in `Phase_Plan_Technical.md` (Kotlin 2.0 incompatibility)
- [x] Catalog data served from Drift cache when offline — "Last updated X hours ago" shown if stale
- [x] Product images load via `cached_network_image` with a shimmer placeholder (manual implementation, no `shimmer` package)

## 6. Live Testing — Bugs Found & Fixed

After the user deployed to a live Supabase project and ran the app on an emulator/device, live testing surfaced two layout bugs not caught by `flutter analyze`/`flutter test` (neither renders a real device screen):

- **Bottom-row overflow on the product tile** (`RenderFlex overflowed`, later a residual 2.3px clip) — the tile's `childAspectRatio` (0.62 → tried 0.52 → settled at 0.45 across `catalog_screen.dart`, `subcategory_products_screen.dart`, and the "You Might Also Like" row in `product_detail_screen.dart`) didn't leave enough vertical room for name + variant + price + Add-to-Cart button. Fixed by giving tiles more height and shrinking the Add to Cart button/stepper to a compact style (smaller padding, `minimumSize`, 32px icon buttons). Root cause of the *symptom* ("Add to Cart button invisible"): `Card(clipBehavior: Clip.antiAlias)` was silently clipping the overflowing button rather than erroring, which is why it disappeared instead of showing the red overflow banner once wrapped in `Flexible`.
- **No cart-count badge** — the bottom nav's Cart icon had no numeral overlay, contradicting the "Cart 🔴" badge shown in `02_catalog_tab.md`'s mockups. Added a red count badge on `AppShell`'s cart `NavigationDestination`, driven by `localCartStubProvider`'s total quantity.

## 7. Known Gaps / Deliberate Non-Scope

- **Cart is a local, in-memory stub** — resets on app restart. Acceptable for this milestone since Cart itself (persistence, server sync, guest-cart merge) is Milestone 3's job. The cart-count badge added in §6 reads this stub, so it will reset too until Milestone 3 lands.
- **Search p99 latency (800ms target)** and **scroll-spy performance** are both code-complete and now running against the live catalog, but not load-tested — both are explicitly Phase 7 hardening tasks (k6 load test, profile-mode scroll testing) in `Phase_Plan_Technical.md`.
- **Wishlist grid screen** is not built — only the heart toggle (DB + API + optimistic Drift cache), per the Phase 2 vs. Phase 5 split in the technical plan.
- **Voice search** stays deferred to Phase 5 (carried over from the Milestone 1 Kotlin 2.0 incompatibility note).
- **Email OTP** works today (Supabase free tier, no Pro required) but is rate-limited; **Phone/SMS OTP** stays deferred — blocked on a third-party SMS provider account (Twilio/MessageBird/etc.), not a Supabase plan tier.

See `Milestone 2 manual steps.md` for the deployment steps already carried out, and `00_common_architecture.md` §17 for cross-cutting open decisions (Porter, Brownie Points, email provider) that don't block this milestone but are tracked there.
