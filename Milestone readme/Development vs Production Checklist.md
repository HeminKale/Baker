# Development vs Production Deployment Checklist

**Purpose:** Quick reference for what to set up NOW (development) vs LATER (Play Store production).

---

## Milestone 1 — Foundation

### Phase A: Database & Supabase Setup

#### NOW (Development) ✅
- [ ] Run database migrations 001-006 against production Supabase
- [ ] Enable JWT custom claims hook in Supabase Dashboard
- [ ] Get debug SHA-1 fingerprint from Android Studio
- [ ] Create Android OAuth client in Google Cloud with debug SHA-1
- [ ] Copy Google OAuth Client ID and Secret
- [ ] Enable Google OAuth in Supabase Dashboard
- [ ] Add redirect URL `com.chefsandbakers.app://login-callback` in Supabase
- [ ] Create `product-images` storage bucket (Phase 2 prep)

#### LATER (Play Store) 📅
- [ ] Create release keystore (`baker_ally-release.jks`)
- [ ] Get release SHA-1 fingerprint from release keystore
- [ ] Create second Android OAuth client in Google Cloud with release SHA-1
- [ ] Update Supabase to support release OAuth client (add release SHA-1 to existing client OR create separate client)
- [ ] Set up staging Supabase project (mirror of production)

---

### Phase B: Backend Deployment

#### NOW (Development) ✅
- [ ] Set Edge Function secrets:
  - [ ] `DB_POOL_URL` (Supabase pooler, port 6543) — **REQUIRED**
  - [ ] `UPSTASH_REDIS_REST_URL` (optional)
  - [ ] `UPSTASH_REDIS_REST_TOKEN` (optional)
  - [ ] `SENTRY_DSN` (optional)
  - [ ] `FIREBASE_*` secrets (not used this milestone, skip for now)
- [ ] Deploy backend: `supabase functions deploy api`
- [ ] **⚠️ IMPORTANT: Turn OFF "Verify JWT with legacy secret"** in Edge Function settings
  - Go to Supabase Dashboard → Edge Functions → Click `api` → Settings
  - Toggle "Verify JWT with legacy secret" to **OFF**
  - Click Save changes
- [ ] Verify health endpoint: `GET /v1/health` returns 200

#### LATER (Play Store) 📅
- [ ] Set up staging Edge Functions with same secrets
- [ ] Enable monitoring/observability for production backend
- [ ] Set up production Sentry project (if not already done)
- [ ] Configure backup/disaster recovery for DB

---

### Phase C: Flutter App Configuration

#### NOW (Development) ✅
- [ ] Create `.env` file in `baker_ally_flutter/` with debug values:
  ```
  SUPABASE_URL=https://your-project-ref.supabase.co
  SUPABASE_ANON_KEY=your-anon-key
  API_BASE_URL=https://your-project-ref.supabase.co/functions/v1/api
  ```
- [ ] Verify `.env` is in `.gitignore` (don't commit credentials)
- [ ] Run Dart code generation: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Verify platform configs (AndroidManifest.xml, Info.plist have deep link)

#### LATER (Play Store) 📅
- [ ] Create `.env.production` with production values (same endpoints, different OAuth client if needed)
- [ ] Create `.env.staging` with staging Supabase credentials
- [ ] Run `flutterfire configure` to initialize Firebase
- [ ] Set up Firebase Crashlytics initialization
- [ ] Configure FCM (push notifications)
- [ ] Update `pubspec.yaml` with final production versions
- [ ] Sign app with release keystore
- [ ] Build release AAB for Play Store

---

### Phase D: Build & Run

#### NOW (Development) ✅
- [ ] Set up Android Emulator (one-time ~10 min)
- [ ] Generate code: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Run Flutter analyze & tests: `flutter analyze && flutter test`
- [ ] Launch emulator: `flutter emulators --launch Pixel_6_API_33`
- [ ] Run app: `flutter run`
- [ ] Test Google Sign-In flow
- [ ] Test protected routes (Cart redirects to login)
- [ ] Test logout

#### LATER (Play Store) 📅
- [ ] Build release APK: `flutter build apk --release`
- [ ] Build release AAB: `flutter build appbundle --release`
- [ ] Test release build on physical device
- [ ] Run full QA testing suite
- [ ] Prepare release notes and screenshots
- [ ] Submit to Play Store
- [ ] Monitor crash reports and user feedback

---

### Phase E: Verification

#### NOW (Development) ✅
- [ ] Backend health check: `GET /v1/health` → 200
- [ ] Database: `SELECT * FROM roles;` shows `customer_individual` and `admin`
- [ ] Flutter app launches without crashes
- [ ] Google Sign-In works end-to-end
- [ ] JWT stored in secure storage
- [ ] Protected routes redirect correctly
- [ ] Logout clears JWT and redirects to login

#### LATER (Play Store) 📅
- [ ] Release build installs on Play Store device
- [ ] All verification checks pass on release build
- [ ] No crashes reported in Crashlytics
- [ ] Performance metrics acceptable (latency, memory, battery)
- [ ] Security audit passed (OWASP top 10, credential handling)
- [ ] User feedback collected and logged

---

## Changing Supabase Account / Data Migration

**When switching to a different Supabase account or project:**

| Step | Action | Where to get new value | Notes |
|------|--------|------------------------|-------|
| 1 | Run migrations 001-006 | New Supabase project | Required every time |
| 2 | Enable JWT hook | New project → Auth → Hooks | Required every time |
| 3 | Configure Google OAuth | New project → Auth → Providers | Use same OAuth credentials, register same redirect URL |
| 4 | Create storage bucket | New project → Storage | Required for Phase 2 |
| 5 | Get new `DB_POOL_URL` | New project → Settings → Database → Connection String (port 6543) | **DIFFERENT for each project** |
| 6 | Set Edge Function secrets | `supabase secrets set DB_POOL_URL=...` | Use new project's connection string |
| 7 | Disable JWT verification | New project → Edge Functions → `api` → Settings | Turn OFF "Verify JWT with legacy secret" |
| 8 | Re-deploy backend | `supabase functions deploy api` | Redeploy to new project |
| 9 | Update Flutter `.env` | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` | **DIFFERENT for each project** |
| 10 | Rebuild Flutter | `dart run build_runner build --delete-conflicting-outputs` | Regenerate configs with new values |

**Data Loss Warning:**
- Old user accounts will NOT migrate to new Supabase project
- New project starts with empty database
- Each project is completely isolated
- Plan data migration strategy before switching (export/import if needed)

**Testing Before Switch:**
1. Test all flows on current Supabase project
2. Document current state (user counts, data, settings)
3. Create new Supabase project
4. Run through Phase A-D on new project
5. Verify all flows work on new project
6. Only then switch Flutter app to new `.env` values

---

## Quick Reference: What Not to Do

### NOW ❌ (Don't do these until Play Store):
- ❌ Create release keystore yet
- ❌ Run `flutterfire configure`
- ❌ Build release APK/AAB
- ❌ Submit to Play Store
- ❌ Set up staging environment (can do, but not required yet)
- ❌ Enable production Sentry project (use dev/test first)

### ALWAYS ⚠️:
- ⚠️ **NEVER** commit `.env` file with real credentials
- ⚠️ **NEVER** commit release keystore to git
- ⚠️ **NEVER** share Google OAuth Client Secret publicly
- ⚠️ **NEVER** use debug build for Play Store
- ⚠️ **NEVER** share Supabase service-role key with frontend

---

## Google OAuth & SHA-1 Reference

| Aspect | Debug (NOW) | Release (LATER) |
|--------|------|---------|
| **Keystore** | `~/.android/debug.keystore` (auto) | `android/app/baker_ally-release.jks` (you create) |
| **SHA-1 source** | Android Studio or keytool | keytool on release keystore |
| **Google Cloud client** | `baker_ally_android` | `baker_ally_android_release` |
| **Supabase setup** | Use debug Client ID/Secret | Add release Client ID/Secret |
| **When to set up** | NOW (Milestone 1) | LATER (Play Store prep) |
| **Validity** | Only for debug builds on dev devices | Only for release builds signed with release keystore |

---

## Environment Configuration Reference

### Development (`.env`)
```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
API_BASE_URL=https://your-project-ref.supabase.co/functions/v1/api
```
**Use for:** Local emulator, dev device testing

### Staging (`.env.staging`) — Optional but recommended
```
SUPABASE_URL=https://your-staging-ref.supabase.co
SUPABASE_ANON_KEY=your-staging-anon-key
API_BASE_URL=https://your-staging-ref.supabase.co/functions/v1/api
```
**Use for:** Testing before production, QA team

### Production (`.env.production`)
```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
API_BASE_URL=https://your-project-ref.supabase.co/functions/v1/api
```
**Use for:** Play Store release builds

---

## Secrets Management (Supabase Edge Functions)

### Development (Set NOW)
```bash
supabase secrets set DB_POOL_URL="..."  # REQUIRED
supabase secrets set UPSTASH_REDIS_REST_URL="..."  # Optional
supabase secrets set UPSTASH_REDIS_REST_TOKEN="..."  # Optional
supabase secrets set SENTRY_DSN="..."  # Optional
```

### Production (Set LATER)
```bash
# Same secrets, but values point to production services:
supabase secrets set DB_POOL_URL="..."  # Production pooler
supabase secrets set UPSTASH_REDIS_REST_URL="..."  # Production Redis
supabase secrets set SENTRY_DSN="..."  # Production Sentry project
```

---

## Next Milestones After Verification

| Milestone | Focus | Start When |
|-----------|-------|-----------|
| **Milestone 2** | Catalog & Search | Milestone 1 fully passing |
| **Milestone 3** | Orders | Catalog working |
| **Milestone 4** | Payments & Checkout | Orders working |
| **Milestone 5** | UI Polish | Core features working |
| **Play Store Launch** | Release build & submission | Milestone 5 complete, QA passed |

---

## Troubleshooting: Development vs Production

### "Google Sign-In fails in debug build"
- Check debug SHA-1 is in Google Cloud OAuth client
- Check Supabase has Google provider enabled
- Check `.env` SUPABASE_* values are correct

### "Google Sign-In fails in release build"
- Check release SHA-1 is in Google Cloud OAuth client (different from debug!)
- Check Supabase OAuth client supports release SHA-1
- Check app is signed with release keystore

### "JWT token not being stored"
- Check `flutter_secure_storage` platform configs
- Check Android/iOS permissions in manifests
- Run `flutter clean && flutter pub get && flutter run`

### "Backend 401 errors in debug but works in production"
- Check API endpoint in `.env` is correct
- Check JWT interceptor is reading from secure storage
- Check Supabase JWT hook is enabled

---

## Important Dates & Reminders

- **Milestone 1 Target Completion:** Today ✅
- **Play Store Launch Planning:** Milestone 5 onwards
- **Annual Certificate Renewal:** Release keystore expires in 10 years (if you used 10000 days validity)
- **OAuth Credential Rotation:** Consider rotating Client Secret yearly for security

