# Baker Ally — Consolidated Pending Steps (as of 18 July 2026)

Every manual/deployment step called out across all files in `Milestone readme/`, pulled into one list. Two kinds of item below:

- 📍 **Confirmed pending today** — verified directly against the live codebase/accounts during this session's audit (2026-07-18). These are current, not guesses.
- 📋 **Carried over from the milestone's own doc** — listed as pending when that milestone's readme was written. Deployment has clearly progressed since then (Milestone 6's admin routes work against live `orders`/`discounts`/`carts` tables, which means Milestone 3's migrations are live), so some of these are probably already done. Not re-verified this session — spot-check against your Supabase dashboard before assuming either way.

---

## 📍 Confirmed pending today — do these first

These were directly checked (code search, account status, git status) during this session's planning-doc audit.

### 1. Firebase push notifications — 3 manual steps
Full detail in `Milestone 6 manual steps.md` Phase D. Nothing works until all three are done:
1. Run `flutterfire configure` (needs your Firebase console login) → generates `lib/firebase_options.dart`
2. Add 2 lines to `main.dart`:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
   ```
3. Firebase Console → Project Settings → Service Accounts → generate a private key → `supabase secrets set FIREBASE_SERVICE_ACCOUNT_KEY='<json>'`

Everything downstream of this (Crashlytics, Firebase Analytics — see #4 below) is also blocked on step 2, since none of them work without `Firebase.initializeApp()` being called.

### 2. Sentry error tracking — never actually built
Planned since the original `backend_stack.md` (Phase 1 scope) but no `Sentry.init(...)` call exists anywhere in the Edge Function. Zero error tracking is currently live on a payments app. Now explicitly scheduled in `Phase_Plan_Technical.md` Phase 7 — needs the real SDK wiring, not just alerts on top of something that already exists.

### 3. Apple Developer Account + Google Play Console — not purchased
- Apple Developer: $99/year — not purchased
- Google Play Console: $25 one-time — not purchased

Store submission (Milestone 7) is hard-blocked on both. This is a business/payment action, not engineering — flagged in `Phase_Plan_Business.md` Milestone 7.

### 4. Analytics — nothing is running
`Phase_Plan_Technical.md` says PostHog was replaced by Firebase Analytics back in Milestone 1, but **zero `FirebaseAnalytics` calls exist anywhere in `lib/`**. There is currently no analytics of any kind collecting data. Needs the actual `logEvent()` calls added for add-to-cart, checkout, order-placed (Phase 7 scope) — and needs #1's `Firebase.initializeApp()` first.

### 5. Product Reviews & Ratings — designed, never built
`Phase_Plan_Technical.md` §5.8 documents a full `product_reviews` table + 3 endpoints as Milestone 5 scope. None of it exists — no table, no routes, no UI. Needs an explicit decision: build as a pre-launch addendum, or formally move to post-launch. Currently the one place the docs read as "done" when it isn't.

### 6. Admin panel (`baker_ally_admin`) — not deployed publicly yet
Code is complete and the backend it talks to is live, but the Next.js app itself only runs on `localhost:3000` today. Full walkthrough already written in `Milestone 6 manual steps.md` Phase E (Vercel import, Root Directory = `baker_ally_admin`, env vars, then update the `ADMIN_WEB_ORIGIN` backend secret to the real Vercel URL).

### 7. Uncommitted Milestone 6 work
`git status` on the `Milestone-6` branch currently shows the entire admin panel (`baker_ally_admin/` routes, components, lib files), the new backend admin/FCM routes, and migrations 024–025 as **uncommitted / untracked**. Needs a commit, then a PR merging `Milestone-6` → `main` (same pattern as `Milestone-3`/`Milestone-5` before it) before any of this is the "official" state of the repo.

### 8. Dependency/stack cleanup decisions
- **Zod** — planned in `backend_stack.md`, never adopted; every route validates manually. Decide: adopt now or drop from the doc (not launch-blocking).
- **`purchases_flutter` (RevenueCat)** — pinned, zero usage, no matching product feature (Baker Ally sells physical goods, not subscriptions). Recommend dropping before a store submission.
- **`app_links`** — pinned, zero usage. Legitimately needed once push-notification-tap deep linking is built (Phase 4), inert until then — keep, don't drop.

### 9. Codemagic CI/CD — not set up
No automated Flutter build/sign/upload pipeline exists yet. Currently all Flutter builds are manual (`flutter build appbundle`). This is Phase 7 §7.2 scope, and — same as Vercel — needs its "Project directory" setting pointed at `baker_ally_flutter` specifically, since this is a monorepo.

### 10. Razorpay — still test-mode
Live keys are an explicit Phase 7 swap (`RAZORPAY_KEY_ID`/`RAZORPAY_KEY_SECRET` replaced with production values). No real money has moved through the app yet. (Flagged here for completeness — you've noted this is a decision to revisit later, not something to action now.)

---

## 📋 Milestone 1 — Foundation

Source: `Milestone 1 manual steps.md`, `Milestone 1.md`, `Development vs Production Checklist.md`

- [ ] Run migrations `001`–`006` against the live Supabase project
- [ ] Supabase Dashboard → Authentication → Hooks → enable `public.custom_access_token_hook` (JWT role claims won't work without this)
- [ ] Supabase Dashboard → Authentication → URL Configuration → add redirect URL `com.chefsandbakers.app://login-callback`
- [ ] **Email OTP template customization** (needs Supabase Pro or custom SMTP): Dashboard → Authentication → Email Templates → "Magic link or OTP" → replace body with `{{ .Token }}` markup so users get a 6-digit code instead of a magic link. Documented as explicitly pending in `Milestone 1.md` §5.
- [ ] Google OAuth: create the Android OAuth client in Google Cloud Console with your debug SHA-1, paste Client ID/Secret into Supabase → Authentication → Providers → Google
- [ ] Turn OFF "Verify JWT with legacy secret" in Supabase Dashboard → Edge Functions → `api` → Settings (required for `/v1/health` and other public routes to work)
- [ ] Fill real values into `baker_ally_flutter/.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`)
- [ ] Set Edge Function secrets: `DB_POOL_URL` (required), `UPSTASH_REDIS_REST_URL`/`TOKEN` (optional), `SENTRY_DSN` (optional — see confirmed-pending #2 above, this was never actually done)
- [ ] **Release keystore + release-SHA-1 OAuth client** — explicitly deferred to Play Store prep (Milestone 7), don't do yet
- [ ] Phone/SMS OTP via Firebase — deferred fast-follow, needs a bridging design session first (Firebase verifies phone client-side, nothing bridges that into a Supabase session yet)

**Likely already done** (per memory, but not re-verified this session): the core migrations and OAuth setup, since Milestone 2 built directly on top of this and was confirmed deployed live.

---

## 📋 Milestone 2 — Browse the Catalog

Source: `Milestone 2 manual steps.md`, `Milestone 2.md`

- [ ] Run migrations `007`–`013` (categories, sub-categories, products, variants, images, wishlists, seed data) — **run-once only**, re-running `013_seed_catalog.sql` duplicates every row (no unique constraint on names)
- [ ] Redeploy Edge Function to ship `routes/catalog.ts` + `routes/wishlist.ts`
- [ ] Rebuild Flutter (`dart run build_runner build --delete-conflicting-outputs`) to pick up Drift schema v2

**Status:** memory records this milestone as already deployed live and tested on a device — likely fully done. Listed here for completeness only.

**Known permanent gap, not a pending step:** all catalog data (104 products, images, prices, stock) is placeholder/fictional, seeded for testing. Real product data needs to go in via the Milestone 6 admin panel or a fresh seed file — see `Milestone 2.md` §2 for the full list of what's fake.

---

## 📋 Milestone 3 — Buy Products (Cart & Payments)

Source: `Milestone 3 manual steps.md`, `Milestone 3.md`, `PHASE3_TESTING_WITHOUT_RAZORPAY.md`

- [ ] Run migrations `014`–`021` (carts, cart_items, discounts, product_discounts, orders, order_items, webhook_events, `BAKE10` demo discount seed)
- [ ] **Razorpay test account setup** (~10 min): sign up at dashboard.razorpay.com, switch to Test Mode, generate test API keys
- [ ] Configure the Razorpay webhook (Settings → Webhooks → point at `https://<ref>.supabase.co/functions/v1/api/v1/webhooks/razorpay`, set a shared secret)
- [ ] Set Edge Function secrets: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`
- [ ] Redeploy Edge Function to ship the 5 new route files + Razorpay lib
- [ ] Rebuild Flutter, run through the full checkout test flow with a Razorpay test card (`4111 1111 1111 1111`) or test UPI (`success@razorpay`)

**Status per memory:** "code complete, not deployed" as of last update — but Milestone 6's admin order routes work against live `orders`/`carts`/`discounts` tables, so the migrations at minimum are almost certainly live. **The Razorpay account/webhook setup specifically is the part most likely still outstanding** — worth a direct check of `supabase secrets list` for `RAZORPAY_KEY_ID`.

**Known permanent gap:** flat ₹49 shipping is a placeholder in two places that must stay in sync (`checkout.ts` backend + `checkout_providers.dart` Flutter) until the Porter delivery decision is made — you've already flagged this as a pending business decision to skip for now.

---

## 📋 Milestone 5 — My Account & Smart Reordering

Source: `Milestone 5 manual steps.md`

- [ ] Create Supabase Storage bucket `avatars` (public) with the 3 policies documented in Phase A.1 (select/insert/update, path pattern `{userId}.webp`)
- [ ] Create Supabase Storage bucket `invoices` (private, no policies needed — service-role only)
- [ ] Redeploy Edge Function to ship `routes/orders.ts`, `routes/order-again.ts`, extended addresses/cart/users routes, `lib/invoice.ts` (new `pdf-lib` dependency)
- [ ] Rebuild Flutter (`flutter pub get` + `dart run build_runner build`) to pick up Drift v3→v4 (`CachedOrders` table) and the new `image_picker`/`url_launcher` deps

**Status per memory:** "code complete, not deployed" as of last update. **The two Storage buckets are the most likely outstanding item** — nothing later in the build (Milestone 5.5, Milestone 6) required them, so there's been no forcing function to create them. Worth checking Supabase Dashboard → Storage → Buckets directly.

---

## 📋 Milestone 5.5 — Home Tab

Source: `Milestone 5.5 pending steps.md`, `Milestone 5.5.md`

- [ ] Rebuild Flutter on a device (`flutter clean && flutter pub get && flutter run`) — backend was deployed live during the build, but the app itself was never rebuilt on a real device with this code, so the Drift v4→v5 migration path (`CachedHomeSections`) has never actually been exercised outside `deno check`/`flutter analyze`
- [ ] Live-verify Home actually renders real product tiles (not empty sections) — depends on the seeded catalog having recent, discounted, and trending products
- [ ] Live-verify "New Offers" tiles show the real discounted price, not a full-price variant
- [ ] Live-verify "See all" pagination ("Load More" on a 20+ product section)
- [ ] Live-verify offline fallback (airplane mode after first load) renders from `CachedHomeSections`
- [ ] Decide whether to seed more catalog data if Home renders sparse/empty sections — a content decision, not a code fix

---

## 📋 Voice Search (shipped outside the milestone sequence, 2026-07-18)

Source: `Voice Search.md`

- [ ] **On-device test not done.** Build/compile verification (`flutter analyze`, `gradlew compileDebugKotlin`) confirms the code is wired correctly, but the actual microphone → recognition → search-results flow has never been exercised on a real device or emulator with mic access. Worth a specific pass: tap the mic icon on Home/Catalog/Order Again, confirm the permission prompt appears, speak a query, confirm results populate.

**Deliberately not built (not a gap, a decision):** `voice_search_used` analytics event — skipped as not worth tracking at current volume, trivial to add later if it becomes useful.

---

## 📋 Milestone 6 — Admin Web Panel

Source: `Milestone 6 manual steps.md`, `Milestone 6.md` (full detail already in that doc — summarized here)

- [ ] Confirm `ADMIN_WEB_ORIGIN` secret is set correctly (currently should be `http://localhost:3000` for dev)
- [ ] Create your first admin user manually (Supabase Dashboard → Authentication → Users → Add user, then `UPDATE users SET role_id = ...` to admin) — the invite flow needs an existing admin to bootstrap from
- [ ] Full local smoke test: categories → products → variants → images → discounts → orders → user invite → cross-sell
- [ ] Deploy to Vercel (see confirmed-pending #6 above)
- [ ] Update `ADMIN_WEB_ORIGIN` to the real Vercel URL post-deploy (the #1 cause of a broken deploy if skipped)
- [ ] Firebase push setup (see confirmed-pending #1 above — same 3 steps, this doc is where they're written up in full)

---

## Suggested order of attack

If you want a single sequence rather than working milestone-by-milestone:

1. **Verify what's actually live** — `supabase secrets list`, check Storage buckets, check which migrations have run (quick Supabase Dashboard pass covers M1/M3/M5's uncertain items in a few minutes)
2. **Commit + merge `Milestone-6` → `main`** (confirmed-pending #7) — get the repo into a clean, official state first
3. **Firebase 3-step setup** (confirmed-pending #1) — unblocks push notifications, Crashlytics, and Analytics all at once
4. **Deploy admin panel to Vercel** (confirmed-pending #6) — short, mostly done, just needs execution
5. **Sentry init** (confirmed-pending #2) — before more real users touch the app
6. **Reviews & Ratings decision** (confirmed-pending #5) and **dependency cleanup** (confirmed-pending #8) — both are just decisions, not work, until you decide
7. **Dev accounts + Codemagic + Razorpay live keys** — Phase 7 launch prep, no rush until you're actually ready to submit
