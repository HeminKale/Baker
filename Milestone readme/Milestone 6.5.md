# Milestone 6.5 — Quantity-Discount Promo + Product Info Sheet

> Ships outside the milestone sequence — a small, self-contained addition built on top of Milestone 6, same treatment as `Milestone 5.5.md` and `Voice Search.md`. Built 2026-07-19. Plan file: `C:\Users\hemin\.claude\plans\transient-forging-cookie.md`.

Status: **code complete and deployed live.** Backend + admin panel changes are live (migration applied, Edge Function redeployed, admin panel typechecked). Flutter changes are code-complete and verified via `flutter analyze`/`flutter test`/`build_runner`, not yet run on a live device this session.

On the product detail screen, customers now see a live progress nudge after adding at least one unit of a variant: "Add 3 more to get ₹10 off," with a progress bar that updates in real time as cart quantity changes, flipping to a success state once the threshold is met. It's a real discount, not cosmetic — it applies in the cart bill and at checkout. The threshold, discount amount, and message wording are all admin-configurable per variant. Separately, the wishlist heart moved from next to the product name onto the product image's top-right corner (matching catalog tiles), and its old spot now hosts an 'i' icon that opens admin-authored bullet-point product info.

## 1. What Was Built

**Key reuse finding**: `product_discounts` — a table built in Milestone 3 (`017_create_product_discounts.sql`) "so the Phase 6 admin panel can scope discounts" — had sat completely unused ever since. This feature is what finally wires it up, rather than adding a new table.

**Database** (`migrations/026_AP_quantity_discounts_and_product_info.sql`):
- `discounts.type` check constraint extended to include `'quantity'`.
- `discounts.threshold_qty` (integer, nullable) and `discounts.message_template` (text, nullable) — new columns, only meaningful for `type='quantity'` rows. The existing `value` column (paise) is reused for the flat discount amount.
- Unique partial index on `product_discounts.variant_id` — single-tier only, one active quantity discount per variant.
- `products.info_message` (text, nullable) — admin-authored bullet points, newline-separated.

**Backend** (`baker_ally_backend/`):
- `lib/discountEngine.ts` — `computeQuantityDiscountValue()` (pure, single-tier: awards the flat amount once at the threshold, doesn't scale with multiples) and `getQuantityDiscountsForVariants()` (batch-fetch, same shape as `catalog.ts`'s `attachDisplayInfo`), shared by every route below so there's exactly one source of truth.
- `routes/catalog.ts` — `GET /v1/products/:id` now returns each variant's `quantityDiscount` config and the product's `infoMessage`.
- `routes/cart.ts` — `loadCartItems` (used by every cart endpoint) now returns each line's raw `quantityDiscount` config, mirroring how code-based discounts are already client-computed rather than server-precomputed.
- `routes/checkout.ts` — `POST /cart/checkout`'s price re-validation sums quantity discounts across lines and folds them into the combined `discountValue` stored on the order, alongside the code-based discount. `orders.discountId` stays scoped to the code discount only (quantity discounts are per-line/plural).
- `routes/admin-catalog.ts` — `PUT`/`DELETE /admin/variants/:id/quantity-discount` (upsert/remove, same dedicated-endpoint precedent as `PATCH .../stock`), `infoMessage` added to the product create/update schema, `GET /admin/products/:id` returns each variant's config for free.
- `routes/admin-discounts.ts` — the general Discounts list now filters out `type='quantity'` rows so they don't pollute the code-based-discount admin page.

**Admin panel** (`baker_ally_admin/`):
- `lib/types.ts` — `QuantityDiscountConfig` on `ProductVariant`, `infoMessage` on `Product`.
- `product-info-form.tsx` — new Textarea for info bullets, same pattern as the existing description field.
- `variants-section.tsx`'s `VariantDialog` — new "Quantity discount (optional)" sub-section (threshold, amount, message template), shown only when editing an existing variant (a brand-new variant has no id yet to attach the config to). Saves independently after the main variant PUT succeeds, same pattern as the cross-sell section's independent calls.

**Flutter** (`baker_ally_flutter/`):
- Models (`ProductVariant`, `ProductDetail`, `CartItem`) extended with the new fields; `ProductDetail.infoBullets` splits `infoMessage` on newlines.
- Drift `CachedCartItems` gains 3 nullable columns (schema v5 → v6, additive `onUpgrade`) — the quantity-discount config is denormalized onto the cart item at add-to-cart time, same as price, so guest/offline carts still compute the discount correctly without a network round trip.
- `cartProvider`'s `addItem()` threads the config through; `CartState.quantityDiscountTotal` sums it live across all lines.
- `billSummaryProvider` extended with the same client-mirrors-server technique already used for code discounts — recomputes live from cart state, server re-validates independently at checkout with the existing `409 PRICE_CHANGED` safety net as backstop.
- New widgets: `QuantityPromoBanner` (progress message + bar, watches the same `cartProvider.select(quantityOf(variantId))` the Add-to-Cart button already watches) and `ProductInfoSheet` (bottom sheet listing bullets).
- `product_detail_screen.dart` — wishlist heart moved onto the image gallery's top-right corner (mirrors `product_tile.dart`'s existing positioning), info icon added in its old spot (hidden when no info bullets exist), promo banner inserted below the price block.

## 2. How Sync Is Guaranteed (the original design question)

This was the core requirement going in: the "2" in "Add 2 more" must never go stale. The answer is that nothing is ever stored as a rendered string — the message is a pure computed value from `(admin config, fetched once) × (live cart quantity, from the provider the Add-to-Cart button already watches)`. On the cart/checkout page, the same technique already proven for code-based discounts (client recomputes live, server re-validates and 409s on any mismatch) was extended rather than inventing a new mechanism.

## 3. Scope Decisions (confirmed with you during planning)

1. **Message wording uses `{remaining}`/`{amount}` placeholders**, not a fully fixed sentence or fully free (non-dynamic) text — admin controls the wording, the numbers are always live-substituted.
2. **Single-tier only** — one threshold, one flat ₹ amount, awarded once. Buying 6 of a "buy 3, get ₹10 off" variant doesn't give ₹20 off.
3. **Info-bullet message is product-level**, not per-variant — matches how `description` already works.
4. **Banner appears only after the first unit is added to cart**, not as a pre-add teaser, matching the literal request ("on click of add to cart").
5. **Stock-limited variants hide the banner entirely** — if `stockQty < thresholdQty`, the promo is mathematically unreachable, so it's not shown.

## 4. Verification Done

- `deno check supabase/functions/api/index.ts` — clean.
- Migration 026 applied and verified live (all 4 new columns/index confirmed via direct query).
- `supabase functions deploy api` — deployed; `/v1/health` and admin-route 401 gating both curl-verified post-deploy.
- `npx tsc --noEmit` on `baker_ally_admin` — clean.
- `flutter analyze` — 0 errors (39 pre-existing baseline info lints, none in touched files).
- `flutter test` — passing.
- `dart run build_runner build --delete-conflicting-outputs` — clean, Drift v6 codegen regenerated successfully.

**Not done this session**: live on-device testing of the full flow (admin sets a promo → customer sees the banner → cart/checkout reflects the discount → order confirms with the right total). No browser/device automation was available; static verification only, same caveat as most milestones in this project.

## 5. Known Gaps / Deliberate Non-Scope

- **`startsAt`/`expiresAt` on quantity-discount rows** are honored on the read side (the config won't apply outside the window) but not exposed in the admin sub-form yet — a promo is either on (`isActive`) or off, not time-boxed, from the UI. The columns are there for a future addition.
- **Order history loses the code-vs-quantity discount split post-purchase** — both are combined into `orders.discountValue`, a deliberate tradeoff to avoid a new `orders` column for a live-checkout-only distinction.
- **No pre-add-to-cart teaser.** A customer who never taps "+" doesn't see the promo exists. Matches the literal request; a small always-visible badge near the price block would be a natural follow-up if you want more upfront visibility.
- **No live device test yet** — see §4.
