# Baker Ally — Profile & Account Architecture
> Triggered by tapping the profile avatar (top-right corner of any screen).
> Not a bottom nav tab — opens as a bottom sheet overlay.
> Last updated: July 2026

---

## How It Opens

Tapping the avatar on the top-right of any screen slides up a bottom sheet covering **90% of the screen height**. A drag handle at the top allows dismissal. Background is dimmed.

---

## UI — Profile Bottom Sheet

```
┌─────────────────────────────────────────────────┐
│              ─────  (drag handle)                │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  [  Avatar  ]  Priya Sharma              │   │
│  │               Sunshine Cakes & Co.       │   │
│  │               +91 98765 43210            │   │
│  │               GSTIN 27ABCDE1234F1Z5      │   │
│  │                              [Edit →]    │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  📦  Your Orders                      ›  │   │
│  ├──────────────────────────────────────────┤   │
│  │  🚚  Order Status                     ›  │   │
│  ├──────────────────────────────────────────┤   │
│  │  ❤️  Your Wishlist                    ›  │   │
│  ├──────────────────────────────────────────┤   │
│  │  🧾  Receipts & Invoices              ›  │   │
│  ├──────────────────────────────────────────┤   │
│  │  📍  Delivery Addresses               ›  │   │
│  ├──────────────────────────────────────────┤   │
│  │  🍰  Recipes                          ›  │   │
│  ├──────────────────────────────────────────┤   │
│  │  📞  Contact Us                       ›  │   │
│  ├──────────────────────────────────────────┤   │
│  │  ❓  Help & Support                   ›  │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  🚪  Log Out                             │   │  ← destructive — separate from menu list
│  └──────────────────────────────────────────┘   │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## Profile Card (top section)

Shows the logged-in user's info at a glance:

| Field | Source | Editable |
|---|---|---|
| Avatar | `users.avatar_url` (Supabase Storage) | Yes — tap opens image picker |
| Full name | `users.full_name` | Via Edit screen |
| Business name | `users.business_name` | Via Edit screen |
| Phone | `users.phone` (from Supabase Auth OTP) | Read-only |
| GSTIN | `users.gstin` | Via Edit screen — optional |

Tapping **[Edit →]** navigates to `/profile/edit` — a separate full screen (not nested in the sheet).

---

## Menu Items — What Each Does

### 📦 Your Orders → `/orders`
Full order history list. Most recent first.

```
┌─────────────────────────────────────────────────┐
│ ← Back          Your Orders                     │
│                                                  │
│  ORD-3391 · 2 Jul 2026 · 6 items        ›       │
│  ✅ Delivered · ₹18,420                          │
│  ─────────────────────────────────────────────  │
│  ORD-3350 · 24 Jun 2026 · 4 items       ›       │
│  ✅ Delivered · ₹9,260                           │
│  ─────────────────────────────────────────────  │
│  ORD-3312 · 17 Jun 2026 · 8 items       ›       │
│  🚚 In Transit · ₹22,110                         │
└─────────────────────────────────────────────────┘
```

Each row taps to `/orders/:orderId` — order detail.

---

### 🚚 Order Status → `/orders` (active filter)

Same as Your Orders but pre-filtered to `status IN (confirmed, processing, shipped)`. Shows only active/in-progress orders.

```
┌─────────────────────────────────────────────────┐
│ ← Back         Order Status                     │
│                                                  │
│  ORD-3312 · 17 Jun 2026                          │
│  🚚 In Transit                                   │
│  Carrier: Delhivery · AWB: 1234567890            │
│  Est. delivery: 9 Jul 2026                       │
│  [Track Order →]                                 │
└─────────────────────────────────────────────────┘
```

---

### ❤️ Your Wishlist → `/wishlist`

Products the user has saved. Grid layout — same product tile as catalog.

```
┌─────────────────────────────────────────────────┐
│ ← Back          Your Wishlist                   │
│                                                  │
│  [product tile]  [product tile]                  │
│  [product tile]  [product tile]                  │
│                                                  │
│  (empty state: "No saved items yet")             │
└─────────────────────────────────────────────────┘
```

Each tile has a filled heart icon. Tap heart → removes from wishlist.
Tap tile → product detail.

---

### 🧾 Receipts & Invoices → `/receipts`

List of all paid orders with downloadable invoice.

```
┌─────────────────────────────────────────────────┐
│ ← Back      Receipts & Invoices                 │
│                                                  │
│  INV-3391 · 2 Jul 2026 · ₹18,420   [Download]  │
│  INV-3350 · 24 Jun 2026 · ₹9,260   [Download]  │
└─────────────────────────────────────────────────┘
```

Download generates a PDF invoice — Hono Edge Function renders it server-side and returns a signed Supabase Storage URL.

---

### 📍 Delivery Addresses → `/addresses`

All saved addresses. Default marked with a pin badge.

```
┌─────────────────────────────────────────────────┐
│ ← Back      Delivery Addresses    [+ Add New]   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  📍 Home  (Default)             [Edit]   │   │
│  │  123, MG Road, Flat 4B                   │   │
│  │  Mumbai – 400001                         │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │  🏭 Bakery Studio               [Edit]   │   │
│  │  456, Link Road, Shop 12                 │   │
│  │  Mumbai – 400053                         │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

Add/Edit address opens a form screen using `flutter_form_builder`:

```
Fields:
  Label (Home / Bakery / Other)    → text
  Full Name                        → text, required
  Phone                            → phone, required
  Address Line 1                   → text, required
  Address Line 2                   → text, optional
  City                             → text, required
  State                            → dropdown, required
  Pincode                          → number (6 digits), required
  Set as default?                  → toggle
```

---

### 🍰 Recipes → `/recipes`

Static or CMS-driven content screen. Bakers can browse recipe content from Baker Ally. Architecture: initially static markdown/JSON served from Hono, later upgradeable to a CMS.

---

### 📞 Contact Us → `/contact`

Simple screen with:
- WhatsApp chat button (opens Interakt chat or wa.me link)
- Email address
- Support hours

---

### ❓ Help & Support → `/help`

FAQ accordion + link to raise a support ticket (email/WhatsApp).

---

### 🚪 Log Out

**Shown separately at the bottom — not grouped with menu items** (destructive action).

On tap:
1. Show confirmation dialog: "Are you sure you want to log out?"
2. On confirm:
   - Call `supabase.auth.signOut()`
   - Clear `flutter_secure_storage` (JWT deleted)
   - Clear Drift local cache (cart, orders, catalog)
   - Navigate to `/login`, replace history (no back)

---

## Edit Profile Screen → `/profile/edit`

```
┌─────────────────────────────────────────────────┐
│ ← Back          Edit Profile                    │
│                                                  │
│          [  Avatar  ]                            │
│           Tap to change                          │
│                                                  │
│  Full Name  ___________________________          │
│  Business Name  _______________________          │
│  GSTIN  ______________________________           │
│  (optional — for customer's own records)         │
│  Phone  ______________________________           │
│  (grayed out — tied to OTP login, not editable)  │
│                                                  │
│  [  Save Changes  ]                              │
└─────────────────────────────────────────────────┘
```

Avatar change:
- Tap → image picker (gallery or camera)
- Selected image → uploaded to Supabase Storage at `avatars/{user_id}.webp`
- `users.avatar_url` updated via `PATCH /v1/users/me`

---

## Data & API

| Action | Endpoint | Method |
|---|---|---|
| Load profile | `/v1/users/me` | GET |
| Update profile | `/v1/users/me` | PATCH |
| Upload avatar | Supabase Storage direct upload | — |
| Load orders | `/v1/orders?page=1&limit=20` | GET |
| Load active orders | `/v1/orders?status=active` | GET |
| Load wishlist | `/v1/wishlist` | GET |
| Remove from wishlist | `/v1/wishlist/:variantId` | DELETE |
| Load addresses | `/v1/addresses` | GET |
| Add address | `/v1/addresses` | POST |
| Update address | `/v1/addresses/:id` | PATCH |
| Delete address | `/v1/addresses/:id` | DELETE |
| Load receipts | `/v1/orders?paid=true` | GET |
| Download invoice PDF | `/v1/orders/:id/invoice` | GET (returns signed URL) |

---

## Riverpod Providers

```dart
// Profile data — cached in memory, refreshed on sheet open
final profileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.read(userRepositoryProvider).getMe();
});

// Orders list
final ordersProvider = FutureProvider.family<List<Order>, OrderFilter>((ref, filter) async {
  return ref.read(orderRepositoryProvider).getOrders(filter);
});

// Wishlist
final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<WishlistItem>>((ref) {
  return WishlistNotifier(ref.read(wishlistRepositoryProvider));
});

// Addresses
final addressesProvider = FutureProvider<List<Address>>((ref) async {
  return ref.read(addressRepositoryProvider).getAll();
});
```

---

## Flutter Packages Used

| Package | Purpose |
|---|---|
| `supabase_flutter` | `signOut()`, avatar upload |
| `flutter_secure_storage` | Clear JWT on logout |
| `flutter_form_builder` | Address add/edit form |
| `form_builder_validators` | Address field validation |
| `cached_network_image` | Avatar display |
| `dio` | All API calls |
| `drift` | Clear local cache on logout |

---

## Key Rules

- **Phone number is read-only** — it is the OTP login identity. Cannot be changed from profile edit.
- **Log out clears everything** — JWT, Drift cache, in-memory providers all reset. User starts fresh on next login.
- **Avatar stored in Supabase Storage** — path: `avatars/{user_id}.webp`, public bucket.
- **Address set as default** — only one address can be default. Setting a new default un-defaults the previous one (handled server-side).
