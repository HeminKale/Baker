# Flutter Library Stack — Complete Reference

> Mobile app stack for iOS + Android (non-fintech/health)
> Last updated: July 2026

---

## Table of Contents

1. [State Management + DI — Riverpod](#1-state-management--di--riverpod)
2. [Navigation — GoRouter](#2-navigation--gorouter)
3. [Networking — Dio](#3-networking--dio)
4. [Local Database — Drift](#4-local-database--drift)
5. [Secure Storage — flutter_secure_storage](#5-secure-storage--flutter_secure_storage)
6. [Images — cached_network_image](#6-images--cached_network_image)
7. [Push Notifications — firebase_messaging](#7-push-notifications--firebase_messaging)
8. [Analytics — PostHog](#8-analytics--posthog)
9. [Crash Reporting — Firebase Crashlytics](#9-crash-reporting--firebase-crashlytics)
10. [Forms — flutter_form_builder](#10-forms--flutter_form_builder)
11. [Env Config — envied](#11-env-config--envied)
12. [Deep Linking — app_links](#12-deep-linking--app_links)
13. [In-App Purchases — purchases_flutter (RevenueCat)](#13-in-app-purchases--purchases_flutter-revenuecat)
14. [Background Tasks — workmanager](#14-background-tasks--workmanager)
15. [Auth — supabase_flutter](#15-auth--supabase_flutter)
16. [Quick Reference Table](#quick-reference-table)
17. [pubspec.yaml Dependencies](#pubspecyaml-dependencies)

---

## 1. State Management + DI — Riverpod

**Package:** `flutter_riverpod`, `riverpod_annotation`

### What it is
A system that manages your app's data and shares it across screens. Also acts as a Dependency Injection (DI) container — it creates and provides services (API clients, database, etc.) wherever they're needed.

### The problem it solves
Without it, sharing data between screens means passing it manually through every widget — messy and breaks fast in real apps.

### What it does
- Holds your app's state (logged-in user, fetched data, loading/error status)
- Makes that state available to any screen without manual prop-drilling
- Creates and injects services (repositories, API clients) anywhere in the app
- Automatically rebuilds only the widgets that depend on changed state

### Why Riverpod over alternatives
| Alternative | Problem |
|---|---|
| setState | Doesn't scale beyond one screen |
| Provider | Older, less type-safe, being replaced by Riverpod |
| Bloc | More boilerplate, steeper learning curve |
| GetX | Anti-pattern, hard to test |

### Basic example
```dart
// Define state
final userProvider = FutureProvider<User>((ref) async {
  return ref.read(userRepositoryProvider).getCurrentUser();
});

// Use in any widget
class ProfileScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return user.when(
      data: (u) => Text(u.name),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

---

## 2. Navigation — GoRouter

**Package:** `go_router`

### What it is
Controls how users move between screens. URL-based routing system built on top of Flutter's Navigator 2.0.

### The problem it solves
Flutter's built-in navigation breaks down in real apps — back button behavior, nested routes, tabs, and deep links all become painful without a proper router.

### What it does
- Defines named routes (`/home`, `/profile/:id`, `/settings`)
- Handles back button correctly on both Android and iOS
- Supports nested navigation (tabs with their own navigation stacks)
- Guards routes (redirect unauthenticated users to `/login`)
- Works with deep links via `app_links`

### Basic example
```dart
final router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
    GoRoute(
      path: '/profile/:userId',
      builder: (_, state) => ProfileScreen(
        userId: state.pathParameters['userId']!,
      ),
    ),
  ],
);
```

---

## 3. Networking — Dio

**Package:** `dio`

### What it is
An HTTP client — the layer that sends requests from your Flutter app to your backend API.

### The problem it solves
Flutter's built-in `http` package is too bare-bones for production apps. Attaching tokens, handling errors, retrying failed requests all need to be built from scratch.

### What it does
- Sends GET / POST / PUT / DELETE requests to your backend
- Interceptors — middleware that runs on every request/response
  - Attaches JWT token to every request automatically
  - Catches 401 errors and refreshes the token transparently
- Handles timeouts, cancellation, and upload progress

### Basic example
```dart
// Setup with interceptor
final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl))
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = secureStorage.read('jwt');
        options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ),
  );

// Make a request
final response = await dio.get('/v1/users/me');
```

---

## 4. Local Database — Drift

**Package:** `drift`, `drift_flutter`

### What it is
A local SQLite database that lives on the user's phone. Enables offline-first functionality.

### The problem it solves
If your app only works with internet, users on slow connections or offline get a broken experience. Drift stores data locally so the app works regardless of connectivity.

### What it does
- Stores structured data locally on device
- Caches API responses so screens load instantly (no loading spinners on repeat visits)
- Reactive streams — UI automatically updates when local data changes
- Syncs with backend when connection is restored

### Real-world example
```
User opens app on a plane
→ App loads feed from local Drift database instantly
→ When connection restores, Drift syncs new data from backend
→ UI updates automatically via streams
```

### Why Drift over alternatives
| Alternative | Problem |
|---|---|
| SharedPreferences | Key-value only, not for structured data |
| Hive | No relations, weaker query support |
| sqflite | Manual SQL strings, no type safety |
| Drift | Type-safe, reactive, compile-time query validation |

---

## 5. Secure Storage — flutter_secure_storage

**Package:** `flutter_secure_storage`

### What it is
An encrypted key-value store. Uses the device's hardware security module to store sensitive values.

### The problem it solves
SharedPreferences stores data as plain text — readable by anyone with file access to the device. Auth tokens stored there can be stolen.

### What it stores
- JWT access tokens
- Refresh tokens
- Any credential that must survive app restarts

### How it works under the hood
| Platform | Mechanism |
|---|---|
| iOS | Keychain Services |
| Android | Android Keystore + EncryptedSharedPreferences |

### Basic example
```dart
const storage = FlutterSecureStorage();

// Write
await storage.write(key: 'jwt', value: token);

// Read
final token = await storage.read(key: 'jwt');

// Delete on logout
await storage.delete(key: 'jwt');
```

---

## 6. Images — cached_network_image

**Package:** `cached_network_image`

### What it is
Loads images from URLs and caches them on device so they don't re-download on every view.

### The problem it solves
Without caching, every time a user scrolls past a profile picture, your app re-downloads it. On a list of 50 users, that's 50 network requests every scroll — slow, wastes data, and looks broken on poor connections.

### What it does
- Downloads image once, caches to disk
- Serves from cache on subsequent views (instant load)
- Shows placeholder widget while loading
- Shows error widget if image fails to load

### Basic example
```dart
CachedNetworkImage(
  imageUrl: user.avatarUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.person),
  width: 48,
  height: 48,
)
```

---

## 7. Push Notifications — firebase_messaging

**Package:** `firebase_messaging`

### What it is
The Flutter integration for Firebase Cloud Messaging (FCM) — Google's free push notification infrastructure that works on both iOS and Android.

### How the full flow works
```
Your backend
  → sends message to FCM (Google's servers)
    → FCM delivers to user's device
      → firebase_messaging receives it in your app
        → you show a notification or handle silently
```

### What it handles
- Foreground notifications (app is open and visible)
- Background notifications (app is minimized)
- Terminated notifications (app is fully closed)
- Notification taps — open app to specific screen via GoRouter

### Why FCM
- Free with no limits
- Single integration covers both iOS and Android
- Maintained by Google
- Required for any app that needs real-time alerts (messages, orders, reminders)

### Basic example
```dart
FirebaseMessaging.onMessage.listen((message) {
  // App is open — show in-app banner
  showInAppNotification(message.notification?.title);
});

FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // User tapped notification — navigate to screen
  router.push(message.data['route']);
});
```

---

## 8. Analytics — PostHog

**Package:** `posthog_flutter`

### What it is
Tracks what users actually do in your app — which screens they visit, where they drop off, which features they use.

### The problem it solves
Without analytics you are guessing what to build next. Analytics shows you reality.

### What it tells you
- Most/least visited screens
- Funnel analysis (how many users complete onboarding vs drop off at step 2)
- Feature adoption (is anyone using that feature you spent 2 weeks building?)
- Retention (do users come back after day 1, day 7, day 30?)

### Why PostHog over Firebase Analytics
| | PostHog | Firebase Analytics |
|---|---|---|
| Open source | Yes | No |
| Self-hostable | Yes | No |
| Session recording | Yes | No |
| Feature flags | Yes | No |
| SQL access to data | Yes | No |
| Privacy-friendly | Yes | Limited |

### Basic example
```dart
// Track a screen view
Posthog().screen('ProfileScreen');

// Track an event
Posthog().capture(
  eventName: 'purchase_completed',
  properties: {'plan': 'pro', 'amount': 9.99},
);
```

---

## 9. Crash Reporting — Firebase Crashlytics

**Package:** `firebase_crashlytics`

### What it is
Automatically captures crashes and unhandled errors in your production app and reports them to a dashboard.

### The problem it solves
Without crash reporting, you only find out about bugs when users complain (most don't — they just delete the app). Crashlytics tells you automatically.

### What it captures
- Stack trace of exactly where the crash happened
- Device info (OS version, device model)
- How many users were affected
- Steps leading up to the crash (breadcrumbs)

### What you get in the dashboard
- Real-time crash rate
- Alerts when crash rate spikes
- Issue grouping (same crash from different users grouped together)
- Version comparison (did this crash get worse after your last release?)

### Setup
```dart
// In main.dart — catches all Flutter errors
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

// Catches errors outside Flutter framework
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

---

## 10. Forms — flutter_form_builder

**Package:** `flutter_form_builder`, `form_builder_validators`

### What it is
Pre-built, validated form fields. Covers the most common input types out of the box.

### The problem it solves
Every form field needs validation logic — "is this email valid?", "is this field empty?", "is this password 8+ characters?" — written manually from scratch every time. That's hundreds of lines of boilerplate.

### What it provides
- Text fields, email fields, password fields
- Dropdowns, radio buttons, checkboxes
- Date/time pickers
- Sliders, ratings
- Built-in validators (required, email, min length, regex, etc.)
- Single call to validate entire form

### Basic example
```dart
final _formKey = GlobalKey<FormBuilderState>();

FormBuilder(
  key: _formKey,
  child: Column(children: [
    FormBuilderTextField(
      name: 'email',
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(),
        FormBuilderValidators.email(),
      ]),
    ),
    FormBuilderTextField(
      name: 'password',
      obscureText: true,
      validator: FormBuilderValidators.minLength(8),
    ),
    ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.saveAndValidate()) {
          final values = _formKey.currentState!.value;
          // submit form
        }
      },
      child: Text('Submit'),
    ),
  ]),
)
```

---

## 11. Env Config — envied

**Package:** `envied`, `envied_generator`

### What it is
Reads your `.env` file at build time and generates type-safe Dart code. Keeps config values out of your source code.

### The problem it solves
Hardcoding API URLs and keys directly in code means they end up in your git history and are visible to anyone with repo access.

### Important limitation
`envied` is **build-time only** — values are compiled into the binary. It is for non-sensitive config like API base URLs and public keys. Never put database passwords or payment secret keys in the Flutter app — those live on your backend only.

### What belongs in Flutter .env vs backend
| Value | Where it lives |
|---|---|
| API base URL | Flutter `.env` via envied |
| PostHog public key | Flutter `.env` via envied |
| Database password | Backend env vars (Railway/Fly.io secrets) |
| Payment secret key | Backend env vars only |
| JWT secret | Backend env vars only |

### Setup
```dart
// .env
API_BASE_URL=https://api.yourapp.com
POSTHOG_KEY=phc_xxxxxxxxxxxx

// env.dart (generated)
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _Env.apiBaseUrl;

  @EnviedField(varName: 'POSTHOG_KEY')
  static const String posthogKey = _Env.posthogKey;
}
```

---

## 12. Deep Linking — app_links

**Package:** `app_links`

### What it is
Intercepts URLs and routes them into your Flutter app, navigating directly to the right screen.

### The problem it solves
Without deep linking, any link to your content opens a browser instead of your app. Users lose context and your app feels disconnected.

### Use cases
- Email verification: `yourapp.com/verify?token=abc` → opens app, verifies email
- Invite links: `yourapp.com/invite/xyz` → opens app at invite screen
- Shared content: `yourapp.com/posts/123` → opens app at that post
- Password reset: `yourapp.com/reset?token=abc` → opens app at reset screen

### How it works with GoRouter
```dart
// In main.dart
final appLinks = AppLinks();

appLinks.uriLinkStream.listen((uri) {
  // Hand the deep link URL to GoRouter
  router.go(uri.path, extra: uri.queryParameters);
});
```

---

## 13. In-App Purchases — purchases_flutter (RevenueCat)

**Package:** `purchases_flutter`

### What it is
A unified SDK that handles subscriptions and one-time purchases through both the Apple App Store and Google Play Store.

### The problem it solves
Apple and Google each have completely different, complex purchase APIs. Building both from scratch is weeks of work, easy to get wrong, and if you get it wrong you lose revenue or get rejected from the store.

### What RevenueCat handles
- Single API for both App Store and Play Store
- Subscription management (active, expired, cancelled, in grace period)
- Receipt validation (prevents users from faking purchases)
- Subscription upgrades and downgrades
- Free trial logic
- Restoring purchases on new devices

### What you get in the RevenueCat dashboard
- Monthly Recurring Revenue (MRR)
- Churn rate
- Trial conversion rate
- Revenue by country/platform

### Basic example
```dart
// Initialize
await Purchases.configure(PurchasesConfiguration(Env.revenueCatKey));

// Fetch offerings (your subscription plans)
final offerings = await Purchases.getOfferings();
final monthly = offerings.current?.monthly;

// Purchase
await Purchases.purchasePackage(monthly!);

// Check subscription status
final info = await Purchases.getCustomerInfo();
final isProUser = info.entitlements.active.containsKey('pro');
```

---

## 14. Background Tasks — workmanager

**Package:** `workmanager`

### What it is
Schedules and runs Dart code even when your app is closed or in the background, within OS-imposed restrictions.

### The problem it solves
iOS and Android both aggressively restrict background execution to save battery. `workmanager` works within those restrictions in a cross-platform way, so you don't have to implement separate solutions per platform.

### Use cases
- Periodic sync of Drift local database with backend
- Uploading queued actions when internet reconnects
- Downloading content in the background
- Sending analytics events that were queued offline

### OS constraints to know
| Platform | Minimum interval | Guaranteed timing? |
|---|---|---|
| Android | 15 minutes | Near-guaranteed |
| iOS | ~15 minutes | Best-effort only |

iOS does not guarantee exact timing — the OS decides when to run background tasks based on device usage patterns.

### Basic example
```dart
// Register task
Workmanager().registerPeriodicTask(
  'sync-task',
  'syncWithBackend',
  frequency: Duration(hours: 1),
  constraints: Constraints(networkType: NetworkType.connected),
);

// Handle task execution (top-level function, outside any class)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'syncWithBackend') {
      await SyncService().sync();
    }
    return Future.value(true);
  });
}
```

---

## Quick Reference Table

| Library | Package | One job |
|---|---|---|
| Riverpod | `flutter_riverpod` | Shares and manages data across your whole app |
| GoRouter | `go_router` | Controls screen navigation and deep links |
| Dio | `dio` | Talks to your backend API |
| Drift | `drift` | Stores data locally for offline use |
| flutter_secure_storage | `flutter_secure_storage` | Keeps auth tokens encrypted on device |
| cached_network_image | `cached_network_image` | Loads and caches images efficiently |
| firebase_messaging | `firebase_messaging` | Delivers push notifications |
| PostHog | `posthog_flutter` | Tells you how users use your app |
| Firebase Crashlytics | `firebase_crashlytics` | Tells you when and why the app crashes |
| flutter_form_builder | `flutter_form_builder` | Builds validated forms without boilerplate |
| envied | `envied` | Keeps config values out of source code |
| app_links | `app_links` | Makes URLs open your app at the right screen |
| purchases_flutter | `purchases_flutter` | Handles subscriptions and payments |
| workmanager | `workmanager` | Runs tasks when the app is in the background |
| supabase_flutter | `supabase_flutter` | Auth only — OTP, Google sign-in, issues JWT for Dio |

---

## 15. Auth — supabase_flutter

**Package:** `supabase_flutter`

### What it is
The official Flutter SDK for Supabase. In Baker Ally it is used **exclusively for authentication** — signing users in and getting a JWT. It does not query the database directly.

### The problem it solves
Supabase Auth (OTP, Google OAuth, Apple Sign-In) is a managed service — you cannot trigger it via a plain HTTP call from Dio. The SDK is the only way to initiate the auth flow and receive the signed JWT back.

### What it does in Baker Ally (auth only)
```dart
// Initialise once in main.dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);

// OTP login (most common in India)
await supabase.auth.signInWithOtp(phone: '+919876543210');

// Verify OTP
await supabase.auth.verifyOTP(phone: '+91...', token: '123456', type: OtpType.sms);

// Google Sign-In
await supabase.auth.signInWithOAuth(OAuthProvider.google);

// Get the JWT after login — hand it to Dio's interceptor
final jwt = supabase.auth.currentSession?.accessToken;

// Listen to auth state changes
supabase.auth.onAuthStateChange.listen((event) {
  if (event.event == AuthChangeEvent.signedOut) {
    router.go('/login');
  }
});

// Sign out
await supabase.auth.signOut();
```

### What it does NOT do in Baker Ally
```dart
// ❌ Never query the database directly from Flutter
await supabase.from('products').select();   // Don't do this

// ❌ Never call storage directly from the customer app
await supabase.storage.from('images').upload(...);  // Don't do this

// ✅ All business logic goes through Dio → Hono backend
final response = await dio.get('/products');
```

### Why the split is this way

| Action | Who handles it | Why |
|---|---|---|
| Login / OTP / Google sign-in | `supabase_flutter` | Auth is a managed service — only the SDK can trigger it |
| Get JWT | `supabase_flutter` | JWT is issued by Supabase Auth after login |
| Products, cart, orders | `Dio → Hono` | Business logic (payment verification, stock check) must run on backend |
| Payments | `Dio → Hono → Razorpay` | Secret keys must never be in Flutter |
| Image uploads (admin app) | `Dio → Hono` | Backend validates before storing |

### How the JWT flows into Dio
Once `supabase_flutter` gives you the JWT, Dio's interceptor (already configured in your stack) attaches it to every request automatically:

```dart
// In Dio setup — runs on every request
onRequest: (options, handler) {
  final jwt = supabase.auth.currentSession?.accessToken;
  if (jwt != null) {
    options.headers['Authorization'] = 'Bearer $jwt';
  }
  handler.next(options);
}
```

From that point forward, every Dio call to Hono carries the JWT. Hono's `authMiddleware` verifies it on every protected route.

### Token refresh
Supabase Auth JWTs expire after 1 hour. `supabase_flutter` handles refresh automatically — Dio always reads the current session token, so refresh is transparent.

---

## 16. Quick Reference Table

| Library | Package | One job |
|---|---|---|
| Riverpod | `flutter_riverpod` | Shares and manages data across your whole app |
| GoRouter | `go_router` | Controls screen navigation and deep links |
| Dio | `dio` | Talks to your backend API |
| Drift | `drift` | Stores data locally for offline use |
| flutter_secure_storage | `flutter_secure_storage` | Keeps auth tokens encrypted on device |
| cached_network_image | `cached_network_image` | Loads and caches images efficiently |
| firebase_messaging | `firebase_messaging` | Delivers push notifications |
| PostHog | `posthog_flutter` | Tells you how users use your app |
| Firebase Crashlytics | `firebase_crashlytics` | Tells you when and why the app crashes |
| flutter_form_builder | `flutter_form_builder` | Builds validated forms without boilerplate |
| envied | `envied` | Keeps config values out of source code |
| app_links | `app_links` | Makes URLs open your app at the right screen |
| purchases_flutter | `purchases_flutter` | Handles subscriptions and payments |
| workmanager | `workmanager` | Runs tasks when the app is in the background |
| supabase_flutter | `supabase_flutter` | Auth only — OTP, Google sign-in, issues JWT for Dio |
| razorpay_flutter | `razorpay_flutter` | Opens Razorpay payment sheet for checkout |
| speech_to_text | `speech_to_text` | On-device voice input for search bar |

---

## 17. pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State + DI
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Navigation
  go_router: ^14.8.1

  # Networking
  dio: ^5.7.0

  # Local database
  drift: ^2.23.1
  drift_flutter: ^0.2.4

  # Secure storage
  flutter_secure_storage: ^9.2.2

  # Images
  cached_network_image: ^3.4.1

  # Firebase
  firebase_core: ^3.12.1
  firebase_messaging: ^15.2.5
  firebase_crashlytics: ^4.3.5
  firebase_analytics: ^11.4.5

  # Analytics
  posthog_flutter: ^4.4.2

  # Forms
  flutter_form_builder: ^9.4.0
  form_builder_validators: ^11.1.0

  # Env config
  envied: ^0.5.4

  # Deep linking
  app_links: ^6.4.0

  # In-app purchases
  purchases_flutter: ^8.5.0

  # Background tasks
  workmanager: ^0.5.2

  # Auth
  supabase_flutter: ^2.5.0

  # Payments
  razorpay_flutter: ^1.3.7

  # Voice search
  speech_to_text: ^6.6.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  riverpod_generator: ^2.6.3
  envied_generator: ^0.5.4
  drift_dev: ^2.23.1
```

---

*This document covers the Flutter frontend library stack only. For backend stack (Hono, Drizzle, Supabase Edge Functions, etc.) see [backend_stack.md](backend_stack.md).*
