# Developer Environment Setup

> Baker Ally — Minimal toolchain for Milestones 1–7
> Last updated: July 2026

---

## Overview

This document describes the minimal developer toolchain required to build Baker Ally across all 7 milestones. You test against **real Supabase staging project** (cloud), not a local setup.

**Total install time:** ~25 minutes  
**Restart required:** No (already done)

---

## Toolchain Summary

| Tool | Version | What It Does | Required For |
|---|---|---|---|
| **Flutter SDK** | 3.44.5 | Write + build the mobile app (iOS + Android) | Milestones 1–7 |
| **Dart** | 3.12.2 | Flutter's programming language | Milestones 1–7 |
| **Android Studio** | 2026.1.1.10 | Android SDK + emulator for testing | Milestones 1–7 |
| **Supabase CLI** | 2.109.1 | Manage database migrations + local dev stack | Milestones 1–7 |
| **Deno** | 2.9.1 | Test Edge Functions locally before deploying | Milestones 4–7 |

---

## What Each Tool Does (Architecture Context)

### Flutter SDK + Dart
- Compiles Dart code into iOS/Android apps
- Runs the app on Android emulator (local testing)
- `flutter doctor` verifies the entire toolchain health
- Location: `C:\src\flutter`

### Android Studio + Android SDK
- Provides the Android SDK (platform tools, system images, etc.)
- Runs Android emulator to test the app locally
- Launched via Android Studio setup (GUI)
- You'll do this once for initial config, then rarely touch it again

### Supabase CLI
- Manages database migrations (create tables, indexes, etc.)
- Runs commands to set up local Supabase stack (optional for Phases 1–3)
- Used to push migrations to staging/production
- Installed via npm (Node.js package manager)

### Deno
- Runtime for Supabase Edge Functions (backend code)
- Used to test Edge Functions locally before deployment
- Only needed starting Phase 4 when you build payment/webhook handlers
- Can skip for Phases 1–3 (test against staging Edge Functions instead)

---

## Installation Record

**Date installed:** July 8, 2026  
**Installed by:** User  
**Machine:** Windows 11 Home Single Language  

### Commands Run

```powershell
# 1. Flutter SDK (git clone)
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter

# 2. Android Studio (winget)
winget install -e --id Google.AndroidStudio

# 3. Supabase CLI (npm)
npm install -g supabase

# 4. Deno (winget)
winget install -e --id DenoLand.Deno

# 5. Add Flutter to User PATH
$flutterPath = "C:\src\flutter\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = $currentPath + ";" + $flutterPath
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
```

---

## Verification

All tools verified working on 2026-07-08:

```
flutter --version
→ Flutter 3.44.5 • channel stable

dart --version
→ Dart SDK version: 3.12.2 (stable)

supabase --version
→ 2.109.1

deno --version
→ deno 2.9.1 (stable)
```

---

## Testing Against Supabase

### Development Workflow

1. **Write migrations** locally (SQL files in `/migrations/` folder)
2. **Test migrations** against staging Supabase project:
   ```powershell
   supabase link --project-ref [your-staging-project-id]
   supabase db push
   ```
3. **Test Flutter app** locally against staging Supabase:
   - Set `.env.local` with staging Supabase URL + keys
   - Run app on Android emulator
4. **Test Edge Functions** against staging (or locally with Deno for Phases 4+)

### Why Not Local Supabase?

You already have Supabase staging + production projects. Using them directly:
- Eliminates complexity (no Docker, no WSL2, no local PostgreSQL)
- Tests against the exact same system you'll deploy to
- Faster iteration (no local DB setup overhead)
- Staging is treated as your "dev environment" — safe to destroy/reset data

---

## Android Emulator Setup (One-Time)

After installing Android Studio, you must set up the emulator once:

1. Open **Android Studio** (start menu or `android-studio` command)
2. Complete the setup wizard (download SDK, create emulator image)
3. Once done, you can launch the emulator from Android Studio or via CLI:
   ```powershell
   flutter emulators --launch Pixel_6_API_33
   ```

This is a one-time ~10 min setup. After that, `flutter run` on Android emulator is seamless.

---

## Troubleshooting

### "flutter: command not found"
- Close all PowerShell windows completely
- Open a fresh PowerShell window
- Run `flutter --version`
- If still fails: `C:\src\flutter\bin\flutter.bat --version` (full path)

### "android: command not found"
- Android SDK tools are in `C:\Users\[username]\AppData\Local\Android\Sdk\tools\bin`
- Android Studio setup wizard adds this to PATH automatically
- If missing: run Android Studio setup wizard again

### Flutter doctor shows warnings
```powershell
flutter doctor
```
This tool audits your setup and suggests fixes. Most warnings are safe to ignore for app development; focus on the error messages (red).

---

## Updating Tools Later

### Flutter (stay on stable channel)
```powershell
cd C:\src\flutter
git pull origin stable
flutter upgrade
```

### Supabase CLI
```powershell
npm install -g supabase@latest
```

### Deno
```powershell
winget upgrade -e --id DenoLand.Deno
```

---

## Next Steps

With the toolchain ready, proceed to **Milestone 1 scaffolding**:
- Create Flutter project structure
- Set up Riverpod + GoRouter + Dio
- Create Supabase migrations (Phase 1 tables)
- Scaffold Hono backend
- Build OTP + Google Sign-In flows

See `Milestone 1/README.md` for detailed Phase 1 work.
