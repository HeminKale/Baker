# Milestone 1 — Manual Setup & Deployment Steps

**Status:** Code is complete. These are the manual, non-automated steps you must run to deploy Milestone 1 live.

**Time Required:** ~30-45 minutes  
**Prerequisites:** Supabase project, Firebase project, Google Cloud OAuth client, Upstash Redis account (optional), Sentry project (optional)

---

## ⚠️ IMPORTANT: Changing Supabase Account / Data Migration

**If you switch to a different Supabase account or project:**

1. **Run ALL of Phase A (A.1 - A.5) against the NEW Supabase project** — database migrations must be repeated
2. **Re-run all Edge Function secrets** (B.1) — new project has different connection strings
3. **Re-deploy the backend** (B.2) — redeploy to new project's Edge Functions
4. **Update Flutter `.env`** (C.1) — new project has different SUPABASE_URL and SUPABASE_ANON_KEY
5. **Update Google OAuth** (A.3) — register new redirect URL in new project's Supabase Dashboard
6. **Disable JWT verification toggle** (B.2 verification) — turn OFF "Verify JWT with legacy secret" in new project
7. **Flutter won't recognize old data** — if switching projects, old user data won't sync (new project has empty database)

**Reference:** See "Development vs Production Checklist.md" section on "Changing Supabase Account" for full checklist.

---

## Phase A: Database & Supabase Setup

### Step A.1: Run Database Migrations

**What:** Create all Phase 1 database tables and configure the JWT hook.

**Where:** `C:\Users\hemin\OneDrive\Desktop\Android Project\migrations\`

**Files to run (in order):**
```
001_create_roles.sql
002_create_privilege_levels.sql
003_create_privilege_level_permissions.sql
004_create_users.sql
005_create_addresses.sql
006_create_custom_jwt_claims_hook.sql
```

**⚠️ NOTE:** These migrations must be run on EVERY Supabase project (dev, staging, production). If changing Supabase account, repeat this step on the new project.

**How to run:**

Option 1 — **Supabase Dashboard SQL Editor (easiest for beginners):**
1. Go to your Supabase project → SQL Editor
2. Copy contents of `001_create_roles.sql`
3. Paste into the editor and click "Run"
4. Wait for success message
5. Repeat for migrations 002 → 006 in order

Option 2 — **Supabase CLI (recommended):**
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project
supabase link --project-ref <your-project-ref>
supabase db push
```

**Verify:** 
- Supabase Dashboard → Database → Tables → You should see `roles`, `privilege_levels`, `privilege_level_permissions`, `users`, `addresses`
- Query in SQL Editor: `SELECT * FROM roles;` → Should return `customer_individual` and `admin`

---

### Step A.2: Enable JWT Custom Claims Hook

**What:** Wire up the `custom_access_token_hook` function from migration 006 so every issued JWT includes the user's role in `app_metadata.role`.

**How:**
1. Go to **Supabase Dashboard** → **Authentication** → **Hooks**
2. Find the section "Customize Access Token (JWT) Claims"
3. Click **Enable**
4. In the dropdown, select **`public.custom_access_token_hook`**
5. Click **Save**

**Verify:**
- Dashboard shows the hook is enabled and points to `public.custom_access_token_hook`

---

### Step A.3: Configure Google OAuth & Add Redirect URL

**What:** Enable Google Sign-In in Supabase and register the OAuth callback URL.

#### Part 1: Get Google OAuth Credentials from Google Cloud Console

**Prerequisites:**
- Google Cloud project exists (should already be created from planning phase)
- Android bundle ID: `com.chefsandbakers.app`

**How to get Client ID and Client Secret:**

1. **Open Google Cloud Console**
   - Go to: https://console.cloud.google.com
   - Select your Baker Ally project

2. **Get SHA-1 Fingerprint** (required for Android OAuth)
   
   **From Android Studio (fastest method):**
   - Open Android Studio
   - Go to **Tools** → **App Signing** (or search "App Signing")
   - Look for **Debug certificate** → copy the **SHA1** value
   - Format: `AB:CD:EF:12:34:56:...` (remove colons for Google Cloud form)
   
   **Alternative — From Gradle command (if Android Studio not available):**
   ```powershell
   cd "C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter\android"
   .\gradlew signingReport
   # Look for "SHA1:" in the debug output
   ```
   
   **Alternative — From keytool (if Java is installed):**
   ```powershell
   # Find keytool location:
   Get-ChildItem "C:\Program Files\Java" -Recurse -Filter "keytool.exe" 2>$null | Select-Object -First 1 FullName
   
   # If found, run:
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   # Copy the SHA1 value (40 hex characters)
   ```

3. **Create Android OAuth Client in Google Cloud**
   - Go to Google Cloud Console → **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth Client ID**
   - Choose **Application type: Android**
   - Fill in:
     - **Name:** `baker_ally_android` (or any name)
     - **Package name:** `com.chefsandbakers.app`
     - **SHA-1 certificate fingerprint:** Paste the SHA1 from step 2 (without colons)
   - Click **Create**
   - **Copy the Client ID** that appears (ends in `.apps.googleusercontent.com`)
   - Click on the client to view **Client Secret**

4. **Note down:**
   - `CLIENT_ID`: The full ID ending in `.apps.googleusercontent.com`
   - `CLIENT_SECRET`: The secret string shown in the form

**IMPORTANT — Changing Gmail Accounts or New Machine:**
- You'll need a **new SHA-1 fingerprint** (different machine = different debug keystore)
- Re-run step 2 on the new machine
- Create a **new Android OAuth client** in Google Cloud with the new SHA-1
- Get a **new Client ID and Secret**
- Update Supabase (next section) with the new credentials

**IMPORTANT — Changing Supabase Account:**
- You must register the **same** `com.chefsandbakers.app://login-callback` redirect URL in the NEW Supabase project
- You must create a **new Android OAuth client** in Google Cloud (with same SHA-1, same Client Secret)
- If using different Google Cloud project: create entirely new OAuth credentials

---

#### Part 2: Enable Google OAuth in Supabase

**How:**
1. Go to **Supabase Dashboard** → **Authentication** → **Providers** → **Google**
2. Click **Enable**
3. Paste your **Google OAuth Client ID** (from Google Cloud Console)
4. Paste your **Google OAuth Client Secret** (from Google Cloud Console)
5. Click **Save**

Then:
1. Go to **Authentication** → **URL Configuration**
2. Under "Redirect URLs", add:
   ```
   com.chefsandbakers.app://login-callback
   ```
3. Click **Save**

**⚠️ CRITICAL:** This redirect URL is essential for the OAuth flow to work. Without it:
- When you click "Continue with Google" on the app, Chrome opens
- The Google login completes
- Supabase tries to redirect back to `com.chefsandbakers.app://login-callback`
- Since it's not registered, the redirect is rejected
- Chrome shows "This site cannot be reached"

**Verify:**
- Google provider shows "Enabled" in the providers list
- Redirect URL `com.chefsandbakers.app://login-callback` is listed under URL Configuration

---

**Changing Gmail Accounts / New Machine Checklist:**
- [ ] Get new SHA-1 fingerprint from Android Studio/keytool on new machine
- [ ] Create new Android OAuth client in Google Cloud Console with new SHA-1
- [ ] Copy new Client ID and Secret
- [ ] Update Supabase Dashboard with new credentials
- [ ] Test Google Sign-In to verify it works

---

#### Part 3: Release Build Setup (Play Store Deployment)

**IMPORTANT:** The debug SHA-1 fingerprint only works for debug builds. When you release to the Play Store, you need a **separate OAuth client** with the **release SHA-1 fingerprint**.

**Timeline:** Do this when preparing for Play Store launch (Milestone 4-5), not now.

**Process:**

1. **Create a Release Keystore** (one-time, keep it safe)
   ```powershell
   cd "C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter\android\app"
   keytool -genkey -v -keystore baker_ally-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias baker_ally_release
   ```
   - Store the password safely (you'll need it for every release)
   - This creates `baker_ally-release.jks`

2. **Get Release SHA-1 Fingerprint**
   ```powershell
   keytool -list -v -keystore "C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter\android\app\baker_ally-release.jks" -alias baker_ally_release
   # Copy the SHA1 value
   ```

3. **Create Second OAuth Client in Google Cloud**
   - Google Cloud Console → APIs & Services → Credentials
   - Create new Android OAuth client
   - **Name:** `baker_ally_android_release`
   - **Package name:** `com.chefsandbakers.app`
   - **SHA-1 fingerprint:** Paste the RELEASE SHA-1 from step 2
   - Copy the **new Client ID and Secret**

4. **Create `baker_ally_flutter/.env.production`** (for release builds)
   ```
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   API_BASE_URL=https://your-project-ref.supabase.co/functions/v1/api
   ```

5. **Build Release APK/AAB**
   ```powershell
   cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
   flutter build appbundle --release
   # Or for APK: flutter build apk --release
   ```

6. **Update Supabase OAuth Configuration**
   - Option A: Update the existing client to support both debug + release SHA-1s
     - Go to Google Cloud Console → Edit the Android OAuth client
     - Add the release SHA-1 fingerprint as a second entry
   - Option B: Keep separate clients and swap Client ID/Secret in `.env.production`

7. **Upload to Play Store**
   - Go to Google Play Console → Your App → Releases
   - Upload the AAB file
   - Set redirect URL in Supabase (if not already done): `com.chefsandbakers.app://login-callback`

**Summary Table:**

| | Debug Build | Release Build (Play Store) |
|---|---|---|
| **Keystore location** | `~/.android/debug.keystore` (auto) | `android/app/baker_ally-release.jks` (you create) |
| **SHA-1 fingerprint** | From Android Studio | From keytool on release keystore |
| **OAuth Client** | `baker_ally_android` (debug) | `baker_ally_android_release` (release) |
| **When needed** | Now (development) | Later (Play Store launch) |
| **Supabase config** | Update as needed | May need to add release Client ID |

**WARNING:** Do NOT commit the release keystore to git. Add to `.gitignore`:
```
android/app/baker_ally-release.jks
```

---

### Step A.3b: Email OTP Sign-In (Alternative to Google)

**What:** A second sign-in path added during Milestone 1 testing because Google OAuth requires a Web OAuth client (Client ID + Secret) which Android-only clients don't have, and "Access blocked: This app's request is invalid" errors are common until the OAuth consent screen is fully configured/published.

**Good news:** Email OTP needs **no Google Cloud setup at all**. Supabase's Email provider is enabled by default.

**How it works:**
1. On the login screen, tap **Continue with Email**
2. Enter your email address → tap **Send Code**
3. Check your inbox for a 6-digit code (check spam folder if not in inbox)
4. Enter the code → tap **Verify Code**
5. You're signed in — same as Google, a session is created and the app navigates to Home

**Optional — customize the email template:**
1. Supabase Dashboard → **Authentication** → **Email Templates** → **Magic Link**
2. By default this template contains a clickable link. To show a 6-digit code instead, edit the template to include `{{ .Token }}`
3. Save

**Verify:**
- Tapping "Continue with Email" opens a new screen with an email field
- After entering a valid email and tapping Send Code, an email arrives within ~1 minute
- Entering the correct code signs you in; an incorrect/expired code shows an error

**Troubleshooting:**
- **No email arrives:** Check Supabase Dashboard → Authentication → Rate Limits (default is a few emails/hour on the free tier) — also check spam folder
- **"Invalid or expired code":** Codes expire after a few minutes — request a new one via "Use a different email" then re-enter the same email

---

### Step A.4: Create Supabase Storage Bucket (Phase 2 prep)

**What:** Create the `product-images` bucket (used in Phase 2 for catalog images, but created now for consistency).

**How:**
1. Go to **Supabase Dashboard** → **Storage** → **Buckets**
2. Click **New bucket**
3. Name: `product-images`
4. Toggle **Public bucket** → ON
5. Click **Create bucket**

**Verify:**
- Bucket `product-images` appears in the buckets list with "Public" badge

---

### Step A.5: Create Staging Environment (Optional but Recommended)

**What:** Mirror your production Supabase schema to a staging project for testing before production.

**How:**
1. Create a new Supabase project (same process as production)
2. Run the same 6 migrations (A.1) against the staging project
3. Enable the JWT hook (A.2) on staging
4. Enable Google OAuth (A.3) on staging
5. Create `product-images` bucket (A.4) on staging

**Later:** Set up a second `.env.staging` file in Flutter and a second set of Edge Function secrets for staging.

---

## Phase B: Backend Deployment (Supabase Edge Functions)

### Step B.1: Set Edge Function Secrets

**What:** Configure environment variables for the backend (database connection, rate limiting, error tracking, Firebase).

**How:**
1. Open Terminal/PowerShell
2. Navigate to the project:
   ```bash
   cd C:\Users\hemin\OneDrive\Desktop\Android Project
   ```
3. Link Supabase project:
   ```bash
   supabase link --project-ref <your-project-ref>
   ```
4. Set each secret (replace placeholders with real values):
   ```bash
   supabase secrets set DB_POOL_URL="postgresql://postgres.[project-ref]:[password]@aws-[region].pooler.supabase.com:6543/postgres"
   
   supabase secrets set UPSTASH_REDIS_REST_URL="https://[endpoint].upstash.io"
   supabase secrets set UPSTASH_REDIS_REST_TOKEN="[your-token]"
   
   supabase secrets set SENTRY_DSN="https://[key]@sentry.io/[project-id]"
   
   supabase secrets set FIREBASE_PROJECT_ID="[your-firebase-project-id]"
   supabase secrets set FIREBASE_CLIENT_EMAIL="[your-firebase-service-account-email]"
   supabase secrets set FIREBASE_PRIVATE_KEY="[your-firebase-private-key]"
   ```

**Where to find these values:**

| Secret | Where to find |
|--------|---------------|
| `DB_POOL_URL` | Supabase Dashboard → Project Settings → Database → Connection string → Transaction mode pooler (port 6543) |
| `UPSTASH_REDIS_REST_URL` | Upstash Console → Redis instance → REST API → Endpoint URL |
| `UPSTASH_REDIS_REST_TOKEN` | Upstash Console → Redis instance → REST API → Token |
| `SENTRY_DSN` | Sentry → Project Settings → Client Keys (DSN) |
| `FIREBASE_PROJECT_ID` | Firebase Console → Project Settings → Project ID |
| `FIREBASE_CLIENT_EMAIL` | Firebase Console → Service Accounts → Generate new private key (JSON file) → `client_email` field |
| `FIREBASE_PRIVATE_KEY` | Firebase Console → Service Accounts → private key (JSON file) → `private_key` field |

**Which secrets are optional:**
- ✓ `DB_POOL_URL` — **REQUIRED** (backend won't work without DB connection)
- ⚠ `UPSTASH_REDIS_*` — Optional (rate limiting no-ops gracefully without it)
- ⚠ `SENTRY_DSN` — Optional (error tracking no-ops gracefully without it)
- ⚠ `FIREBASE_*` — Not used in Milestone 1 (for phone OTP fast-follow)

**IMPORTANT — Changing Supabase Account:**
- Every Supabase project has different secrets
- `DB_POOL_URL` will be **different** for each project (different connection string)
- You MUST re-run `supabase secrets set` for each project with its own connection string
- Get the connection string from the NEW project's Database settings
- After setting new secrets, re-deploy with `supabase functions deploy api`

**Verify:**
```bash
supabase secrets list
```
Should show your secrets (values hidden for security).

---

### Step B.2: Deploy the Backend

**What:** Deploy the Hono Edge Function to Supabase.

**How:**
1. Terminal/PowerShell (already in project directory):
   ```bash
   supabase functions deploy api
   ```
2. Wait for success message (should say "Deployed Functions on project...")

**Verify:**
```bash
curl https://<your-project-ref>.supabase.co/functions/v1/api/v1/health
```
Should return:
```json
{"data":{"status":"ok"}}
```

**If you get 401 Unauthorized:**
Go to **Supabase Dashboard** → **Edge Functions** → Click `api` → **Settings**
- Find "Verify JWT with legacy secret" toggle
- **Turn it OFF** (it should be gray/disabled)
- Click **Save changes**
- Try the health endpoint again

**Why?** That toggle enforces JWT verification on ALL requests (old/legacy auth method). We use custom auth logic in our code instead (recommended by Supabase). Turning it OFF allows public endpoints like `/health` to work without auth, while protected routes use our custom `authMiddleware`.

---

## Phase C: Flutter App Configuration

### Step C.1: Fill in .env File

**What:** Add your Supabase credentials to the Flutter app.

**Where:** `C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter\.env`

**Current contents (template):**
```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
API_BASE_URL=https://your-project-ref.supabase.co/functions/v1/api
```

**How to fill in:**

| Field | Where to find |
|-------|---------------|
| `SUPABASE_URL` | Supabase Dashboard → Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Project Settings → API → anon public key |
| `API_BASE_URL` | Constructed as `https://<project-ref>.supabase.co/functions/v1/api` |

**Example (filled):**
```
SUPABASE_URL=https://abcdef123456.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
API_BASE_URL=https://abcdef123456.supabase.co/functions/v1/api
```

**Verify:**
- File saved at correct path: `baker_ally_flutter/.env`
- No quotes around values
- All three fields filled

**IMPORTANT — Changing Supabase Account:**
- Every Supabase project has **different** `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- You MUST update `.env` with the NEW project's credentials
- The `API_BASE_URL` changes only if the new project's ref is different
- Run `dart run build_runner build` after changing `.env` to regenerate configs
- App will not work with old `.env` values pointing to old Supabase project

---

### Step C.2: Android & iOS Platform-Specific Setup

**What:** No additional setup required for Milestone 1 (deep links are already configured in code).

**Note:** Firebase Crashlytics + FCM initialization will be done in a later milestone via `flutterfire configure`.

**Verify (Android):**
- Open `android/app/src/main/AndroidManifest.xml`
- Confirm deep link intent-filter exists with `com.chefsandbakers.app://login-callback`

**Verify (iOS):**
- Open `ios/Runner/Info.plist`
- Confirm `CFBundleURLTypes` array contains `com.chefsandbakers.app`

---

## Phase D: Build & Run

### Step D.1: Generate Code (Dart Build Runner)

**What:** Run code generation for `envied`, `riverpod_generator`, `drift`, etc.

**How:**
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
dart run build_runner build --delete-conflicting-outputs
```

**Wait for completion** (should say "Built with build_runner in Xs; wrote X outputs").

**Verify:**
- `lib/core/config/env.g.dart` file is created
- `lib/shared/local_db/app_database.g.dart` file is created
- `lib/features/auth/presentation/auth_provider.g.dart` file is created
- `lib/features/profile/profile_provider.g.dart` file is created

---

### Step D.2: Run Flutter Analyze & Tests

**What:** Verify the Flutter code has no errors.

**How:**
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
flutter analyze
flutter test
```

**Expected output:**
```
flutter analyze:
  Analyzing baker_ally_flutter...
  [X issues found, 0 errors] (should be 0 errors)

flutter test:
  00:00 +0: loading...
  00:00 +1: All tests passed!
```

---

### Step D.3: Start Android Emulator (Or connect device)

**What:** Set up a device/emulator to run the app.

**Option 1 — Android Emulator (Recommended for first test):**

1. Open Android Studio → **Device Manager** (right sidebar)
2. Click **Create Device** (if not already created)
3. Select a device (e.g., Pixel 5) → Click **Next**
4. Select API level (e.g., API 33+) → Click **Next**
5. Click **Finish**
6. Click **Play button** (▶️) to launch
7. Wait 5-10 minutes for Android boot screen

**Space Note:** Each emulator image takes 2-4GB. If you later switch to physical device testing, you can delete emulator images to free up space:
```powershell
rm -r "$env:USERPROFILE\.android\avd\"  # Frees ~2-10GB
```

**Option 2 — Physical Android Device (For later, after testing on emulator):**
- Enable Developer Mode (tap Build Number 7 times in Settings → About)
- Enable USB Debugging (Settings → Developer Options → USB Debugging)
- Connect via USB cable
- Run:
  ```powershell
  cd "C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter"
  flutter devices
  # Should list your device
  flutter run  # Picks your device automatically
  ```
- Can delete emulator images after switching to this method

**Option 3 — iOS Simulator (Mac only):**
```bash
open -a Simulator
```

---

### Step D.4: Run the App (First Time)

**What:** Start the Flutter app on the emulator/device.

**How:**
```bash
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
flutter run
```

**Wait for build to complete** (first run takes ~5-10 minutes).

---

### Step D.5: Rebuild the App (After Code Changes)

**What:** If you've made code changes or want to do a clean rebuild, use these commands.

**Option 1 — Fast Rebuild (Most common):**
```powershell
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
flutter run
```
This hot-reloads (if supported) or rebuilds incrementally. Takes 1-3 minutes.

**Option 2 — Clean Rebuild (After modifying pubspec.yaml, .env, or native code):**
```powershell
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter

# Remove build artifacts
flutter clean

# Get latest dependencies
flutter pub get

# Regenerate code (envied, riverpod, drift, etc.)
dart run build_runner build --delete-conflicting-outputs

# Rebuild the app
flutter run
```
Takes 5-15 minutes.

**Option 3 — Build APK (For sharing/testing on other devices):**
```powershell
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

**Option 4 — Build Release APK (For Play Store submission — Phase 7):**
```powershell
cd C:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**When to use each:**
- **flutter run** — Day-to-day development; works if you didn't change dependencies or config
- **flutter clean** — After merging branches, changing .env, updating pubspec.yaml, or if you get weird errors
- **flutter build apk** — Testing on other Android devices or troubleshooting
- **flutter build appbundle** — Only when submitting to Play Store (Phase 7)

**Expected behavior:**
1. App launches
2. Login screen appears with "Baker Ally" title and "Continue with Google" button
3. Tap button → Google sign-in sheet appears
4. Sign in with a test Google account
5. App loads Home tab with placeholder screens
6. Bottom nav shows 5 tabs (Home, Catalog, Order Again, Brownie Points, Cart)

**Test the flow:**
1. Tap "Cart" tab → should redirect to login (protected route)
2. Go back to Home, tap Google sign-in
3. Tap "Cart" tab again → should load cart placeholder (now authenticated)
4. Tap profile avatar (top right) → should show profile overlay (Phase 5 feature)

---

## Phase E: Verification Checklist

### Backend Verification
- [ ] `GET https://<ref>.supabase.co/functions/v1/api/v1/health` returns 200 with `{data: {status: "ok"}}`
- [ ] `POST /v1/auth/me` with valid Google JWT creates a `users` row and returns role
- [ ] `GET /v1/users/me` returns user profile
- [ ] Invalid/missing JWT returns 401
- [ ] Rate limiting is active (optional, test by sending 25+ requests/min to `/v1/auth/*`)

### Database Verification
- [ ] `SELECT * FROM roles;` returns `customer_individual` and `admin`
- [ ] `SELECT * FROM users WHERE role_id = (SELECT id FROM roles WHERE name = 'customer_individual');` shows created user after first Google sign-in
- [ ] Privileges table is empty (Phase 6 will populate it)

### Flutter Verification
- [ ] App launches without crashes
- [ ] Login screen displays correctly
- [ ] Google Sign-In button works (opens Google auth sheet)
- [ ] After sign-in, JWT is stored in `flutter_secure_storage`
- [ ] Home tab loads without errors
- [ ] Tapping Cart (protected) before login redirects to login
- [ ] Tapping Cart after login loads the tab
- [ ] Logout button (in profile overlay placeholder) clears JWT and redirects to login

### Network Verification (Dio Interceptor)
- [ ] Use Fiddler/Burp/Charles to intercept network traffic
- [ ] Every request to `/v1/*` should have `Authorization: Bearer <JWT>` header
- [ ] Failed auth returns 401 error response

---

## Troubleshooting

### "Database connection refused"
- **Cause:** `DB_POOL_URL` is incorrect or Supabase project is unreachable
- **Fix:** 
  1. Verify `DB_POOL_URL` in `supabase secrets list`
  2. Check Supabase project is active (not deleted)
  3. Re-set the secret: `supabase secrets set DB_POOL_URL="..."`

### "JWT signature verification failed"
- **Cause:** JWT hook not enabled or signed with wrong key
- **Fix:**
  1. Go to Supabase Dashboard → Auth → Hooks
  2. Confirm `custom_access_token_hook` is enabled
  3. Test by signing in again

### "Flutter app shows white screen after login"
- **Cause:** API call to `/v1/auth/me` failed, app stuck on loading
- **Fix:**
  1. Check backend is deployed: `curl https://<ref>.supabase.co/functions/v1/api/v1/health`
  2. Check `.env` values are correct (SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL)
  3. Regenerate code: `dart run build_runner build --delete-conflicting-outputs`
  4. Restart app: `flutter run` (stop with Ctrl+C first)

### "envied generation failed"
- **Cause:** `.env` file is missing or `.env.local` exists (git ignores `.env` by default)
- **Fix:**
  1. Verify `.env` file exists at project root
  2. Delete `.env.local` if it exists
  3. Re-run: `dart run build_runner build --delete-conflicting-outputs`

### "Rate limiting returns 429 (Too Many Requests)"
- **Cause:** Upstash Redis secrets are set (optional feature active)
- **Fix:** Either
  - Wait 60 seconds and retry, or
  - Remove Upstash secrets: `supabase secrets unset UPSTASH_REDIS_REST_URL UPSTASH_REDIS_REST_TOKEN`

---

## Next Steps After Verification

Once all verification checks pass:

1. **Commit the code** (if not already done):
   ```bash
   git add -A
   git commit -m "Milestone 1 complete: Foundation (Auth + DB + Backend)"
   git push
   ```

2. **Document in Milestone 1 README** (already done, but update if any changes):
   - List any environment-specific configs
   - Document any known issues
   - Add performance notes

3. **Begin Milestone 2** (Catalog & Search):
   - Read `Planning docs/Phase_Plan_Technical.md` Phase 2 section
   - Start with catalog DB tables (migrations 006-011)
   - Build catalog API endpoints

---

## Support & Questions

For issues not covered above:
1. Check `Milestone readme/Milestone 1.md` for scope and architecture decisions
2. Review `Planning docs/Phase_Plan_Technical.md` for what Phase 1 includes
3. Check backend error logs: Supabase Dashboard → Edge Functions → `api` → Logs
4. Check Flutter logs: Terminal output from `flutter run`
