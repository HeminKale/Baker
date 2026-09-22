# Milestone 6.5 — Manual Setup & Deployment Steps

**Status:** Backend + admin panel are already live (migration applied, Edge Function redeployed, admin panel typechecked). Flutter changes are code-complete but never run on a device this session.

**Time Required:** ~10 minutes. **No new accounts, secrets, or Storage buckets** — this feature reuses the existing `discounts`/`product_discounts` tables and the already-deployed backend/admin infrastructure. The only real step is rebuilding the Flutter app and testing the flow live.

**Prerequisites:** Milestone 6 already deployed (admin panel running, at least one admin user exists).

---

## Phase A: Backend — Already Done, Verify Only

These ran during the build. Confirm rather than repeat:

```sql
SELECT threshold_qty, message_template FROM discounts LIMIT 1;  -- columns should exist, no error
SELECT info_message FROM products LIMIT 1;                       -- column should exist, no error
```
```bash
curl "https://bpmtnsaebrnuoujwxfea.supabase.co/functions/v1/api/v1/health"
# → {"data":{"status":"ok"}}
```

## Phase B: Admin Panel

If you're running `baker_ally_admin` locally (`npm run dev`), just restart it to pick up the new files — no config changes needed. If it's deployed to Vercel already, the next push/redeploy picks this up automatically (same Root Directory / env vars as before, nothing new to set).

## Phase C: Flutter — Rebuild

**What:** Picks up the Drift v5→v6 migration (3 new nullable columns on `CachedCartItems`) and the new widgets.

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
flutter pub get
flutter run
```

**⚠️ Upgrading from a pre-6.5 install:** Drift runs its v5→v6 `onUpgrade` automatically on first launch (adds 3 nullable columns, additive only) — no uninstall needed.

## Phase D: End-to-End Test (the real acceptance check)

1. **Set up a test promo:** Admin panel → open any product → edit a variant → set Threshold Qty = `3`, Discount Amount = `10` → Save. Leave the message template at its default.
2. **Product detail:** Open that product in the app, select the configured variant. Tap **Add to Cart** once → a banner should appear: *"Add 2 more to get ₹10 off"* with a progress bar. Tap **+** twice more → banner flips to a success/celebration state.
3. **Wishlist + info icon:** Confirm the heart icon now sits on the top-right of the product image (not next to the name). If you set `infoMessage` on that product (via the admin panel's product edit form), the 'i' icon should appear where the heart used to be — tap it to confirm the bottom sheet shows your bullet points.
4. **Cart sync:** Go to the Cart tab → confirm a "Quantity discount − ₹10" line appears in Bill Details and the total reflects it.
5. **Multiple discounts stacking (optional but worth doing):** Configure a second variant with its own threshold/amount, add enough of both to cart, confirm the bill's single "Quantity discount" line shows the **combined** total (e.g. ₹10 + ₹20 = ₹30), not just one of them.
6. **Checkout:** Proceed through checkout with Razorpay test mode → confirm the order goes through at the discounted total, no unexpected `PRICE_CHANGED` error.
7. **Stock-limited edge case:** Set a variant's stock below its threshold (e.g. threshold 3, stock 2) → confirm the banner never appears for that variant, since the promo is unreachable.
8. **Guest/offline (optional):** Add a discount-eligible quantity while logged out, force-close and reopen the app → confirm the banner/cart bill still shows the discount from the local Drift cache.

## Phase E: Verification Checklist

- [ ] Admin can set/edit/remove a variant's quantity discount from the product page
- [ ] Quantity-discount rows do **not** appear on the general Discounts admin page
- [ ] Progress banner appears only after the first unit is added, updates live, flips to success at threshold
- [ ] Wishlist heart is on the image; info icon (if bullets are set) is in its old spot
- [ ] Cart bill shows the discount and totals correctly, including when multiple items each qualify
- [ ] Checkout completes at the discounted total without a `PRICE_CHANGED` error
- [ ] Banner is hidden when stock is below the threshold

---

## Troubleshooting

**"Banner never shows up even after adding items."**
Confirm the variant actually has a quantity discount saved (admin panel → edit that variant → the Threshold Qty / Discount Amount fields should be pre-filled). If blank, it was never saved — re-check for a toast error when you last saved the dialog.

**"Cart total doesn't match what product detail showed."**
This would trigger `PRICE_CHANGED` at checkout as a safety net — it shouldn't happen since both screens use the same underlying config and the same live-cart-quantity math, but if it does, it's the one thing worth reporting back with repro steps.

**"Quantity discount row shows up on the general Discounts page."**
Shouldn't happen — `admin-discounts.ts`'s list filters `type != 'quantity'`. If you see one, the Edge Function may need a fresh deploy (`supabase functions deploy api` from `baker_ally_backend/`).

---

## Next Steps After Verification

```bash
git add -A
git commit -m "Milestone 6.5: quantity-discount promo + product info sheet"
git push
```
No further milestone is queued after this — next up is whatever you decide from `Milestone readme/18 July pending steps.md` (Firebase push setup, Sentry, dev store accounts, etc.) or Milestone 7 (Launch Ready).
