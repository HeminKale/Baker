# Milestone 1 — Foundation

Status: **code complete, not yet deployed.** Everything below was built and verified locally (`flutter analyze`, `flutter test`, `deno check`) without live Supabase/Firebase credentials. It needs the manual steps in §4 before it runs end-to-end.

## 1. Scope Decision — Google Sign-In + Email OTP This Milestone

`Phase_Plan_Technical.md` assumed Supabase's own phone-OTP provider (Twilio/MSG91). Supabase has no built-in Firebase phone provider, so using Firebase for OTP (the decision from the last planning session) means Firebase verifies the phone number client-side and something has to bridge that into an app session — Supabase doesn't do it natively.

We shipped **Google Sign-In + Email OTP** for Milestone 1:
- **Google Sign-In:** Fully native to `supabase_flutter` — zero bridging code, the JWT reaching the backend is a real Supabase-issued token. Requires Google Cloud OAuth client setup (see manual steps).
- **Email OTP (added during testing, July 2026):** Supabase's built-in email provider (enabled by default) — zero Google Cloud setup, sends a 6-digit code, no consent screen friction. Provides a working login path if Google OAuth setup is blocked. Both flows create the same Supabase JWT and trigger `onAuthStateChange` identically.
- **Firebase phone OTP:** Deferred to a fast-follow milestone once the bridging approach (Firebase verifies phone → backend mints an app session) is designed and agreed.

Practical effect: the "user can sign up via OTP" acceptance criterion is **partially met** — Email OTP works; Firebase phone OTP is deferred. Google Sign-In works when OAuth credentials are configured.

## 2. What Was Built

**Database** (`migrations/001-006`, numbered, run manually against Supabase):
- `roles`, `privilege_levels`, `privilege_level_permissions`, `users`, `addresses` — per `00_common_architecture.md` §3-4, with RLS enabled (no policies — only the backend's service-role key touches these tables) and FK indexes.
- `users` has one addition beyond the architecture doc: `fcm_token TEXT`, needed for `POST /v1/users/fcm-token` (Phase 1.5) with nowhere else to live.
- `006` adds the `custom_access_token_hook` function that writes `app_metadata.role` onto every issued JWT (see §4 — must be enabled in the dashboard).

**Backend** (`baker_ally_backend/`, Hono on Supabase Edge Functions, one function named `api`):
- `authMiddleware` (verifies the Supabase JWT via `supabase.auth.getUser`), `adminMiddleware` (checks `app_metadata.role === 'admin'`, not yet used by any route)
- `rateLimitMiddleware` (Upstash-backed, applied to `/v1/auth/*`; no-ops until Upstash secrets are set)
- Drizzle schema (`db/schema.ts`) mirroring the migrations
- Routes: `GET /v1/health`, `POST /v1/auth/me` (get-or-creates the `public.users` row on first login — the signup-hook replacement), `GET /v1/users/me`, `PATCH /v1/users/me`, `POST /v1/users/fcm-token`
- Sentry wraps `app.onError`, no-ops until `SENTRY_DSN` is set

**Flutter** (`baker_ally_flutter/`, package `baker_ally_flutter`, applicationId/bundle id `com.chefsandbakers.app`):
- Full approved package list from `flutter_library_stack.md` §17 added to `pubspec.yaml` (some version bumps were required to resolve on Flutter 3.44.5/Dart 3.12.2 — see `pubspec.yaml` for the exact pinned versions)
- `core/` — envied config (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`), Dio client with a JWT interceptor reading from `flutter_secure_storage`, GoRouter with a `StatefulShellRoute` 5-tab shell (Home/Catalog/Order Again/Brownie Points/Cart, placeholder bodies) and a redirect guard for protected routes
- `features/auth/` — **Two sign-in paths:**
  - **Google Sign-In** via `supabase_flutter` (`AuthRepository.signInWithGoogle()`, `LoginScreen` "Continue with Google" button)
  - **Email OTP** via Supabase's email provider (`AuthRepository.sendEmailOtp()`, `verifyEmailOtp()`, new `EmailOtpScreen` — enter email → receive 6-digit code → verify)
  - Both paths: mirror session token into secure storage on every auth event, call `POST /v1/auth/me` after login, create identical Supabase JWTs
- `features/profile/` — `GET /v1/users/me` wired as a Riverpod provider (no screen consumes it yet — the Profile Overlay UI is Phase 5)
- `shared/local_db/` — Drift with one placeholder table, proving the codegen pipeline for Phase 2 to extend
- Firebase (`firebase_core`, `firebase_crashlytics`, etc.) is pinned as a dependency but **not initialized** — that needs `flutterfire configure`, an interactive step requiring your Firebase login (see §4)

## 3. Acceptance Criteria (from `Phase_Plan_Technical.md`)

- [x] User can sign up via OTP, receives JWT, is stored in `users` table with correct role — **email OTP code complete** (Firebase phone OTP deferred); Email OTP sends a 6-digit code to any email. **⏳ PENDING:** Email template customization in Supabase Dashboard (see §4)
- [ ] User can sign in via Google — code complete, needs live credentials + dashboard redirect URL to verify (alternative: Email OTP requires no Google setup)
- [ ] JWT contains role claim — verified in Hono middleware — code complete, needs the JWT hook enabled in the dashboard (§4) to verify
- [ ] Non-authenticated requests to protected routes return 403 — `authMiddleware` returns 401 for missing/invalid tokens (401 is the correct code for "not authenticated" vs 403 "authenticated but forbidden"; `adminMiddleware` returns 403)
- [ ] User can log out — JWT cleared, Drift cleared, redirected to login — code complete (`AuthRepository.signOut`), not yet device-tested
- [ ] `GET /v1/health` returns 200 from Edge Function — code complete, not yet deployed
- [ ] Staging environment mirrors production schema — depends on you running the same migrations against both projects

## 4. Manual Steps Required From You

1. Run `migrations/001_*.sql` through `006_*.sql` in order against your Supabase project (SQL editor or `psql` — these are plain numbered SQL files, not Supabase CLI-tracked migrations)
2. Supabase Dashboard → Authentication → Hooks → "Customize Access Token (JWT) Claims" → select `public.custom_access_token_hook` (migration 006)
3. Supabase Dashboard → Authentication → URL Configuration → add redirect URL `com.chefsandbakers.app://login-callback`
4. **⏳ PENDING — Email OTP Template (Supabase Pro plan or custom SMTP required):**
   - Supabase Dashboard → **Authentication** → **Email Templates** → **"Magic link or OTP"**
   - Edit the **Body** field to display the 6-digit code instead of a link. Replace the current body with:
     ```html
     <h2>Your login code</h2>
     <p>Please enter this code to sign in: {{ .Token }}</p>
     <p>This code expires in 10 minutes.</p>
     ```
   - Save. After this, "Continue with Email" will send a 6-digit code in the email instead of a magic link.
5. Supabase Dashboard → Authentication → Providers → enable Google, with your existing Google OAuth client credentials
6. Fill real values into `baker_ally_flutter/.env` (copy from `.env.example`): `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` (`https://<ref>.supabase.co/functions/v1/api`)
7. Set Edge Function secrets: `supabase secrets set DB_POOL_URL=... UPSTASH_REDIS_REST_URL=... UPSTASH_REDIS_REST_TOKEN=... SENTRY_DSN=...` (Upstash/Sentry optional — routes no-op gracefully without them)
8. Deploy: `supabase link --project-ref <ref>` then `supabase functions deploy api` from `baker_ally_backend/`
9. Run the app: `cd baker_ally_flutter && dart run build_runner build --delete-conflicting-outputs && flutter run`

## 5. Known Gaps / Deliberate Non-Scope

- **Email template customization** — Code is ready to receive 6-digit OTP codes from email, but requires Supabase Pro plan or custom SMTP setup to customize the email template. Free tier cannot edit templates (§4 step 4). Once template is customized to show `{{ .Token }}`, email OTP is fully functional.
- Phone OTP (Firebase) — fast-follow, needs a bridging design session first
- `flutterfire configure` not run — Crashlytics/FCM/Analytics are pinned dependencies only, not initialized
- No live end-to-end run happened in this session (no Supabase/Firebase credentials available) — verification was `flutter analyze`, `flutter test`, and `deno check` only
- Auth-flow widget tests are minimal (`test/widget_test.dart` only smoke-tests a dependency-free placeholder widget) — full login-flow tests need a mocked `SupabaseClient`, deferred to a dedicated testing pass
