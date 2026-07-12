# Milestone 3 — Manual Setup & Deployment Steps

**Status:** Code is complete. These are the manual, non-automated steps to deploy Milestone 3 live, on top of everything in `Milestone 1 manual steps.md` and `Milestone 2 manual steps.md`.

**Time Required:** ~20–30 minutes (one new account: a **Razorpay test account** — free).
**Prerequisites:** Milestones 1 & 2 already deployed (migrations 001–013 run, Edge Function deployed, `.env`/secrets set, Flutter app runs and shows the catalog).

---

## Phase A: Database — Run the Cart & Payment Migrations

### Step A.1: Run Migrations 014–021

**What:** Creates `carts`, `cart_items`, `discounts`, `product_discounts`, `orders`, `order_items`, `webhook_events`, and seeds the `BAKE10` demo discount.

**Where:** `C:\Users\hemin\OneDrive\Desktop\Android Project\migrations\`

**Files to run (in order):**
```
014_create_carts.sql
015_create_cart_items.sql
016_create_discounts.sql
017_create_product_discounts.sql
018_create_orders.sql
019_create_order_items.sql
020_create_webhook_events.sql
021_seed_discount_bake10.sql
```

**How:** Supabase Dashboard → SQL Editor → paste each file's contents → **Run**, in order. (Or `supabase db push` if you track them via the CLI.)

**Verify:**
```sql
SELECT count(*) FROM discounts WHERE code = 'BAKE10';   -- 1
SELECT table_name FROM information_schema.tables
  WHERE table_name IN ('carts','cart_items','discounts','orders','order_items','webhook_events');  -- 6 rows
```

`021_seed_discount_bake10.sql` uses `ON CONFLICT (code) DO NOTHING`, so re-running it is safe.

---

## Phase B: Razorpay — Create a Test Account & Keys

### Step B.1: Get test API keys

1. Sign up / log in at <https://dashboard.razorpay.com>.
2. Switch the dashboard to **Test Mode** (toggle, top-left).
3. **Settings → API Keys → Generate Test Key**.
4. Copy the **Key Id** (`rzp_test_...`) and **Key Secret** (shown once — save it).

### Step B.2: Configure the webhook

1. Razorpay Dashboard (Test Mode) → **Settings → Webhooks → Add New Webhook**.
2. **Webhook URL:**
   ```
   https://<your-project-ref>.supabase.co/functions/v1/api/v1/webhooks/razorpay
   ```
3. **Secret:** enter any strong random string — you'll set the same value as `RAZORPAY_WEBHOOK_SECRET` below.
4. **Active events:** tick at least `payment.failed` (and `payment.captured` if you want the record; only `payment.failed` is acted on this milestone).
5. Save.

### Step B.3: Set the Edge Function secrets

Same mechanism as the existing `UPSTASH_*` / `SENTRY_DSN` secrets:
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project
supabase secrets set RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx
supabase secrets set RAZORPAY_KEY_SECRET=your_test_key_secret
supabase secrets set RAZORPAY_WEBHOOK_SECRET=the_same_secret_you_entered_in_B.2
```
Verify: `supabase secrets list` should show all three names (values are hidden).

---

## Phase C: Backend — Redeploy the Edge Function

**What:** Ships the five new route files + the Razorpay lib. `deno.json` now depends on `razorpay@^2.9.0` (fetched automatically on deploy).

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project
supabase functions deploy api
```

**Verify** (replace `<ref>` and use a real logged-in JWT for the authed calls):
```bash
# public — should return the seeded discount
curl -X POST "https://<ref>.supabase.co/functions/v1/api/v1/discounts/validate" \
  -H "Content-Type: application/json" -d '{"code":"BAKE10","cartTotal":100000}'
# → {"data":{"code":"BAKE10","type":"percent","value":10,"discountValue":10000,"freeShipping":false}}

# authed — empty cart for a fresh user
curl "https://<ref>.supabase.co/functions/v1/api/v1/cart" -H "Authorization: Bearer <JWT>"
# → {"data":{"items":[]}}
```
If `/discounts/validate` errors with a 500, confirm migrations 014–021 ran. If `/cart/checkout` later errors about Razorpay, confirm the Phase B secrets are set.

---

## Phase D: Flutter — Rebuild

**What:** Picks up the Drift v3 tables (cart + address cache) and the new cart/checkout features. `razorpay_flutter` is already in `pubspec.yaml` (added in Milestone 1), so no `pub get` change is required beyond the usual.

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**⚠️ Upgrading from a Milestone 2 install:** Drift runs its v2→v3 `onUpgrade` automatically on first launch (adds the two new cache tables) — no uninstall needed.

### Android note for Razorpay
`razorpay_flutter` needs `minSdkVersion >= 19` (already satisfied) and internet permission (already present). If the Razorpay sheet fails to open on a physical device, confirm the device has a network connection and that Play Services is available — test payments still need the Razorpay app/UPI apps or card entry.

---

## Phase E: End-to-End Test (the real acceptance check)

1. **Guest cart:** Without logging in, add items from the catalog. Confirm (via a network inspector) that **no `/v1/cart/*` calls fire** while logged out — the cart lives only in Drift. Kill and reopen the app; the cart should still be there.
2. **Merge on login:** Log in (Google or Email OTP). `POST /v1/cart/merge` should fire once; `GET /v1/cart` should reflect the merged items.
3. **Checkout page:** Tap the **Cart** tab → the full checkout page renders (items with steppers, "You Might Also Like", bill details, cancellation policy, fixed bottom CTA).
4. **Discount:** Enter `BAKE10` → Apply → the bill shows a −10% discount line and the total drops. Remove → it reverts.
5. **Address:** Tap **Add** on the CTA bar → add an address (first one auto-becomes default and is preselected).
6. **Payment:** Tap the payment label → pick UPI → Proceed. The Razorpay **test** sheet opens with the correct amount.
7. **Pay (test):** Use a Razorpay [test payment method](https://razorpay.com/docs/payments/payments/test-card-details/) (e.g. test card `4111 1111 1111 1111`, any future expiry/CVV; or test UPI `success@razorpay`).
8. **Confirmation:** Order flips to `confirmed` in the DB, `stock_qty` decrements by the ordered amount, the cart clears (Drift + server), and the confirmation screen shows the order ID + total.
9. **Idempotency / safety (optional, worth doing):**
   - `SELECT status, razorpay_payment_id FROM orders ORDER BY created_at DESC LIMIT 1;` → `confirmed`, payment id set.
   - Re-POST the same `/orders/:id/confirm` body → returns the same `confirmed` result, **no second stock decrement**.
   - Trigger a failed test payment (test card `4000 0000 0000 0002`) → the `payment.failed` webhook marks that pending order `cancelled`.

---

## Phase F: Verification Checklist

### Backend
- [ ] `POST /v1/discounts/validate {code:BAKE10}` returns a 10% discount
- [ ] `GET /v1/cart` (authed) returns `{items:[]}` for a new user; reflects adds
- [ ] `POST /v1/cart/items` adds/increments and caps at `stock_qty`
- [ ] `POST /v1/cart/checkout` returns `{orderId, razorpayOrderId, amount, keyId}`; `409 PRICE_CHANGED` if `expectedTotal` is wrong
- [ ] `POST /v1/orders/:id/confirm` with a valid signature confirms + decrements stock
- [ ] Re-confirming the same order is a no-op (no double decrement)
- [ ] `payment.failed` webhook cancels the pending order; a replayed webhook is deduped

### Flutter
- [ ] Guest cart persists across app restart, no server calls while logged out
- [ ] Cart merges on login
- [ ] Cart badge on the bottom nav reflects the live item count
- [ ] Discount `BAKE10` applies and the bill updates live
- [ ] Checkout requires an address; first address auto-defaults
- [ ] Razorpay test sheet opens; a successful test payment reaches the confirmation screen
- [ ] Cart is empty after a confirmed order

---

## Troubleshooting

**"Checkout fails immediately with PRICE_CHANGED and the total looks right."**
The flat shipping constant is defined in two files that must match: `FLAT_SHIPPING_PAISE` (backend `routes/checkout.ts`) and `kFlatShippingPaise` (Flutter `checkout_providers.dart`). Both are `4900`. If you changed one, change the other. See `Milestone 3.md` §3.1.

**"Razorpay order creation fails (500 on `/cart/checkout`)."**
The `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` secrets aren't set or are wrong — re-check Phase B.3 (`supabase secrets list`) and redeploy.

**"Webhook returns 400 INVALID_SIGNATURE."**
`RAZORPAY_WEBHOOK_SECRET` must exactly equal the secret you entered in the Razorpay webhook config (Phase B.2). Re-set it and redeploy.

**"App crashes on first launch after updating from Milestone 2."**
Drift v2→v3 migration issue. As a dev-only last resort (wipes local cache, not server data), uninstall + reinstall the app.

---

## Next Steps After Verification

1. **Commit the code:**
   ```bash
   git add -A
   git commit -m "Milestone 3 complete: Cart & Payments"
   git push
   ```
2. **Begin Milestone 4** (Orders & Fulfillment): Shiprocket + Interakt WhatsApp + FCM push, driven by the `order_events` pgmq queue. The `orders`/`order_items`/`webhook_events` tables it builds on already exist from this milestone; `shipments` and `notifications` are Milestone 4's to create.
