# Milestone 8 — Catalog Tile Redesign, Notify Me, Reviews & Ratings

> Plan files: `Planning docs/Architecture/02_catalog_tab.md` §5a and §4,
> `Planning docs/Architecture/00_common_architecture.md` §5a and §12a.
> Built 2026-09-22. Closes out the three items `02_catalog_tab.md` had flagged
> as pending.

Status: **code complete, not yet fully live.** The tile redesign and Notify Me button are pure Flutter changes and work as soon as the app is rebuilt — no backend dependency. Reviews & Ratings needs its migration applied and the Edge Function redeployed, which hit the same Supabase CLI `403` that blocked Milestone 7 — see `Milestone 8 manual steps.md`.

## 1. Product Tile Redesign (`02_catalog_tab.md` §5a)

`ProductTile` (`baker_ally_flutter/lib/features/catalog/presentation/widgets/product_tile.dart`) no longer wraps in a `Card` — the image is `ClipRRect`-rounded on its own, and the name/variant/price text below it renders directly on the screen's background with no fill panel. The full-width "Add to Cart" button is gone; in its place, a small floating "+" (`_CircleAddButton`) sits in the image's bottom-right corner via the same `Stack`/`Positioned` mechanism already used for the badge row and wishlist heart on the other two corners. Tapping it swaps to a compact "− N +" pill (`_StepperPill`) via the same `AnimatedSwitcher` transition the old button used — purely a visual relocation, `addToCart()`'s stock-cap/"Max stock reached" logic is untouched. Out-of-stock tiles leave that corner empty; the existing "Out of Stock" badge (top-left) already carries the signal, per the plan's own documented option.

This is the shared `ProductTile` widget, so the change applies everywhere it's reused — Level 2 grid, Home rows, Order Again, Wishlist, product detail's "You Might Also Like" — in one place.

## 2. "Notify Me" Button (`02_catalog_tab.md` §4)

The old disabled "Out of Stock" button on the product detail page's Fixed Bottom CTA is now a functional `_NotifyMeButton` (`product_detail_screen.dart`). **No email provider was needed.** Milestone 6 already built the actual notify mechanism — wishlisting an out-of-stock variant is the notify-me request (`wishlists.last_notified_at`), and `migrations/024_AP_restock_notify_trigger.sql`'s Postgres trigger already pushes an FCM notification via `routes/internal.ts`'s `notify-restock` when stock crosses 0 → positive. `02_catalog_tab.md` had cited "blocked on choosing an email provider," which described a different, older design (`00_common_architecture.md` §12a) that was never built and has now been marked superseded in that doc. The new button is just a differently-labelled front end onto the same `wishlistIdsProvider.toggle()` the heart icon already uses — filled/outline state and login-gating included.

## 3. Reviews & Ratings (`00_common_architecture.md` §5a)

Full feature, new `features/reviews/` Flutter module + new backend route.

**Database** (`migrations/028_AP_create_product_reviews.sql`, not yet applied live):
- `product_reviews` — `product_id`, `user_id`, `order_item_id` (FK to the specific delivered purchase that proves eligibility), `overall_rating` (required, 1-5), 4 optional 1-5 sub-ratings (`quality`/`value`/`packaging`/`accuracy`), `comment`, `tags TEXT[]`, `created_at`, `UNIQUE(user_id, product_id)`.

**Backend** (`baker_ally_backend/supabase/functions/api/`):
- `db/schema.ts` — `productReviews` Drizzle table.
- `routes/reviews.ts` (new) — mixed public/authed under one path prefix, so auth middleware is applied per-route rather than blanket `.use()`:
  - `GET /v1/products/:id/reviews?page=&limit=` — public. Returns `{ summary: { overallRating, reviewCount, categoryAverages }, reviews: [...] }`. Averages computed live via `AVG()`, not precomputed, matching the plan's stated tradeoff (low expected review volume).
  - `GET /v1/products/:id/reviews/eligibility` — authed. `{ canReview, reason? }` where `reason` is `not_purchased` | `not_delivered` | `already_reviewed`.
  - `POST /v1/products/:id/reviews` — authed. **One deviation from the plan:** the request body does not include a client-supplied `orderItemId`. Since eligibility is entirely server-computed anyway (the plan's own words: "backend re-verifies eligibility server-side, never trusts the client"), the server resolves the caller's eligible `order_item` itself (`findEligibleOrderItem` — most recent `delivered` order containing this product, joined through `order_items.variant_id → product_variants.product_id` since `order_items` has no direct `product_id` column) rather than trusting a client-supplied id for a FK it doesn't otherwise validate.
- `index.ts` — `reviewsRoute` mounted at `/v1`.

**Flutter** (`baker_ally_flutter/lib/features/reviews/` — new module):
- Models: `Review`, `ReviewSummary`, `CategoryAverages`, `ReviewEligibility`. `Review.authorLabel` formats a full name as "Priya S." (first name + last-initial), falling back to "Customer" if unset.
- `ReviewRepository` — thin Dio wrapper, no Drift caching (reviews are product-detail-only, same "not cached" precedent as product detail itself).
- `review_providers.dart` — `productReviewsProvider` and `reviewEligibilityProvider`, both `FutureProvider.autoDispose.family` so a freshly-submitted review isn't served stale.
- Widgets: `StarDisplay`/`StarPicker` (read-only vs interactive 1-5 stars, the picker supports fractional averages via half-star icons), `RatingRings` (the 4 category rings), `ReviewCard` (horizontal-scroll card, avatar-initial circle, relative timestamp, tag chips), `AddReviewSheet` (bottom sheet: overall stars required, 4 optional category stars, comment, quick-select tag chips from a fixed suggested list), `ReviewsSection` (composes all of the above — this is what's mounted on the page).
- `product_detail_screen.dart` — `ReviewsSection` inserted directly below `_RelatedProducts` ("You Might Also Like"), matching the plan's layout. The "Add Review" button only renders for a logged-in user whose `reviewEligibilityProvider` returns `canReview: true` — hidden entirely otherwise (guests, ineligible users, and already-reviewed users all just don't see it, rather than showing a disabled button with an explanation).

**Not built this milestone** (kept out of scope, consistent with the plan's own framing of `productReviewsProvider` as "first page"): a dedicated "See all reviews" full list/pagination screen. `ReviewsSection` shows the first page (10 reviews) in the horizontal-scroll card row per the mockup; paging further wasn't specified beyond that and would be a natural small follow-up.

## 4. Doc Updates

- `02_catalog_tab.md` — all three "not yet built" callouts replaced with "✅ Built in Milestone 8" notes (tile redesign banner, Notify Me paragraph, Reviews & Ratings section, §9's three review endpoint rows, §10's Riverpod comment). Top "Last updated" line bumped.
- `00_common_architecture.md` — §5a's "not built yet" banner replaced with a built note (plus the `orderItemId` deviation called out). §12a is marked **superseded** rather than deleted — kept as a historical record of the email-based design that was never built, with a note pointing at what actually shipped (wishlist + FCM push, no email provider). §17 "Still Open" row C (email provider) marked resolved-as-moot, since the feature it was blocking took a different, already-built path; Resend for Auth OTP emails is called out as a separate, already-resolved decision so the two don't get conflated.

## 5. Verification Done

- `deno check supabase/functions/api/index.ts` — clean.
- `flutter analyze` — 0 errors, 0 warnings across the whole project (only the same category of pre-existing style `info` lints already present elsewhere).
- `flutter test` — passing.
- No `build_runner` regeneration needed — Reviews has no Drift table (network-only), and the tile/Notify Me changes don't touch the local DB schema.

**Not done this session:**
- **Migration 028 not applied** — same `403 LegacyDbConfigLoginRoleStatusError` that blocked Milestone 7's migration 027 (CLI account lacks privileges on `bpmtnsaebrnuoujwxfea`). **Migration 027 is also still pending** from Milestone 7 — both need to be applied, in order, next time someone with real access runs the manual steps.
- **Edge Function not redeployed** — blocked on the same permissions gap; `/v1/products/:id/reviews*` will 404 until `supabase functions deploy api` runs successfully (this same deploy also finally picks up Milestone 7's `routes/projects.ts`, still pending from last time).
- **No live device/browser testing** — couldn't reach a live backend this session.

## 6. Known Gaps / Deliberate Non-Scope

- **No "See all reviews" screen** — see §3 above.
- **Review author names are shown as first-name + last-initial** ("Priya S.") — a reasonable privacy default not explicitly specified in the plan; flag if you want full names or a different anonymization scheme instead.
- **`00_common_architecture.md` §12a's email design is superseded, not deleted** — kept in the doc as a record of the rejected approach rather than removed outright, consistent with how this repo's docs tend to keep decisions traceable.
