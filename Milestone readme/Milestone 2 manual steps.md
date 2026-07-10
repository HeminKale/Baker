# Milestone 2 — Manual Setup & Deployment Steps

**Status:** Code is complete. These are the manual, non-automated steps you must run to deploy Milestone 2 live, on top of everything already done in `Milestone 1 manual steps.md`.

**Time Required:** ~10-15 minutes (no new accounts/credentials needed — reuses the same Supabase project and Edge Function from Milestone 1)
**Prerequisites:** Milestone 1's manual steps already completed (migrations 001-006 run, backend deployed at least once, `.env` filled in)

---

## Phase A: Database — Run the Catalog Migrations

### Step A.1: Run Migrations 007-013

**What:** Creates `categories`, `sub_categories`, `products`, `product_variants`, `product_images`, `wishlists`, and seeds them with dummy data (see `Milestone 2.md` §2 for exactly what's dummy).

**Where:** `C:\Users\hemin\OneDrive\Desktop\Android Project\migrations\`

**Files to run (in order):**
```
007_create_categories.sql
008_create_sub_categories.sql
009_create_products.sql
010_create_product_variants.sql
011_create_product_images.sql
012_create_wishlists.sql
013_seed_catalog.sql
```

**How to run:**

Option 1 — **Supabase Dashboard SQL Editor:**
1. Go to your Supabase project → SQL Editor
2. Copy contents of `007_create_categories.sql` → paste → **Run**
3. Repeat for 008 → 013 in order
4. `013_seed_catalog.sql` takes a few seconds longer than the others (it's a PL/pgSQL loop inserting ~104 products + ~310 variants + ~210 images) — wait for the success message before moving on.

Option 2 — **Supabase CLI:**
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project
supabase link --project-ref <your-project-ref>
supabase db push
```

**⚠️ NOTE:** `013_seed_catalog.sql` is written to run **once** against a fresh catalog — there's no unique constraint on category/product names, so running it twice duplicates every row. If you need to re-seed, either truncate `categories` (cascades to everything below it via `ON DELETE CASCADE`) first, or write a fresh seed file instead of re-running this one.

**Verify:**
- Supabase Dashboard → Database → Tables → you should see `categories`, `sub_categories`, `products`, `product_variants`, `product_images`, `wishlists`
- `SELECT count(*) FROM categories;` → should return `6`
- `SELECT count(*) FROM sub_categories;` → should return `27`
- `SELECT count(*) FROM products;` → should return `104`
- `SELECT name FROM sub_categories WHERE name = 'Festive Packaging';` → should exist but have zero products (`SELECT count(*) FROM products p JOIN sub_categories sc ON sc.id = p.sub_category_id WHERE sc.name = 'Festive Packaging';` → `0`) — this is deliberate, it exercises the empty-state UI.

---

## Phase B: Backend — Redeploy the Edge Function

### Step B.1: Deploy

**What:** Ships the two new route files (`routes/catalog.ts`, `routes/wishlist.ts`) — same Edge Function as Milestone 1, no new secrets required.

**How:**
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project
supabase functions deploy api
```

**Verify:**
```bash
curl https://<your-project-ref>.supabase.co/functions/v1/api/v1/categories
```
Should return `{"data":[{"id":"...","name":"Ingredients",...},...]}` with 6 categories.

```bash
curl "https://<your-project-ref>.supabase.co/functions/v1/api/v1/products?q=cream"
```
Should return a non-empty `data` array (full-text search working).

**If either call returns an empty array or an error:** confirm migrations 007-013 actually ran (Phase A) and that `DB_POOL_URL` is still set correctly (`supabase secrets list` — this doesn't change from Milestone 1, only re-check if you've since switched Supabase projects).

---

## Phase C: Flutter — Rebuild

### Step C.1: Regenerate Code & Run

**What:** Picks up the new Drift tables (schema v2) and Riverpod providers.

**How:**
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**⚠️ If you have the app already installed from Milestone 1 testing:** Drift will run its `onUpgrade` migration automatically (schema v1 → v2, adds the new cache tables) the first time the app opens post-update — no manual device action needed, no uninstall required.

**Expected behavior:**
1. App launches, sign in (Google or Email OTP, from Milestone 1)
2. Tap the **Catalog** tab → should show all 6 categories as bold headings, each with a horizontal row of subcategory tiles (with placeholder photos)
3. Tap a subcategory tile → Level 2 opens: left strip of subcategory names + product grid on the right, grouped by subcategory
4. Scroll the grid → the left strip should highlight whichever subcategory is currently in view; tapping a strip label should scroll the grid to that section
5. Tap a product tile → Level 3 opens: image gallery (swipe left/right), variant chips (tap to switch, price/stock updates), description, "You Might Also Like" row, and a fixed **+ Add to Cart** button at the bottom
6. Tap **+ Add to Cart** → button turns into a `− 1 +` stepper (this is the Milestone 2 local stub — it will *not* survive an app restart; that's expected until Milestone 3)
7. Tap the heart icon next to the product name → fills red (wishlist add) — requires being logged in; if not logged in, a "Log In" bottom sheet appears instead
8. Tap the search icon in the Catalog tab's app bar → type a query (e.g. "cream") → results should appear within ~1 second

**Test offline caching:**
1. With the app open and the Catalog tab already loaded once, turn off WiFi/mobile data (or stop the backend)
2. Force-close and reopen the app, go to Catalog
3. Categories/subcategories/products should still render from the local Drift cache
4. If the cached data is more than 24 hours old, a "Last updated X hours ago" banner should appear at the top

---

## Phase D: Verification Checklist

### Backend Verification
- [ ] `GET /v1/categories` returns all 6 categories with `subCategoryCount`
- [ ] `GET /v1/categories/:id/subcategories` returns that category's subcategories
- [ ] `GET /v1/products?categoryId=<id>` returns products grouped correctly by subcategory when read client-side
- [ ] `GET /v1/products?q=cream` returns relevant results
- [ ] `GET /v1/products/:id` returns full variant + image lists
- [ ] `GET /v1/products/:id/related` returns other products from the same subcategory
- [ ] `POST /v1/wishlist` (with a valid JWT) adds a row; `GET /v1/wishlist` reflects it; `DELETE /v1/wishlist/:variantId` removes it
- [ ] Requests to `/v1/wishlist*` without a JWT return 401

### Flutter Verification
- [ ] Catalog tab renders all 6 categories, no hardcoded text
- [ ] Level 2 scroll-spy works in both directions
- [ ] Badges (Trending/Low Stock/Out of Stock/Sale/New) appear correctly per product
- [ ] Out-of-stock products are still visible in the grid by default (not hidden) — confirms the fix described in `Milestone 2.md` §4
- [ ] Tapping `+` on a low-stock variant (seeded with `stock_qty = 3`) stops incrementing at 3 and shows a "Max stock reached" snackbar — confirms the second fix in `Milestone 2.md` §4
- [ ] Variant selection on product detail updates price + stock + Add button
- [ ] Wishlist heart requires login and persists after toggling
- [ ] Search returns results and shows a "no results" empty state for nonsense queries
- [ ] App works offline after first load, with the staleness banner appearing after 24h of cached data

---

## Troubleshooting

### "Empty categories/products list in the app"
- **Cause:** Migrations 007-013 weren't run, or `013_seed_catalog.sql` failed partway through
- **Fix:** Re-check Phase A's verification queries; if `categories` has rows but `products` doesn't, re-run `013_seed_catalog.sql` after confirming no partial rows exist (`SELECT count(*) FROM products;`)

### "Search returns nothing for any query"
- **Cause:** The generated `search_vector` column wasn't created (migration 009 didn't run, or ran against a Postgres version where `GENERATED ALWAYS AS ... STORED` isn't supported — needs Postgres 12+, Supabase is always well above this)
- **Fix:** `SELECT search_vector FROM products LIMIT 1;` — if this errors with "column does not exist," re-run `009_create_products.sql`

### "App crashes on first launch after updating from Milestone 1"
- **Cause:** Drift schema migration (v1 → v2) failed
- **Fix:** As a last resort during development (not for real user data), uninstall and reinstall the app to get a fresh local DB — this only affects the local cache, not the server

---

## Next Steps After Verification

1. **Commit the code** (if not already done):
   ```bash
   git add -A
   git commit -m "Milestone 2 complete: Catalog & Search"
   git push
   ```
2. **Begin Milestone 3** (Cart & Payments):
   - Read `Planning docs/Phase_Plan_Technical.md` Phase 3 section
   - `localCartStubProvider` (Milestone 2) gets replaced by a real server-synced `cartProvider` — widget code shouldn't need to change
