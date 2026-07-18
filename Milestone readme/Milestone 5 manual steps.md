# Milestone 5 — Manual Setup & Deployment Steps

**Status:** Code is complete. These are the manual, non-automated steps to deploy Milestone 5 live, on top of everything in `Milestone 1/2/3 manual steps.md`.

**Time Required:** ~10–15 minutes (no new external accounts — just two Supabase Storage buckets).
**Prerequisites:** Milestones 1–3 already deployed. **Zero new DB migrations this milestone** — every table read/written (`users`, `addresses`, `wishlists`, `orders`, `order_items`) already exists.

---

## Phase A: Supabase Storage — Create the New Buckets

Milestone 5 needs two new Storage buckets that don't exist yet. Both are created the same way Milestone 1's `product-images` bucket was.

### Step A.1: Create the `avatars` bucket (public)

**Where:** Supabase Dashboard → Storage → New bucket.

- Name: `avatars`
- Public bucket: **Yes** (avatar images are shown via a public URL in `CachedNetworkImage`, same as product images)

**Policies** (SQL Editor, or Storage → Policies UI). Uploads go to a flat path `{userId}.webp` — no subfolder — so ownership is checked against the exact filename:

```sql
create policy "Avatar images are publicly readable"
on storage.objects for select
using (bucket_id = 'avatars');

create policy "Users can upload their own avatar"
on storage.objects for insert
to authenticated
with check (bucket_id = 'avatars' and name = auth.uid()::text || '.webp');

create policy "Users can replace their own avatar"
on storage.objects for update
to authenticated
using (bucket_id = 'avatars' and name = auth.uid()::text || '.webp');
```

`uploadBinary(..., fileOptions: FileOptions(upsert: true))` in `user_repository.dart` needs both the insert and update policies since upsert can resolve to either.

### Step A.2: Create the `invoices` bucket (private)

**Where:** Supabase Dashboard → Storage → New bucket.

- Name: `invoices`
- Public bucket: **No**

**Policies:** none needed. Invoice PDFs are only ever written and read via `routes/orders.ts`'s `supabaseAdmin` client (`lib/supabaseAdmin.ts`, service-role key), which bypasses Storage RLS entirely. Clients only ever see a short-lived signed URL (`GET /v1/orders/:id/invoice`, 10-minute expiry) — never the bucket directly. Leaving this bucket policy-free means a regular user JWT has **zero** direct access, which is the intended behavior.

**Verify:**
```sql
select id, public from storage.buckets where id in ('avatars', 'invoices');
-- avatars  | true
-- invoices | false
```

---

## Phase B: Backend — Redeploy the Edge Function

**What:** Ships `routes/orders.ts`, `routes/order-again.ts`, the extended `routes/addresses.ts`/`routes/cart.ts`/`routes/users.ts`, and `lib/invoice.ts`. `deno.json` now depends on `pdf-lib@^1.17.1` (fetched automatically on deploy).

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project
supabase functions deploy api
```

**Verify** (replace `<ref>` and use a real logged-in JWT):
```bash
# authed — empty/seeded order list for a user
curl "https://<ref>.supabase.co/functions/v1/api/v1/orders" -H "Authorization: Bearer <JWT>"
# → {"data":[...],"meta":{"page":1,"limit":50,"total":N}}

# authed — invoice for a confirmed order (first call generates + caches the PDF)
curl "https://<ref>.supabase.co/functions/v1/api/v1/orders/<orderId>/invoice" -H "Authorization: Bearer <JWT>"
# → {"data":{"url":"https://...signed..."}}
```
If the invoice call 500s, confirm the `invoices` bucket exists (Phase A.2) — `generateInvoicePdf` runs fine locally, but the `bucket.upload(...)` call fails if the bucket is missing.

---

## Phase C: Flutter — Rebuild

**What:** Picks up the Drift v3→v4 migration (`CachedOrders` table) and the new account/discovery features. `image_picker` and `url_launcher` are new pubspec deps.

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**⚠️ Upgrading from a Milestone 3 install:** Drift runs its v3→v4 `onUpgrade` automatically on first launch (adds `CachedOrders`) — no uninstall needed.

---

## Phase D: End-to-End Test (the real acceptance check)

1. **Profile & avatar:** Tap the avatar in the top bar → Profile Overlay opens (profile card + 8-item menu + Log Out). Tap **Edit →** → change Full Name/Business Name/GSTIN → **Save Changes** → overlay reflects the update. Tap the avatar circle → pick a photo → it uploads and the top bar avatar updates immediately.
2. **Addresses CRUD:** Profile Overlay → **Delivery Addresses**. Add a new address, edit an existing one, delete one, and tap **Set as Default** on a non-default one — confirm only one address ever shows the "Default" badge.
3. **Wishlist:** Heart a couple of products from product detail, then Profile Overlay → **Your Wishlist** → grid shows them; tapping the heart on a tile removes it immediately.
4. **Orders:** Profile Overlay → **Your Orders** → list of past orders (needs at least one confirmed order from Milestone 3 testing). Tap one → detail screen shows items, bill breakdown, and delivery address. Profile Overlay → **Order Status** → same list, filtered to active orders only.
5. **Receipts:** Profile Overlay → **Receipts & Invoices** → paid orders list. Tap **Download** on one → opens the invoice PDF externally (first tap generates it server-side; a second tap for the same order should be near-instant since it's cached).
6. **Order Again:** Bottom nav → **Order Again** tab.
   - As a guest (logged out): shows a "Log in to see items you've ordered before" prompt, not the tab content.
   - Logged in with 2+ multi-item orders sharing the same variants: a "Frequently Bought Together" group appears — tap it, adjust per-item quantities/uncheck items, tap **Add Selected Items to Cart** → items land in the cart in one call.
   - "Previously Bought" lists distinct variants from past orders, most recent first; tapping **+** adds one to the cart. If there are 20+ distinct variants, a **Load More** button appears.
7. **Static pages:** Profile Overlay → **Recipes** (static list), **Contact Us** (WhatsApp/email/hours), **Help & Support** (FAQ accordion + "Raise a ticket" → opens Contact Us).
8. **Log Out:** Profile Overlay → **Log Out** → confirm dialog → lands on `/login` with Drift cache and JWT cleared (Order Again's guest prompt should show if you navigate to that tab afterward).

---

## Phase E: Verification Checklist

### Backend
- [ ] `PATCH /v1/addresses/:id` updates fields and correctly reassigns default
- [ ] `DELETE /v1/addresses/:id` promotes the next-most-recent address to default if the deleted one was default
- [ ] `GET /v1/orders` paginates and supports `status=active` / `paid=true`
- [ ] `GET /v1/orders/:id` returns items + address, 404s for another user's order
- [ ] `GET /v1/orders/:id/invoice` generates on first call, re-signs (near-instant) on repeat calls
- [ ] `GET /v1/order-again/frequently-bought` only returns combos ordered 2+ times, capped at 10
- [ ] `GET /v1/order-again/previously-bought` paginates, most recently ordered first
- [ ] `POST /v1/cart/items/batch` adds/clamps to stock and silently skips unknown/inactive variants

### Flutter
- [ ] Top bar shows the default address label + avatar (or a login icon for guests)
- [ ] Profile Overlay's 8 menu items all navigate correctly; Log Out clears Drift + JWT + Supabase session
- [ ] Avatar upload updates both the Edit Profile screen and the top bar immediately
- [ ] Addresses list/add/edit/delete all work; default-address invariant holds
- [ ] Wishlist grid empty state ("No saved items yet") shows correctly for a wishlist-less account
- [ ] Order history/detail/receipts render correctly offline for the cached page-1 "Your Orders" view (airplane mode after one successful load)
- [ ] Order Again shows the guest prompt when logged out, real data when logged in
- [ ] `flutter analyze` and `flutter test` both clean

---

## Troubleshooting

**"Avatar upload succeeds but the image never shows."**
Confirm the `avatars` bucket is **public** (Phase A.1) — `getPublicUrl()` only resolves to a servable URL on a public bucket.

**"Avatar upload fails with a 403/RLS error."**
The insert/update policy compares `name` to `auth.uid()::text || '.webp'` exactly — confirm the Flutter upload path is still `'$userId.webp'` (no folder prefix) and that `userId` is the Supabase Auth user id, not some other id.

**"Invoice download 500s or times out."**
Confirm the `invoices` bucket exists (Phase A.2) and that the Edge Function has been redeployed since this milestone's code landed (Phase B) — `generateInvoicePdf` and the `pdf-lib` import are new.

**"Order Again's Frequently Bought Together section never shows anything."**
It requires at least two *separate* orders containing the *exact same set* of 2+ variants (not just any two orders) — see `routes/order-again.ts`'s grouping logic. Single-item orders and one-off combos don't qualify by design.

**"App crashes on first launch after updating from Milestone 3."**
Drift v3→v4 migration issue. As a dev-only last resort (wipes local cache, not server data), uninstall + reinstall the app.

---

## Known Deviations From the Architecture Docs (intentional, not bugs)

- **Address form has no Full Name / Phone fields**, even though `06_profile_and_account.md`'s mockup shows them. The `addresses` table has no such columns (those live on `users`, edited via `/profile/edit`), and adding them would need a new migration — which this milestone explicitly locks at zero. The form matches the real `PATCH/POST /addresses` contract instead: label, line1, line2, city, state, pincode, default toggle.
- **Wishlist grid uses a custom tile, not a reused `ProductTile`.** `GET /wishlist` doesn't return the fields `ProductTile`/`ProductVariant` require (`sku`, `subCategoryId`, `isTrending`, `createdAt`), so a literal reuse would need fabricated placeholder values. The custom tile renders exactly what the endpoint actually returns.
- **Previously Bought pagination is a "Load More" button**, not true infinite scroll — functionally paginated (satisfies the Phase 6 checkpoint) without adding a second pagination state machine on top of the existing `FutureProvider`.
- ~~Order Again uses vertical lists~~ — **superseded 2026-07-12.** After seeing the reference mockup, Order Again was reworked to match it: Frequently Bought Together is a horizontal scroll of fixed-width cards with a one-tap "Add All to Cart" (adds every item at qty 1 via the batch endpoint), and Previously Bought is a 2-column grid, both per `Phase_Plan_Technical.md` §5.4 / `Phase_Plan_Business.md`'s mockup. Tapping a Frequently Bought card body (not the button) still opens the per-item stepper sheet for selective add.

---

## Next Steps After Verification

1. **Commit the code:**
   ```bash
   git add -A
   git commit -m "Milestone 5 complete: Account & Discovery"
   git push
   ```
2. **Milestone 4** (Orders & Fulfillment — Shiprocket, shipments, FCM push) remains deferred pending the Porter-vs-Shiprocket delivery decision, per the context that kicked off this milestone. Order Status/Order Detail will pick up carrier/AWB display once `shipments` exists.
