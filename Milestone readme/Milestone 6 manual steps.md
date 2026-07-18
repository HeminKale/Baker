# Milestone 6 — Manual Setup & Deployment Steps

**Status:** Code is complete and the backend half is already deployed live. These are the remaining manual steps: confirming the backend secrets/CORS are set, creating the first admin user, wiring up Firebase push (optional but recommended), and — new — deploying the admin panel itself to Vercel so it's reachable at a real URL instead of just `localhost`.

**Time Required:** ~15 minutes for backend verification + first admin user, ~10 minutes for Vercel deploy, ~15–20 minutes for the Firebase steps (optional, can be done later).

**Prerequisites:** Milestones 1–5 already deployed. Migrations 022–025 already applied and the Edge Function already redeployed with the admin routes (this happened live during the build — Phase A below is just verification).

---

## Phase A: Verify the Backend Is Live (should already be done)

These were run during the build, but confirm before moving on.

### Step A.1: Confirm migrations 022–025 applied

```sql
select name from roles where name = 'staff';  -- 1 row
select column_name from information_schema.columns
  where table_name = 'wishlists' and column_name = 'last_notified_at';  -- 1 row
select table_name from information_schema.tables where table_name = 'product_cross_sell';  -- 1 row
select tgname from pg_trigger where tgname = 'trg_notify_restock';  -- 1 row
```

### Step A.2: Confirm the `ADMIN_WEB_ORIGIN` secret is set

This is what the backend checks incoming `/v1/admin/*` requests' `Origin` header against for CORS.

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_backend
supabase secrets list
```

Look for `ADMIN_WEB_ORIGIN` in the list. For local dev it should be `http://localhost:3000`. **You'll need to update this once you deploy to Vercel (Phase E) — see the note there.**

If it's missing:
```bash
supabase secrets set ADMIN_WEB_ORIGIN=http://localhost:3000
supabase functions deploy api
```

### Step A.3: Confirm the Edge Function has the admin routes

```bash
curl "https://bpmtnsaebrnuoujwxfea.supabase.co/functions/v1/api/v1/admin/products"
```
Expect `401 Unauthorized` (no token) — that confirms the route exists and is gated, not a 404.

---

## Phase B: Create Your First Admin User

The invite flow (6.7) needs at least one existing admin to invite anyone else — so the very first user has to be created directly.

### Step B.1: Create the auth user

Supabase Dashboard → Authentication → Users → **Add user** → enter your email + a password → **Create user**.

### Step B.2: Give them the admin role

Find the new user's `id` (Dashboard → Authentication → Users, click them), then:

```sql
update users set role_id = (select id from roles where name = 'admin')
where id = '<the-user-id-from-step-B.1>';
```

(If your `users` table row doesn't exist yet for this auth user — it's normally created by a trigger on signup — check `public.users` first; if missing, this is the same "profile row" pattern used everywhere else in the app.)

### Step B.3: Log in

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_admin
npm install    # first time only
npm run dev
```
Open `http://localhost:3000/login`, sign in with the email/password from B.1. You should land on the dashboard with the full nav (Categories, Products, Discounts, Orders, Users, Wishlist Insights).

---

## Phase C: End-to-End Smoke Test (local)

1. **Categories** → create a category, then a sub-category under it.
2. **Products** → create a product under that sub-category, add a variant (SKU + price + stock), upload an image.
3. **Wishlist Insights** → should load (empty is fine if nothing's wishlisted yet).
4. **Discounts** → create a test discount, edit it.
5. **Orders** → should list any orders from earlier milestones' testing; open one, confirm the detail view renders items + address.
6. **Users** → invite a second user (staff role) → copy the generated link → open it in an incognito window → set a password → confirm it lands them in the dashboard with the reduced nav (no Discounts/Users).
7. **Cross-sell**: open a product → Cross-sell section → search for another product → Add → confirm it shows up, remove it.

---

## Phase D: Firebase Push Notifications (optional — can be done anytime later)

Restocking works fine without this; it just won't send a push to wishlisters until these are done. Full explanation of *why* each step is needed is in the conversation history / `bakerally_milestone6_status.md`.

### Step D.1: `flutterfire configure`

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
dart pub global activate flutterfire_cli   # first time only
flutterfire configure
```
Follow the prompts (log into your Firebase account, pick or create a project, select Android/iOS). This generates `lib/firebase_options.dart`.

### Step D.2: Wire up `main.dart`

Add these two lines inside `main()`, after `WidgetsFlutterBinding.ensureInitialized()` and before `runApp(...)`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```
(`firebaseMessagingBackgroundHandler` and the imports it needs are already in `lib/core/notifications/fcm_service.dart` — check its top-level function and import it into `main.dart`.)

### Step D.3: Get a service account key and set the backend secret

1. Firebase Console → your project → gear icon → **Project Settings** → **Service Accounts** tab.
2. **Generate new private key** → downloads a JSON file.
3. Set it as an Edge Function secret (paste the *entire* file contents as one value):
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_backend
supabase secrets set FIREBASE_SERVICE_ACCOUNT_KEY='<paste full JSON here>'
```

### Step D.4: Set the internal notify secret (if not already done)

This is the shared secret between the DB trigger and `routes/internal.ts` — see the note in migration `024_AP_restock_notify_trigger.sql`.

```sql
select vault.create_secret('<any-strong-random-string>', 'internal_notify_secret');
```
```bash
supabase secrets set INTERNAL_NOTIFY_SECRET=<the-same-strong-random-string>
```

### Step D.5: Redeploy and test

```bash
supabase functions deploy api
```
Test: wishlist an out-of-stock item on your phone (needs D.1–D.2 done and the app rebuilt/reinstalled first), then in the admin panel restock that variant's `stock_qty` from 0 to something positive. A push should arrive within a few seconds.

---

## Phase E: Deploy the Admin Panel to Vercel

Right now the admin panel only runs on `localhost:3000`. This puts it on a real URL your staff can log into from anywhere.

### Step E.1: Push the code to GitHub (if not already)

The repo is already on GitHub per your earlier message (`Milestone-6` branch). Confirm `baker_ally_admin/` is committed and pushed:
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project
git status
git push
```
`baker_ally_admin/.gitignore` already excludes `.env.local` and `node_modules` — don't force-add those.

### Step E.2: Import the project into Vercel

1. Go to <https://vercel.com> → sign in with your GitHub account (free, no card needed for hobby tier).
2. **Add New... → Project** → select your `Baker` repo → **Import**.
3. **Root Directory** — this is the one setting that matters most: click **Edit** next to Root Directory and set it to `baker_ally_admin`. (Your repo has 3 apps in it — Vercel needs to know which folder is the Next.js app; leaving this as the repo root will fail the build.)
4. Framework Preset should auto-detect as **Next.js** once the root directory is set correctly.
5. Leave Build Command / Output Directory as the Next.js defaults (`next build` / auto-detected) — don't override these.

### Step E.3: Add environment variables

Before clicking Deploy, expand **Environment Variables** and add the same three keys from `baker_ally_admin/.env.local`:

| Key | Value |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://bpmtnsaebrnuoujwxfea.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | (same anon key as in your local `.env.local`) |
| `NEXT_PUBLIC_API_BASE_URL` | `https://bpmtnsaebrnuoujwxfea.supabase.co/functions/v1/api` |

These are all `NEXT_PUBLIC_*` because they're safe to expose to the browser (anon key is meant to be public; RLS + the backend's own auth checks do the real gating) — same pattern as `baker_ally_flutter/.env`.

### Step E.4: Deploy

Click **Deploy**. Takes ~2–3 minutes. Vercel gives you a URL like `https://baker-ally-admin.vercel.app` (or similar, based on your project name).

### Step E.5: Update `ADMIN_WEB_ORIGIN` to the real URL

This is the step people forget — until you do this, CORS will block the deployed site from calling the backend. The backend was locked to `http://localhost:3000` in Phase A.

```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_backend
supabase secrets set ADMIN_WEB_ORIGIN=https://your-actual-vercel-url.vercel.app
supabase functions deploy api
```
**No trailing slash** on the URL — `hono/cors` compares it exactly against the browser's `Origin` header.

### Step E.6: Test the deployed site

Open your Vercel URL, log in with the admin user from Phase B. Everything should behave identically to local — if login works but every subsequent API call fails with a CORS error in the browser console, re-check Step E.5 (mismatched origin is the #1 cause).

### Note on future deploys

Vercel auto-redeploys on every push to whichever branch you connected (by default, your repo's default branch). If you want it to redeploy on pushes to `Milestone-6` (or wherever admin-panel work happens) instead of `main`, change it under Vercel Project → Settings → Git → Production Branch.

---

## Phase F: Verification Checklist

### Backend
- [ ] Migrations 022–025 applied
- [ ] `ADMIN_WEB_ORIGIN` secret matches whatever origin you're actually calling from (localhost during dev, the Vercel URL in prod)
- [ ] `GET /v1/admin/products` returns 401 without a token, 200 with an admin/staff token
- [ ] Non-admin/staff JWT gets 403 on admin routes

### Admin Panel (local or deployed)
- [ ] Login works, wrong-role users get bounced to `/unauthorized`
- [ ] Staff nav hides Discounts and Users; admin nav shows everything
- [ ] Categories/Products/Variants/Images CRUD all work
- [ ] Orders list + detail render correctly
- [ ] Invite flow generates a working link
- [ ] Cross-sell add/remove works and shows up on the storefront's "You Might Also Like" (positions 5–7)

### Push (only if Phase D was done)
- [ ] `flutterfire configure` ran, `firebase_options.dart` exists
- [ ] `main.dart` has the 2 new lines
- [ ] `FIREBASE_SERVICE_ACCOUNT_KEY` and `INTERNAL_NOTIFY_SECRET` are both set
- [ ] Restocking a wishlisted item triggers a real push notification on device

---

## Troubleshooting

**"Vercel build fails immediately."**
Almost always the Root Directory wasn't set to `baker_ally_admin` (Step E.2.3) — Vercel tried to build the whole monorepo as if it were the Next.js app.

**"Login works locally but not on the deployed Vercel URL — network tab shows CORS errors."**
`ADMIN_WEB_ORIGIN` on the backend doesn't match the Vercel URL exactly (Step E.5). Check for a trailing slash mismatch or `http` vs `https`.

**"Admin panel loads but every page shows an error / can't fetch data."**
Check the three `NEXT_PUBLIC_*` env vars in Vercel Project → Settings → Environment Variables — a typo'd Supabase URL or anon key fails silently in the browser console, not at build time.

**"Invited user's link says 'invalid or expired'."**
Supabase invite links expire (default 24h). Re-invite from the Users page to generate a fresh one.

**"Restocking doesn't send a push, no errors anywhere."**
Expected if Phase D wasn't done — the trigger and `routes/internal.ts` both silently no-op when the secrets aren't set (deliberate, so stock updates never fail because of a missing notification config). Walk through Phase D.

---

## Next Steps After Verification

1. **Commit the code** (if anything changed, e.g. `main.dart` from Phase D):
   ```bash
   git add -A
   git commit -m "Milestone 6 complete: Admin Web Panel"
   git push
   ```
2. **Milestone 7** — next planned scope not yet defined in this session; check `Plan.md` / `Planning docs/Phase_Plan_Business.md` for what's queued after the admin panel.
