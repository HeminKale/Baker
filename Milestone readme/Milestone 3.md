# Milestone 3 — Buy Products (Cart & Payments)

Status: **code complete, not yet deployed.** Same delivery model as Milestones 1 & 2 — everything below was built and verified locally (`deno check`, `flutter analyze`, `flutter test`, `dart run build_runner build`) without a live Supabase project or Razorpay keys. It needs the steps in `Milestone 3 manual steps.md` before it runs end-to-end. Plan file used to build it: `C:\Users\hemin\.claude\plans\we-are-planning-to-immutable-newt.md`.

Milestone 3 replaces Milestone 2's in-memory cart stub with a real server-synced, Drift-backed cart, and adds the full checkout → discount → address → Razorpay payment → order-confirmation flow.

## 1. What Was Built

Built in three sub-phases (backend → Flutter cart → Flutter checkout).

**Database** (`migrations/014-021`):
- `carts`, `cart_items` (with `UNIQUE(cart_id, variant_id)` so add-to-cart is a safe upsert), `discounts`, `product_discounts`, `orders` (status CHECK + `razorpay_payment_id UNIQUE`), `order_items`, `webhook_events` — schema matches `00_common_architecture.md` §4.
- `021_seed_discount_bake10.sql` — seeds one demo code, **BAKE10** (10% off), so the discount flow is demoable before the Phase 6 admin panel exists.

**Backend** (`baker_ally_backend/`, Hono on Supabase Edge Functions):
- `db/schema.ts` — 7 new Drizzle tables.
- `lib/razorpay.ts` — lazy Razorpay client + HMAC payment/webhook signature verification (Deno `node:crypto`, timing-safe compare).
- `lib/discountEngine.ts` — shared discount validate/calculate logic, reused by both the validate endpoint and checkout so the client's numbers are never trusted.
- `routes/cart.ts` — `GET /v1/cart`, `POST/PATCH/DELETE /v1/cart/items`, `DELETE /v1/cart`, `POST /v1/cart/merge`, `GET /v1/checkout/recommendations`.
- `routes/discounts.ts` — `POST /v1/discounts/validate` (public).
- `routes/checkout.ts` — `POST /v1/cart/checkout` (re-validates prices + stock, creates the pending order + Razorpay order) and `POST /v1/orders/:id/confirm` (verifies signature, decrements stock, confirms, clears cart — all in one DB transaction).
- `routes/webhooks.ts` — `POST /v1/webhooks/razorpay` (raw-body HMAC, dedup via `webhook_events`, `payment.failed` → cancel).
- `routes/addresses.ts` — `GET`/`POST /v1/addresses` (list + add only; see §2).
- All 5 registered in `index.ts`.

**Flutter** (`baker_ally_flutter/`):
- `shared/local_db/app_database.dart` — Drift schema bumped to **v3**, adds `CachedCartItems` + `CachedAddresses` (additive `onUpgrade`, so existing Milestone 1/2 installs migrate automatically).
- `features/cart/` — `CartItem` model, `CartRepository` (optimistic Drift write + background server sync + revert-on-failure, mirroring `WishlistRepository`), `CartNotifier`/`cartProvider` (seeds from Drift, refreshes from server when logged in, merges the guest cart on login, resets on logout).
- `features/checkout/` — `Address` + `DiscountResult` models, `AddressRepository` + `CheckoutRepository` (typed `PriceChangedException` / `OutOfStockException` / `DiscountInvalidException`), `checkout_providers.dart` (selected address/payment, applied discount, live `billSummaryProvider`, recommendations, status machine), the `CheckoutScreen` (renders `/cart`, owns the Razorpay instance), `OrderConfirmationScreen`, and the address-selector + payment-mode bottom sheets + `CartItemRow`.
- Router (`core/router/app_router.dart`) — `/cart` now renders `CheckoutScreen`; `/checkout/confirmation` added as a sibling in the same Cart branch (bottom nav stays visible).

## 2. Scope Decisions (locked with you before/while building — don't re-litigate without asking)

- **7 new tables, not the 9 in the kickoff prompt.** `shipments` and `notifications` are Phase 4 scope (their only producers — Shiprocket, WhatsApp, FCM — don't exist until then), per `Phase_Plan_Technical.md`. You confirmed deferring them.
- **Flat delivery fee = ₹49 (4900 paise), hardcoded placeholder.** See §3 — this is the one genuinely pending item.
- **Demo discount `BAKE10` (10% off) is seeded** so the discount flow demos without the admin panel.
- **Addresses: list + add only this milestone.** Enough to unblock checkout. `PATCH`/`DELETE` and the full "Delivery Addresses" management screen stay Phase 5.

## 3. ⚠️ PENDING / Open Items

1. **Flat shipping fee is a placeholder (₹49).** The real free-shipping threshold / weight-based cost depends on the **Porter integration**, which is an explicit open business decision (`00_common_architecture.md` §17, open decision A — "before Milestone 4"). It's defined in **two places that MUST stay in sync**:
   - Backend: `FLAT_SHIPPING_PAISE = 4900` in `baker_ally_backend/supabase/functions/api/routes/checkout.ts`
   - Flutter: `kFlatShippingPaise = 4900` in `baker_ally_flutter/lib/features/checkout/presentation/providers/checkout_providers.dart`
   - If these ever disagree, `POST /cart/checkout` returns `PRICE_CHANGED` and checkout can't proceed. When the real shipping rule is decided, update both (or, better, have the server return the shipping cost and the client stop computing it — a small future refactor).
2. **Razorpay is test-mode only.** Live keys are a Phase 7 swap (risk register). No real money moves this milestone.
3. **No live end-to-end run** — same as Milestones 1 & 2, no Supabase/Razorpay credentials in this session. Verified by `deno check`, `flutter analyze`, `flutter test`, `build_runner` only.
4. **Order history / tracking is Phase 4.** The confirmation screen shows the order ID + total + a static "estimated delivery" line and a WhatsApp note, but there is no "Track Order" button yet (no order-detail screen or Shiprocket status until Phase 4). "Continue Shopping" is the only CTA.
5. **`payment.success` is confirmed client-side, not by webhook.** The Razorpay webhook only handles `payment.failed` → cancel. Success goes through the client-driven `POST /orders/:id/confirm` (the standard Razorpay pattern). Both paths are idempotent.

## 4. Deviations From the Plan / Docs (all deliberate, noted here)

- **Cart provider swap done by direct wiring, not the "facade" the plan sketched.** The plan proposed keeping `localCartStubProvider` as a thin mirror over the new `cartProvider`. Since the add path already had to change (it needs `productId`/`productName`/`imageUrl` to build a real `CartItem`, which the old `add(variantId, maxQty)` didn't carry), the widgets (`product_tile.dart`, `product_detail_screen.dart`, `app_shell.dart`) were already being edited — so `localCartStubProvider` was **removed** and those widgets now read `cartProvider` directly via `quantityOf(variantId)` / `.decrement()` / `totalItems`, and the shared add helper was widened + renamed `addToCartStub` → `addToCart`. Cleaner than a zombie facade with duplicated state; the AnimatedSwitcher button↔stepper interaction itself is unchanged.
- **`CartState` is minimal (items, totalItems, subtotal).** The doc's §12 `CartState` also listed `discountValue`/`shippingCost`/`total`/`discountCode`/`discount`. Those are checkout-screen concerns and live in `checkout_providers.dart`'s `billSummaryProvider` / `appliedDiscountProvider` instead, so the cart badge/tiles don't rebuild on discount changes. Same information, cleaner separation.
- **`/cart` is no longer a protected route.** It was hardcoded in `_protectedPaths` in Milestone 2, which contradicted the guest-cart spec (`05_cart_and_checkout.md` §2/§3 — guests can view the cart and add items; only **Proceed** requires login). `_protectedPaths` is now empty; the login gate lives on the checkout Proceed action via the existing `showLoginRequiredSheet`.
- **No separate `/checkout` route.** Per `05_cart_and_checkout.md` §3, the Cart tab IS the checkout page, so `/cart` renders `CheckoutScreen` directly. Only `/checkout/confirmation` is its own route.
- **Price re-validation uses `expectedTotal`, not a stored cart-price snapshot.** `cart_items` has no price column by design, so `POST /cart/checkout` takes the total the client is displaying, recomputes independently from live DB prices, and returns `409 PRICE_CHANGED` with the corrected breakdown on any mismatch.
- **No `Idempotency-Key` header.** `00_common_architecture.md` §16 mentions one, but `razorpay_payment_id UNIQUE` + the `status='pending'` guard on confirm already make retries safe, and no header-idempotency machinery exists anywhere in the codebase. Skipped as unnecessary.

## 5. Post-Build Verification Pass (bugs found & fixed)

A verification pass after the initial build — checked against `Phase_Plan_Technical.md` Phase 3, `05_cart_and_checkout.md`, and the plan file — found **3 real bugs, all fixed** (same practice as Milestone 2's validation pass). None were caught by `flutter analyze`/`flutter test`; they're logic bugs that only a spec cross-read surfaces:

1. **Stale discount → `PRICE_CHANGED` loop.** `billSummaryProvider` used the discount amount frozen at validate-time. If the cart changed after applying a percent code, the client total no longer matched the server's recompute at `POST /cart/checkout`, and the `PRICE_CHANGED` recovery (`cartProvider.refresh()`) didn't re-validate the discount — so Proceed looped on `PRICE_CHANGED` forever. **Fix:** `billSummaryProvider` now recomputes the discount from `type`+`value` against the live subtotal, mirroring the server's `discountEngine.ts` arithmetic exactly, so it always matches.
2. **Cold-start cart doubling.** On app restart as a returning logged-in user, Drift holds their previously-synced server cart (each item has a `serverId`). The auth listener fired `_onLogin`, which merged **all** local items back into the server cart via `POST /cart/merge` — doubling every quantity on each cold start. **Fix:** `_onLogin` now merges only genuine guest items (`serverId == null`); already-synced items just trigger a plain `GET /cart`.
3. **Guest couldn't reach the login gate.** The checkout Proceed button was disabled when no address was selected, but a guest has no address (addresses require auth), so a guest could never tap Proceed to get the login sheet — contradicting `05_cart_and_checkout.md` §2/§3. **Fix:** Proceed is disabled only while busy; `_placeOrder` gates login → address → pay in order (guest → login sheet, logged-in-no-address → address sheet).

Re-verified after the fixes: `flutter analyze` (no errors/warnings), `flutter test` (passing), `deno check` (exit 0).

**Minor, left as-is (noted, not a bug):** for `POST /v1/cart/checkout`, `authMiddleware` runs twice — once from `cart.ts`'s `/cart*` guard and once from `checkout.ts`'s own `/cart/checkout` guard (two separate route files both matching the path). It's one extra auth round-trip, harmless and idempotent; kept so `checkout.ts` stays self-protecting rather than depending on `cart.ts`'s middleware.

## 6. Acceptance Criteria (from `Phase_Plan_Technical.md` Phase 3)

- [x] Guest can add items, log in, and see items merged into the cart — `POST /v1/cart/merge` on the login transition (`CartNotifier._onLogin`).
- [x] Qty stepper animates correctly — qty 0 reverts to Add button (unchanged from Milestone 2; now backed by the real cart).
- [x] Server-side price re-validation catches changed prices before payment opens — `expectedTotal` check → `409 PRICE_CHANGED`.
- [x] Razorpay payment sheet opens with the correct amount — `razorpay_flutter`, opened from `CheckoutScreen`. **Code complete; not device-tested (needs test keys).**
- [x] Successful payment creates a `confirmed` order — `POST /orders/:id/confirm`.
- [x] `razorpay_payment_id` UNIQUE rejects duplicate confirmations — plus an idempotent same-payment-id early return.
- [x] `stock_qty` decrements atomically on confirmation (same tx as the status update) — conditional `UPDATE ... WHERE stock_qty >= qty`; zero rows ⇒ rollback. Two concurrent last-unit checkouts can't both succeed.
- [x] Webhook dedup prevents double-processing — `webhook_events(source, event_id)` UNIQUE.
- [x] Discount code applies correctly — bill updates live via `billSummaryProvider`.
- [x] Cart cleared after a successful order — server-cleared inside the confirm transaction + `cartProvider.clearAfterOrder()`.

Boxes are checked for "code complete + locally verified." The three that need a live deployment + Razorpay test keys to actually observe (payment sheet, real decrement under concurrency, webhook replay) are called out in §3 and in the manual-steps doc.

## 7. Known Gaps / Deliberate Non-Scope

- **No live end-to-end run** (no credentials this session).
- **Shipping cost is a placeholder** (§3.1).
- **Order history, tracking, WhatsApp, push, Shiprocket** — all Phase 4.
- **Address edit/delete + management screen** — Phase 5.
- **`product_discounts` table is built but unused by checkout** — Milestone 3 checkout only applies code-based discounts (`discounts.code`); product-scoped auto-discounts are for the Phase 6 admin panel.

See `Milestone 3 manual steps.md` for exactly what to run before this is live.
