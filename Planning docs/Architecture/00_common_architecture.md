# Baker Ally — Common Architecture
> Foundation layer: applies to every tab, every screen, every feature.
> Last updated: July 2026

---

## Table of Contents

1. [What Baker Ally Actually Is](#1-what-baker-ally-actually-is)
2. [App Structure — Tabs & Navigation](#2-app-structure--tabs--navigation)
3. [User, Profile, Role & Privilege System](#3-user-profile-role--privilege-system)
4. [Core Database Tables](#4-core-database-tables)
5. [Product & Catalog Architecture](#5-product--catalog-architecture)
    - [5a. Reviews & Ratings Architecture](#5a-reviews--ratings-architecture)
6. [Pricing Architecture](#6-pricing-architecture)
7. [Image Architecture](#7-image-architecture)
8. [Cart Architecture](#8-cart-architecture)
9. [Order Architecture](#9-order-architecture)
10. [Payment Architecture](#10-payment-architecture)
11. [Shipping & Delivery Architecture](#11-shipping--delivery-architecture)
12. [Notification Architecture](#12-notification-architecture)
    - [12a. Back-in-Stock Email Notifications](#12a-back-in-stock-email-notifications)
13. [Brownie Points — Placeholder](#13-brownie-points--placeholder)
14. [Admin Web Panel Architecture](#14-admin-web-panel-architecture)
15. [Offline & Sync Strategy](#15-offline--sync-strategy)
16. [API Design Principles](#16-api-design-principles)
17. [Open Questions & Decisions Needed](#17-open-questions--decisions-needed)
18. [Architecture Risks & Mitigations](#18-architecture-risks--mitigations)

---

## 1. What Baker Ally Actually Is

Baker Ally is a **B2B/B2C bakery supply marketplace** — not a generic e-commerce app. This distinction drives several architectural decisions:

- Customers are **bakers and home bakers** buying ingredients, packaging, tools, and decorations
- Products have **variants** (size, weight, flavour) and potentially **bulk pricing tiers**
- Orders may be **recurring** — same items bought weekly or monthly
- Sellers/admins manage **catalog, stock, pricing, and discounts** from a web panel
- **WhatsApp is a primary communication channel** — not a nice-to-have

This context shapes everything below.

---

## 2. App Structure — Tabs, Navigation & Global Shell

### Bottom Navigation Bar (5 tabs)

```
├── Home           — Search + content tiles (newly launched, offers, etc.)
├── Catalog        — Browse categories → subcategories → products
├── Order Again    — Frequently bought together + previously bought
├── Brownie Points — Loyalty program (placeholder screen for now)
└── Cart           — Cart items → checkout
```

---

### Global App Shell — Present on Every Screen

Every screen in the app shares a consistent shell — **including all sub-screens like product detail, order detail, profile sub-screens etc.** The bottom navigation bar never disappears.

```
┌─────────────────────────────────────────────────────┐
│  [📍 Default Address   ▼]        [🔔]   [👤 Avatar] │  ← Top bar
│                                                       │
│  [🔍 Search icon]  ← taps to open search bar         │  ← Search (all pages except Home)
│  (Home only: search bar visible by default, not icon) │
├─────────────────────────────────────────────────────┤
│                                                       │
│                  Screen Content                       │
│                                                       │
├─────────────────────────────────────────────────────┤
│  [Home]   [Catalog]   [Order Again]   [🍪]   [Cart 🔴]│  ← Bottom nav
└─────────────────────────────────────────────────────┘
```

**Top bar elements:**

| Element | Position | Behaviour |
|---|---|---|
| Default delivery address | Top left | Shows selected address label (e.g. "Home", "Bakery"). Tap → address selector bottom sheet (85% screen) |
| Notification bell | Top right (left of avatar) | Badge shows unread count. Tap → notification list bottom sheet |
| Profile avatar | Top right | Tap → profile overlay bottom sheet |

**Search behaviour:**

| Screen | Search display |
|---|---|
| Home | Full search bar visible by default (prominent, top of content) |
| All other screens | Search icon in header — tap to expand inline search bar |

**Search implementation (Flutter):**
- `speech_to_text` package for voice input (on-device, no API cost)
- Text search hits `GET /v1/products?q=<term>` — backend full-text search via Postgres `tsvector`
- Search results shown inline, replacing screen content while active

**Cart badge:**
- Red circle on Cart tab icon showing item count
- Driven by `cartProvider` (Riverpod) — updates instantly on any add/remove

---

### Profile Overlay (top-right avatar tap)

Not a tab. Opens as a bottom sheet covering ~90% of screen:

```
Profile overlay
├── Profile Info          — name, phone, business name, avatar upload
├── Your Orders           → /orders
├── Order Status          → /orders (filtered to active)
├── Your Wishlist         → /wishlist
├── Receipts & Invoices   → /receipts
├── Delivery Addresses    → /addresses
├── Recipes               → /recipes (content, external or CMS)
├── Contact Us            → /contact
├── Help & Support        → /help
└── Log Out               → clears JWT, navigates to /login
```

---

### GoRouter Navigation Map

```dart
/                              → Home tab
/catalog                       → Catalog — category grid
/catalog/:categoryId           → Subcategory list for category
/catalog/:categoryId/:subId    → Product grid for subcategory
/product/:productId            → Product detail
/order-again                   → Order Again tab
/brownie-points                → Brownie Points (placeholder)
/cart                          → Cart tab
/checkout                      → Checkout page (items → you might like → bill → address → payment)
/checkout/confirmation         → Order confirmed screen
/orders                        → Order history
/orders/:orderId               → Order detail
/wishlist                      → Wishlist
/addresses                     → Saved addresses
/receipts                      → Receipts & invoices
/recipes                       → Recipes content
/contact                       → Contact Us
/help                          → Help & Support
/login                         → OTP / Google sign-in
```

### Navigation Rules — Back Button & Bottom Nav

**Bottom navigation bar:**

| Screen | Bottom nav visible? |
|---|---|
| All 5 tabs (Home, Catalog, Order Again, Brownie Points, Cart) | Yes |
| Sub-screens (product detail, order detail, address list, wishlist, etc.) | Yes |
| Checkout page | Yes |
| Order confirmation | Yes |
| Profile sub-screens (edit profile, address form, receipts, etc.) | Yes |
| Login screen | No — bottom nav hidden |
| Onboarding / OTP screen | No — bottom nav hidden |

The bottom nav is always visible in the main app shell. It is only hidden on pre-auth screens (login, OTP verification).

---

**Back navigation — how every screen goes back:**

| Screen | Back behaviour |
|---|---|
| Tab root screens (Home, Catalog, Order Again, Cart, Brownie Points) | No back button — these ARE the tabs |
| Level 2 product grid (`/catalog/:categoryId/:subId`) | `←` in top bar → back to `/catalog` (Level 1) |
| Level 3 product detail (`/product/:productId`) | `←` in top bar → back to wherever it was opened from (catalog Level 2, home, wishlist, etc.) |
| Checkout (`/checkout`) | `←` in top bar → back to Cart tab |
| Order confirmation | No back — replace navigation (user cannot go back to checkout after paying) |
| Order detail (`/orders/:id`) | `←` → back to order list |
| Profile sub-screens | `←` → back to profile bottom sheet |
| Address form | `←` → back to address list |

**On Android — hardware back button:**
Follows the same rules above. GoRouter handles this automatically via `PopScope`. On a tab root screen, Android back button exits the app (standard behaviour).

**Bottom nav tap on current tab:**
Tapping the active tab icon scrolls that tab back to the top (like Instagram/Zomato). If already at top, no action.

---

**Route guards (GoRouter redirect):**
```dart
redirect: (context, state) {
  final isLoggedIn = ref.read(authProvider).isLoggedIn;
  final protectedRoutes = ['/cart', '/checkout', '/orders', '/wishlist', '/addresses'];
  if (!isLoggedIn && protectedRoutes.any(state.uri.path.startsWith)) {
    return '/login?redirect=${state.uri.path}';
  }
  return null;
}
```

---

### Riverpod State Architecture

```
Root providers (always alive — survive tab switches)
├── authProvider            — JWT, user id, role
├── cartProvider            — cart items + totals (Drift-persisted)
├── selectedAddressProvider — currently selected delivery address
├── notificationProvider    — unread notification count (Supabase Realtime)
└── profileProvider         — user profile data

Tab providers (lazy — created on first tab visit)
├── homeProvider            — banner/tile content
├── catalogProvider         — category tree + selected subcategory
├── orderAgainProvider      — frequently bought + previously bought
└── browniePointsProvider   — points balance (placeholder)

Screen providers (scoped — alive only while screen is mounted)
├── productDetailProvider(productId)
├── checkoutProvider        — checkout state machine
└── searchProvider          — search query + results
```

---

## 3. User, Profile, Role & Privilege System

This is the **most critical foundation layer**. Everything in the app depends on who the user is and what they can access.

### Concept Hierarchy

```
User (authentication identity — Supabase Auth)
  └── has one Profile (display name, phone, business name, etc.)
  └── has one Role (Customer Individual | Admin | future roles)
        └── Role optionally linked to one Privilege Level (role-level default)
  └── optionally has own Privilege Level (user-level override)
        └── USER privilege level takes priority over ROLE privilege level
              └── Privilege Level defines access to Objects, Fields, Records
```

**Resolution rule:** When both a role-level and user-level privilege level exist, the **user-level privilege level is authoritative**. The role-level is the default applied when no user-level override exists. This allows two users with the same role to have different access without changing the role itself.

### Roles (current)

| Role | Who | Access |
|---|---|---|
| `customer_individual` | Default for all signups | Own records only — orders, addresses, wishlist |
| `admin` | Store owner / staff | All records — full web panel access |

> Note: More roles will be added as requirements emerge (e.g. `staff`, `warehouse`, `delivery_partner`). The architecture must accommodate this without restructuring.

### Privilege Levels

A Privilege Level is a named configuration that defines:
- Which **objects** (tables) a user can see
- Which **fields** within those objects are readable / editable
- Which **records** within those objects (own only vs all)

This is not built yet — placeholder in DB schema. Architecture described in [Admin Web Panel section](#14-admin-web-panel-architecture).

### Database Tables: User & Access System

```sql
-- Supabase Auth handles the auth identity (UUID, email, phone)
-- We extend it with our own tables

users
  id                    UUID PRIMARY KEY  -- matches Supabase Auth user id exactly
  email                 TEXT
  phone                 TEXT
  full_name             TEXT
  business_name         TEXT              -- baker's business name
  gstin                 TEXT              -- optional, for customer's own accounting records
  avatar_url            TEXT
  role_id               UUID FK → roles.id
  privilege_level_id    UUID FK → privilege_levels.id NULL
                        -- NULL = inherit from role. Set to override role's privilege level.
                        -- User-level privilege level takes priority over role-level when both exist.
  is_active             BOOLEAN DEFAULT true
  created_at            TIMESTAMPTZ DEFAULT now()

roles
  id                    UUID PRIMARY KEY
  name                  TEXT UNIQUE       -- 'customer_individual', 'admin'
  privilege_level_id    UUID FK → privilege_levels.id NULL  -- default privilege for this role
  created_at            TIMESTAMPTZ DEFAULT now()

privilege_levels
  id              UUID PRIMARY KEY
  name            TEXT              -- e.g. 'Full Admin', 'Catalog Manager'
  description     TEXT
  created_at      TIMESTAMPTZ DEFAULT now()

privilege_level_permissions
  id              UUID PRIMARY KEY
  privilege_level_id UUID FK → privilege_levels.id
  object_name     TEXT              -- table name e.g. 'products', 'orders'
  can_read        BOOLEAN DEFAULT false
  can_edit        BOOLEAN DEFAULT false
  field_overrides JSONB             -- { "field_name": { "can_read": true, "can_edit": false } }
  record_scope    TEXT              -- 'own' | 'all'
  created_at      TIMESTAMPTZ DEFAULT now()
```

### Signup Flow

```
New user signs up (OTP or Google)
  → Supabase Auth creates auth identity
  → Hono trigger / Edge Function creates users row
      with role_id = (SELECT id FROM roles WHERE name = 'customer_individual')
  → Flutter receives JWT
  → JWT contains: user_id, role name (from custom claim)
```

### JWT Custom Claims

Supabase Auth supports custom JWT claims via a database hook. We set the role on the JWT so Hono can check it without a DB query on every request:

```sql
-- Supabase Auth hook function (set in Supabase dashboard)
CREATE OR REPLACE FUNCTION custom_jwt_claims(event jsonb)
RETURNS jsonb AS $$
  SELECT event || jsonb_build_object(
    'app_metadata', jsonb_build_object(
      'role', (SELECT r.name FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = (event->>'user_id')::uuid)
    )
  );
$$ LANGUAGE sql;
```

---

## 4. Core Database Tables

Full schema — all tables Baker Ally needs at launch.

### Categories & Products

```sql
categories
  id              UUID PRIMARY KEY
  name            TEXT NOT NULL            -- 'Ingredients', 'Packaging', etc.
  image_url       TEXT
  sort_order      INTEGER DEFAULT 0
  is_active       BOOLEAN DEFAULT true
  created_at      TIMESTAMPTZ DEFAULT now()

sub_categories
  id              UUID PRIMARY KEY
  category_id     UUID FK → categories.id NOT NULL
  name            TEXT NOT NULL            -- 'Creams', 'Cake Boxes & Bases', etc.
  image_url       TEXT
  sort_order      INTEGER DEFAULT 0
  is_active       BOOLEAN DEFAULT true
  created_at      TIMESTAMPTZ DEFAULT now()

products
  id              UUID PRIMARY KEY
  sub_category_id UUID FK → sub_categories.id NOT NULL
  name            TEXT NOT NULL
  description     TEXT
  is_active       BOOLEAN DEFAULT true
  is_trending     BOOLEAN DEFAULT false
  sort_order      INTEGER DEFAULT 0
  created_at      TIMESTAMPTZ DEFAULT now()
  updated_at      TIMESTAMPTZ DEFAULT now()

product_variants
  id              UUID PRIMARY KEY
  product_id      UUID FK → products.id NOT NULL
  name            TEXT NOT NULL            -- '500g', '1kg', '5kg bag'
  sku             TEXT UNIQUE NOT NULL
  original_price  INTEGER NOT NULL         -- paise — shown struck-through if discount active
  current_price   INTEGER NOT NULL         -- paise — actual selling price
  stock_qty       INTEGER DEFAULT 0
  is_active       BOOLEAN DEFAULT true
  sort_order      INTEGER DEFAULT 0
  created_at      TIMESTAMPTZ DEFAULT now()

product_images
  id              UUID PRIMARY KEY
  product_id      UUID FK → products.id NOT NULL
  variant_id      UUID FK → product_variants.id NULL  -- null = applies to all variants
  storage_path    TEXT NOT NULL            -- Supabase Storage path
  public_url      TEXT NOT NULL
  sort_order      INTEGER DEFAULT 0
  is_primary      BOOLEAN DEFAULT false
  created_at      TIMESTAMPTZ DEFAULT now()
```

### Reviews & Ratings

See §5a for the full architecture. `order_items` (referenced below) is defined in "Cart & Orders" further down this section — reviews can't be migrated/built before Phase 3/4's order tables exist, since eligibility depends on them.

```sql
product_reviews
  id                UUID PRIMARY KEY
  product_id        UUID FK → products.id NOT NULL
  user_id           UUID FK → users.id NOT NULL
  order_item_id     UUID FK → order_items.id NOT NULL   -- proof of verified purchase
  overall_rating    SMALLINT NOT NULL         -- 1-5, CHECK (overall_rating BETWEEN 1 AND 5)
  quality_rating    SMALLINT NULL             -- 1-5 each, optional finer breakdown
  value_rating      SMALLINT NULL             -- shown as the category "rings" on product detail
  packaging_rating  SMALLINT NULL
  accuracy_rating   SMALLINT NULL             -- "matches the description" rating
  comment           TEXT NULL
  tags              TEXT[] NULL               -- quick-select chips, e.g. {Great Quality, Slow Delivery}
  created_at        TIMESTAMPTZ DEFAULT now()
  UNIQUE (user_id, product_id)                -- one review per user per product, no matter how many times re-bought
```

### Discounts

```sql
discounts
  id              UUID PRIMARY KEY
  code            TEXT UNIQUE              -- NULL for auto-applied discounts
  name            TEXT NOT NULL            -- internal label
  type            TEXT NOT NULL            -- 'percent' | 'flat' | 'free_shipping'
  value           INTEGER NOT NULL         -- percent: 10 = 10%, flat: 5000 = ₹50
  min_order_value INTEGER DEFAULT 0        -- paise — minimum cart value to apply
  max_uses        INTEGER NULL             -- NULL = unlimited
  uses_count      INTEGER DEFAULT 0
  is_active       BOOLEAN DEFAULT true
  starts_at       TIMESTAMPTZ NULL
  expires_at      TIMESTAMPTZ NULL
  created_at      TIMESTAMPTZ DEFAULT now()

product_discounts
  id              UUID PRIMARY KEY
  product_id      UUID FK → products.id NULL      -- NULL = applies to all
  variant_id      UUID FK → product_variants.id NULL
  discount_id     UUID FK → discounts.id NOT NULL
  created_at      TIMESTAMPTZ DEFAULT now()
```

### Cart & Orders

```sql
carts
  id              UUID PRIMARY KEY
  user_id         UUID FK → users.id NOT NULL UNIQUE  -- one active cart per user
  created_at      TIMESTAMPTZ DEFAULT now()
  updated_at      TIMESTAMPTZ DEFAULT now()

cart_items
  id              UUID PRIMARY KEY
  cart_id         UUID FK → carts.id NOT NULL
  variant_id      UUID FK → product_variants.id NOT NULL
  quantity        INTEGER NOT NULL DEFAULT 1
  added_at        TIMESTAMPTZ DEFAULT now()

addresses
  id              UUID PRIMARY KEY
  user_id         UUID FK → users.id NOT NULL
  label           TEXT                     -- 'Home', 'Bakery', 'Studio'
  line1           TEXT NOT NULL
  line2           TEXT
  city            TEXT NOT NULL
  state           TEXT NOT NULL
  pincode         TEXT NOT NULL
  is_default      BOOLEAN DEFAULT false
  created_at      TIMESTAMPTZ DEFAULT now()

orders
  id              UUID PRIMARY KEY
  user_id         UUID FK → users.id NOT NULL
  address_id      UUID FK → addresses.id NOT NULL
  status          TEXT DEFAULT 'pending'   -- pending|confirmed|processing|shipped|delivered|cancelled
  subtotal        INTEGER NOT NULL         -- paise
  discount_id     UUID FK → discounts.id NULL
  discount_value  INTEGER DEFAULT 0        -- paise — snapshot of discount applied
  shipping_cost   INTEGER DEFAULT 0        -- paise
  total           INTEGER NOT NULL         -- paise
  razorpay_order_id     TEXT
  razorpay_payment_id   TEXT UNIQUE        -- idempotency constraint
  notes           TEXT
  created_at      TIMESTAMPTZ DEFAULT now()
  updated_at      TIMESTAMPTZ DEFAULT now()

order_items
  id              UUID PRIMARY KEY
  order_id        UUID FK → orders.id NOT NULL
  variant_id      UUID FK → product_variants.id NOT NULL
  product_name    TEXT NOT NULL            -- snapshot — product name at time of order
  variant_name    TEXT NOT NULL            -- snapshot
  quantity        INTEGER NOT NULL
  unit_price      INTEGER NOT NULL         -- paise — price at time of order
  created_at      TIMESTAMPTZ DEFAULT now()

shipments
  id              UUID PRIMARY KEY
  order_id        UUID FK → orders.id NOT NULL
  shiprocket_order_id   TEXT
  awb             TEXT                     -- tracking number
  carrier         TEXT
  status          TEXT DEFAULT 'pending'
  tracking_url    TEXT
  estimated_delivery DATE
  updated_at      TIMESTAMPTZ DEFAULT now()
```

### Supporting Tables

```sql
wishlists
  id              UUID PRIMARY KEY
  user_id         UUID FK → users.id NOT NULL
  variant_id      UUID FK → product_variants.id NOT NULL
  created_at      TIMESTAMPTZ DEFAULT now()
  UNIQUE (user_id, variant_id)

stock_notify_requests        -- see §12a Back-in-Stock Email Notifications
  id              UUID PRIMARY KEY
  user_id         UUID FK → users.id NOT NULL
  variant_id      UUID FK → product_variants.id NOT NULL
  notified_at     TIMESTAMPTZ NULL         -- NULL = still waiting; set once the email sends
  created_at      TIMESTAMPTZ DEFAULT now()
  UNIQUE (user_id, variant_id)

notifications
  id              UUID PRIMARY KEY
  user_id         UUID FK → users.id NOT NULL
  channel         TEXT                     -- 'push' | 'in_app' (no 'whatsapp' -- see §12)
  type            TEXT                     -- 'order_confirmed' | 'shipped' | etc.
  title           TEXT
  body            TEXT
  is_read         BOOLEAN DEFAULT false
  sent_at         TIMESTAMPTZ DEFAULT now()

webhook_events
  id              UUID PRIMARY KEY
  source          TEXT NOT NULL            -- 'razorpay' | 'shiprocket'
  event_id        TEXT NOT NULL
  payload         JSONB
  processed_at    TIMESTAMPTZ DEFAULT now()
  UNIQUE (source, event_id)

brownie_points
  id              UUID PRIMARY KEY
  user_id         UUID FK → users.id NOT NULL
  points          INTEGER NOT NULL         -- positive = earned, negative = redeemed
  reason          TEXT                     -- 'order_ORD-001' | 'redeemed_cart' etc.
  order_id        UUID FK → orders.id NULL
  created_at      TIMESTAMPTZ DEFAULT now()
```

### Required Indexes

```sql
-- Catalog browsing
CREATE INDEX idx_products_subcategory ON products(sub_category_id) WHERE is_active = true;
CREATE INDEX idx_subcategories_category ON sub_categories(category_id) WHERE is_active = true;
CREATE INDEX idx_variants_product ON product_variants(product_id) WHERE is_active = true;
CREATE INDEX idx_product_images_product ON product_images(product_id);

-- Reviews & ratings -- product_id lookup drives both the review list and
-- the live-aggregated rating summary on product detail (§5a)
CREATE INDEX idx_product_reviews_product ON product_reviews(product_id);

-- Orders
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);

-- Wishlist
CREATE INDEX idx_wishlists_user ON wishlists(user_id);

-- Back-in-stock notifications -- only the pending ones need to be scanned
-- when a variant's stock_qty crosses 0 -> positive
CREATE INDEX idx_stock_notify_variant_pending
  ON stock_notify_requests(variant_id) WHERE notified_at IS NULL;

-- Notifications
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE is_read = false;

-- Brownie points
CREATE INDEX idx_brownie_points_user ON brownie_points(user_id);
```

---

## 5. Product & Catalog Architecture

### Category Hierarchy

```
Category (e.g. Ingredients)
  └── SubCategory (e.g. Creams)
        └── Product (e.g. Fresh Cream 25%)
              └── Variant (e.g. 500ml, 1L, 5L)
                    └── Images (primary + gallery)
                    └── Price (original_price + current_price)
                    └── Stock
```

### Categories from App Content (locked)

```
A. Ingredients
   1. Creams
   2. Cocoa & Chocolates
   3. Fruit Fillings & Crushes
   4. Food Stabilizers & Leaving Agents
   5. Mixes
   6. Food Colours
   7. Food Flavours

B. Packaging
   1. Cake Boxes & Bases
   2. Dessert Boxes
   3. PVC & Acrylic Packaging
   4. Biodegradable Packaging
   5. Bags & Pouches
   6. Add-ons
   7. Festive Packaging

C. Tools & Equipment
   1. Speciality Tools
   2. Kitchen Appliances
   3. Structure Tools

D. Cake Decorations
   1. Edible Decorations
   2. Non Edible Decorations
   3. Add-ons

E. Seasonal & New Collections
   1. Collections for Festives
   2. Stock Clearance Items
   3. New Arrivals

F. Bakeware
   1. Cake Moulds
   2. Dessert Moulds
   3. Paper Moulds
   4. Silicon Moulds
```

> Note: Makers-Business Tools (Category G) is excluded from current scope per instructions.

### Product Flags

Each product/variant can have multiple flags that affect display and behavior:

| Flag | Where stored | Effect |
|---|---|---|
| `is_trending` | products table | Shows "Trending" badge |
| `is_active = false` | products/variants | Hidden from catalog |
| `stock_qty = 0` | product_variants | Shows "Out of Stock" — cannot add to cart |
| `stock_qty < threshold` | product_variants | Shows "Low Stock" badge |
| `original_price ≠ current_price` | product_variants | Shows struck-through original, highlighted discounted price |
| `is_active` on category/subcategory | categories/sub_categories | Hides entire section |

---

## 5a. Reviews & Ratings Architecture

**Not built yet — designed here, scheduled to Phase 5 (Account & Discovery)**, since eligibility depends on `order_items` existing (Phase 3/4) and Phase 5 is where the "Discovery"/trust-building features live. Product-level only — no store-wide/seller rating in this design (kept out of scope deliberately to match the initial ask).

Appears on the Product Detail page (Level 3), below "You Might Also Like" (`02_catalog_tab.md` §4).

### Layout (adapt to Baker Ally's own brand colours — the screenshot referenced during design was Zomato-style and used as a structural reference only, not a colour/category source)

```
─── Reviews & Ratings ─────────────────────────────

  4.6 ★★★★★                          410 reviews
  (See all reviews →)

  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
  │  4.8   │  │  4.7   │  │  4.5   │  │  4.9   │   ← 4 category rings, live-averaged
  └────────┘  └────────┘  └────────┘  └────────┘
  Quality      Value       Packaging   Accuracy
                                        to Listing

  ┌──────────────────────────────────────────┐
  │ [avatar] Priya S.                 ⭐ 5.0 │
  │          3 months ago                    │
  │          "Cream held up perfectly for    │
  │          the whole tiering job."         │
  │          [Quality] [Packaging]           │
  └──────────────────────────────────────────┘  ← horizontal scroll, same
  (more review cards scroll horizontally →)         card pattern as product tiles

  [ See all reviews → ]

  [ Add Review ]   ← only shown if the logged-in user is eligible (below)
```

### Eligibility — verified purchase only

A user can review a product only if they have an `order_items` row for that product on an order with `status = 'delivered'` — not merely `confirmed`, since a fair review (especially of "Packaging Condition") requires the item to have actually arrived. One review per user per product (`UNIQUE(user_id, product_id)` on `product_reviews`), regardless of how many times they've reordered it.

```
GET /v1/products/:id/reviews/eligibility
  → { canReview: boolean, reason?: 'not_purchased' | 'not_delivered' | 'already_reviewed' }
  → Flutter only renders the "Add Review" button when canReview = true
```

### Rating categories

Replaces the screenshot's restaurant-specific categories (Ambience, Music, Food, Service, Pricing, Hygiene) with ones relevant to a physical-goods bakery-supply store:

| Category | What it measures |
|---|---|
| Product Quality | Did the ingredient/tool perform as expected? |
| Value for Money | Fair pricing for what was received |
| Packaging Condition | Arrived intact, no leaks/damage/melting |
| Accuracy vs Description | Matched the listed size/description/photos |

Each is an optional 1-5 sub-rating on the review form; `overall_rating` is the only required field. The 4 rings on product detail are the **live average** of each sub-rating across all reviews for that product (simple `AVG()` query, not precomputed — review volume per product is expected to be low; revisit with a materialised aggregate only if Phase 7 load testing shows it's needed, same reasoning as the `order_group_cache` precomputation note in §3).

### Data & API

| Action | Endpoint | Method | Notes |
|---|---|---|---|
| Load reviews + aggregate summary | `/v1/products/:id/reviews?page=&limit=` | GET | Returns `{ summary: { overallRating, reviewCount, categoryAverages }, reviews: [...] }` |
| Check review eligibility | `/v1/products/:id/reviews/eligibility` | GET | Drives whether "Add Review" renders |
| Submit a review | `/v1/products/:id/reviews` | POST | `{ orderItemId, overallRating, qualityRating?, valueRating?, packagingRating?, accuracyRating?, comment?, tags? }` — backend re-verifies eligibility server-side, never trusts the client |

### Add Review Form

Opens as a bottom sheet from the "Add Review" button:
- Overall star rating (required, tap to select 1-5)
- 4 optional category star ratings (Quality / Value / Packaging / Accuracy)
- Free-text comment (optional)
- Quick-select tag chips (optional, multi-select — e.g. "Great Quality", "Fast Delivery", "Damaged Packaging") for the small pill chips shown on each review card
- Submit → `POST /v1/products/:id/reviews` → sheet closes, review list + rings refresh

### Riverpod State

```dart
final productReviewsProvider = FutureProvider.family<ReviewSummary, String>((ref, productId) async {
  return ref.read(reviewRepositoryProvider).getReviews(productId);
});

final reviewEligibilityProvider = FutureProvider.family<ReviewEligibility, String>((ref, productId) async {
  return ref.read(reviewRepositoryProvider).getEligibility(productId);
});
```

---

## 6. Pricing Architecture

### Two-Price Model

Every variant stores **two prices**:
- `original_price` — the MRP / full price, shown struck-through when a discount is active
- `current_price` — the actual selling price

```
original_price = 10000  (₹100)
current_price  = 8500   (₹85)

UI shows: ~~₹100~~  ₹85  🏷️ 15% off
```

Admin sets both prices directly. No computed discount stored — the difference is visual only.

### Cart Price Calculation

```
line_total = variant.current_price × quantity        (per item)
subtotal   = Σ line_totals
discount   = calculated from discount code (if applied)
shipping   = 0 if subtotal ≥ free_shipping_threshold, else flat_rate
total      = subtotal - discount + shipping
GST        = included in price (B2C — decided)
```

> **Decided (§17):** Baker Ally is B2C. GST is included in all prices. No separate GST line on checkout. Customers may optionally store their GSTIN on their profile for their own records but it does not affect billing.

### Free Shipping via Brownie Points

App Content mentions "Brownie Points program for Free Shipping" — free shipping threshold or brownie point redemption for shipping waiver. Architecture placeholder in brownie_points table.

---

## 7. Image Architecture

### Storage Structure (Supabase Storage)

```
bucket: product-images (public)
  products/
    {product_id}/
      primary.webp          ← main catalog image
      gallery/
        01.webp
        02.webp
        ...
  categories/
    {category_id}.webp
  sub_categories/
    {sub_category_id}.webp
```

### Image Upload Flow (Admin Web Panel)

```
Admin uploads image on web panel
  → Next.js sends file to Hono Edge Function
  → Edge Function:
      1. Validates file type (jpg/png/webp only) + size (< 5MB)
      2. Converts to webp (sharp or equivalent)
      3. Uploads to Supabase Storage
      4. Stores public_url in product_images table
  → Web panel shows preview
```

### Image Display (Flutter)

All images served via `cached_network_image` — cached on device after first load. Primary image shown in catalog tiles, gallery images in product detail page.

---

## 8. Cart Architecture

### Two-layer cart: server + local

| Layer | Tool | Purpose |
|---|---|---|
| Server cart | `carts` + `cart_items` tables | Source of truth — survives app reinstall, login on new device |
| Local cart | Drift (SQLite on device) | Instant UI response — no loading spinner on cart changes |

### Sync Strategy

```
User adds item to cart
  → Drift updated immediately (UI reflects instantly)
  → Background Dio call: POST /cart/items
  → Server cart updated
  → On conflict (e.g. item now out of stock): server wins, Drift corrected

User opens app fresh
  → GET /cart → server cart loaded into Drift
  → UI renders from Drift
```

### Guest Cart

Guest users (not logged in) **can add items to cart** — stored in Drift locally only, no server call. They **cannot checkout** — tapping Proceed shows a login bottom sheet.

```
Guest taps "Add to Cart"
  → Item written to Drift local cart immediately
  → No server call (no JWT available)
  → Cart badge updates, stepper shows qty

Guest taps Cart tab → Proceed
  → Login bottom sheet appears
  → User logs in via OTP / Google

After login:
  → POST /v1/cart/merge { items: [{ variantId, quantity }] }
  → Server merges guest items into user's server cart
      (if item already in server cart → quantities are added)
  → Drift synced from server response
  → Checkout continues
```

This avoids the contradiction of blocking add-to-cart while also describing a merge. The merge only happens because we allowed local cart building pre-login.

---

## 9. Order Architecture

### Order Lifecycle & State Machine

```
[no row]   → User is browsing / adding to cart

pending    → POST /v1/cart/checkout called:
               - orders row CREATED with status = 'pending'
               - razorpay_order_id stored on the row
               - cart items snapshotted into order_items
               - Razorpay order created, keyId + razorpayOrderId returned to Flutter
               - Flutter opens Razorpay payment sheet

             (if user abandons payment → row stays 'pending' → abandoned cart tracking possible)

confirmed  → POST /v1/orders called after successful payment:
               - HMAC signature verified
               - orders row UPDATED: status = 'confirmed', razorpay_payment_id stored
               - Unique constraint on razorpay_payment_id prevents double-confirmation
               - product_variants.stock_qty decremented for each order_item,
                 in the SAME transaction as the status update (see §18 risk
                 register "Stock goes negative" — this is the mitigation,
                 not just a note: decrement here, never at cart add)
               - Job enqueued to pgmq: Shiprocket + WhatsApp + FCM handled async
               - 201 returned to Flutter immediately

processing → Admin/warehouse manually updates OR automated trigger (future)

shipped    → Shiprocket webhook fires → order + shipment updated

delivered  → Shiprocket webhook fires OR admin manual update

cancelled  → Admin cancels before shipment → refund triggered via Razorpay if confirmed
```

**Why create the row at checkout (not at confirmation):**
- Enables abandoned-cart tracking (pending rows older than 24h = abandoned)
- Idempotency before payment — if Flutter crashes after opening Razorpay, the row exists and can be recovered
- The `razorpay_order_id` on the pending row ties Razorpay's order to ours before any money moves

### Order Again Feature (from Plan_Architect.md)

Two sections in the Order Again tab:

**1. Frequently Bought Together**
- Groups of items bought together in past orders — per user first, then platform-wide
- Computed by backend: query order_items, group by order_id, find co-occurring variants
- Top 10 groups shown as horizontally scrollable tiles
- Each tile: 2 product images + `+X items` text if more than 2
- On tap: bottom sheet (85% screen height) with full item list, quantities, add-to-cart

**2. Previously Bought**
- Individual products the logged-in user has ordered before
- Tile: product image, name, current price, "Add to Cart" button
- On "Add to Cart": quantity stepper appears in-tile (– qty +)
- Sorted by most recently bought

### Backend computation (Edge Function)

```typescript
// Frequently bought together — computed server-side
GET /order-again/frequently-bought
  → Query: SELECT variant_ids from order_items grouped by order_id for user
  → Deduplicate and rank by frequency
  → Return top 10 groups with product details

// Previously bought
GET /order-again/previously-bought
  → SELECT DISTINCT variant_id from order_items WHERE user_id = jwt_user
  → JOIN product_variants, products, product_images
  → ORDER BY MAX(order created_at) DESC
```

---

## 10. Payment Architecture

Full detail in [backend_stack.md — Payments section].

### Summary

```
Flutter (razorpay_flutter)
  → POST /cart/checkout        creates Razorpay order, returns order_id + key
  → Opens Razorpay sheet
  → User pays
  → POST /orders               verifies HMAC signature → creates order → enqueues job
  → Queue worker               Shiprocket + WhatsApp + FCM async
```

### Supported Methods (via Razorpay)
- UPI (free — 0% fee)
- Debit / Credit cards
- Netbanking
- Wallets (Paytm, PhonePe, etc.)

### Porter Integration (mentioned in Plan_Architect.md)
Porter is a hyperlocal delivery service (same-city delivery). Architecture:
- Separate from Shiprocket — used for local/same-day deliveries
- Backend: POST to Porter API when order is local delivery type
- Decision needed: is Porter for all orders or only same-city? What triggers Porter vs Shiprocket?

---

## 11. Shipping & Delivery Architecture

### Two delivery providers

| Provider | Use case | Integration |
|---|---|---|
| Shiprocket | Pan-India shipping (2–5 days) | Backend only — webhook for status |
| Porter | Local / same-day delivery | Backend only — to be planned separately |

### Shipping Cost Calculation

```
if order.subtotal >= FREE_SHIPPING_THRESHOLD:
  shipping_cost = 0
else:
  shipping_cost = flat_rate  (e.g. ₹50)
  OR weight-based rate from Shiprocket API
```

### Bakers Info → Customer Shipping Details

"Bakers Info" refers to the **customer's profile** — their business name, phone, and saved delivery addresses. At checkout:
- Customer selects from saved addresses (or adds new one via address bottom sheet)
- Shipping is dispatched from Baker Ally's single warehouse (single-seller store)
- Packaging cost alignment: TBD during Porter integration planning

---

## 12. Notification Architecture

**Decision (2026-07-12): no Interakt/WhatsApp Business API integration.** Order-status communication to the customer is **in-app notifications + FCM push only**. The shipment carrier (Shiprocket) sends its own WhatsApp/SMS delivery updates directly to the customer under its own account — Baker Ally does not build, pay for, or route through a WhatsApp Business API for this. (A plain `wa.me` link on the Contact Us screen for customer support chat is unaffected — that's a static link, not an API integration.)

### Channels

| Channel | Tool | Trigger |
|---|---|---|
| Push | FCM via firebase-admin | Order status changes, promotions |
| In-app | `notifications` table via Dio polling | Bell badge + notification list |

### In-app Notification Bell — Dio Polling (not Supabase Realtime)

**Why not Supabase Realtime:** `supabase_flutter` is auth-only in this architecture. Realtime is a direct DB subscription that bypasses Hono entirely, violating the rule that all data flows through Dio → Hono. Using it would require RLS carve-outs and split the data access model.

**Decision: poll `GET /v1/notifications/unread-count` every 30 seconds via Dio.**

```
Flutter (Riverpod timer-based provider)
  → every 30s: GET /v1/notifications/unread-count
  → returns { count: 3 }
  → bell badge updates

On bell tap:
  → GET /v1/notifications?page=1&limit=20
  → bottom sheet renders list
  → on read: PATCH /v1/notifications/:id { is_read: true }
  → count re-fetched, badge updates
```

30-second polling is sufficient for a notification bell — users don't need sub-second delivery for "your order shipped." FCM push handles the real-time delivery; in-app bell is supplementary.

---

## 12a. Back-in-Stock Email Notifications

**Not built yet — designed here, scheduled per §17's open decisions.** Referenced from `02_catalog_tab.md` (the out-of-stock state on the product tile / Fixed Bottom CTA) and `03_order_again_tab.md` §7, which already called out a "Notify Me" button on out-of-stock tiles as a future feature without a design behind it. This section is that design.

### The trigger point

`product_variants.stock_qty` is the only signal — "back in stock" means it crossed from `0` (or below) to a positive value. Today the sole write path for that column is the Phase 6 admin endpoint `PATCH /v1/admin/variants/:id/stock`; Phase 3's order-confirm flow (§9) will add a second write path (decrementing stock on order confirmation, which only ever *lowers* the value so it can't itself trigger a restock notification, but does mean stock_qty is no longer single-writer).

**Detection should be a Postgres trigger, not an application-level before/after check in each endpoint** — `AFTER UPDATE OF stock_qty ON product_variants WHEN OLD.stock_qty <= 0 AND NEW.stock_qty > 0`, so the transition is caught regardless of which code path caused it (admin stock edit, future bulk import, etc.) rather than requiring every future writer to remember to duplicate the check.

### Data model

```sql
stock_notify_requests
  id              UUID PRIMARY KEY
  user_id         UUID FK → users.id NOT NULL
  variant_id      UUID FK → product_variants.id NOT NULL
  notified_at     TIMESTAMPTZ NULL        -- NULL = pending; set once the email sends
  created_at      TIMESTAMPTZ DEFAULT now()
  UNIQUE (user_id, variant_id)
```

One row = one user's standing request to be told when one variant restocks. `notified_at IS NULL` is "still waiting"; once sent, the row is kept (not deleted) as a record, and a fresh "Notify Me" tap after that point should be allowed to re-arm it (`UPDATE ... SET notified_at = NULL` rather than a second insert, since the unique constraint is on `(user_id, variant_id)`).

### Flow

```
Customer taps "Notify Me" on an out-of-stock variant
  → requires login (same gate as the wishlist heart, 02_catalog_tab.md §6)
  → POST /v1/stock-notify { variantId }
  → upserts a stock_notify_requests row, notified_at = NULL

Admin restocks the variant (Phase 6 stock edit)
  → PATCH /v1/admin/variants/:id/stock updates product_variants.stock_qty
  → Postgres trigger fires (0 -> positive), enqueues a job to a new
    pgmq queue 'stock_notify_events' with { variantId }
    -- reuses the exact queue+worker pattern Phase 4 builds for
    -- order_events (Supabase Cron worker, every 30s), rather than a
    -- second bespoke background-job mechanism

Worker (extends the Phase 4 cron worker)
  → reads pending stock_notify_requests for that variant_id
    (idx_stock_notify_variant_pending makes this cheap)
  → sends one email per request via [email provider -- not yet chosen, see §17]
  → stamps notified_at = now() on each row sent
  → (optional) also inserts a row into `notifications`
    (channel = 'email', type = 'back_in_stock') so it shows in the
    in-app bell too, reusing the existing table rather than a parallel one
```

### What's still an open decision

There is currently **no transactional email provider** wired into the backend. `backend_stack.md`'s only two outbound channels are FCM (push) and Interakt (WhatsApp) — Supabase's built-in email sending is scoped to Auth (OTP codes only), not something application code can call for arbitrary emails. A provider (e.g. Resend, Postmark, SendGrid) needs to be chosen and its secret added alongside `UPSTASH_REDIS_REST_URL` / `SENTRY_DSN` in Edge Function secrets before this can actually send anything. See §17 "Still Open."

---

## 13. Brownie Points — Placeholder

**Not built in current scope.** Architecture reserved.

```
Concept:
  - Earn points on every order (e.g. ₹1 spent = 1 point)
  - Points redeemable for free shipping or discount
  - "Brownie Points" tab in bottom nav — placeholder screen for now

DB: brownie_points table exists (see Section 4)
Tab: shows placeholder "Coming Soon" screen
```

---

## 14. Admin Web Panel Architecture

### What admins do (web only)

```
Products & Catalog
  ├── Add / edit categories and subcategories
  ├── Add / edit products and variants
  ├── Upload product images
  ├── Set original_price and current_price per variant
  ├── Toggle is_active, is_trending, stock_qty
  └── Manage discounts

Orders
  ├── View all orders (filterable by status, date, user)
  ├── Update order status manually
  └── View order details + customer info

Users
  ├── View all users
  ├── Invite new users (admin role)
  ├── Assign roles and privilege levels
  └── Deactivate users

Settings
  ├── Profiles tab — list of profiles
  ├── Users tab — list of users + invite button
  └── Privilege Levels tab
        ├── List of privilege levels
        ├── New privilege level button
        └── Edit privilege level:
              ├── Name + description
              ├── List of objects (tables)
              └── Per object: list of fields
                    ├── Read checkbox
                    └── Edit checkbox (auto-checks Read)
```

### Privilege Level UI (Admin Settings)

```
Privilege Level Editor
┌─────────────────────────────────────────────┐
│ Name: [Catalog Manager                     ]│
│                                             │
│ Object: [products ▼]                        │
│                                             │
│ Field              Read    Edit             │
│ ─────────────────  ──────  ──────          │
│ name               ☑       ☑               │
│ description        ☑       ☑               │
│ is_active          ☑       ☑               │
│ original_price     ☑       ☐               │  ← read-only field
│ current_price      ☑       ☑               │
│ stock_qty          ☑       ☐               │
│                                             │
│ Record scope: ○ Own records  ● All records  │
└─────────────────────────────────────────────┘
```

---

## 15. Offline & Sync Strategy

Baker Ally must work on poor connections — many bakers are in areas with spotty 4G.

### What works offline

| Feature | Offline behaviour |
|---|---|
| Browse catalog | Served from Drift cache — last fetched data shown |
| View cart | Drift-persisted — always available |
| View past orders | Drift-cached — shows last synced orders |
| Place order | Requires internet — clear error message shown |
| View order status | Requires internet |

### Sync via Workmanager

```
Background task (every 60 min when on WiFi)
  → Fetch latest categories + products → update Drift
  → Fetch latest orders → update Drift
  → Push any queued analytics events
```

### Stale data indicators

If cached data is > 24 hours old, show a subtle "Last updated X hours ago" banner — don't silently serve stale prices.

---

## 16. API Design Principles

All Hono routes follow these conventions:

### URL structure
```
/v1/                          ← version prefix on all routes
/v1/categories
/v1/products
/v1/cart
/v1/orders
/v1/admin/products            ← admin routes under /admin/
/v1/webhooks/razorpay         ← webhooks under /webhooks/
```

### Response shape (consistent across all routes)
```typescript
// Success
{ data: <payload>, meta?: { page, total } }

// Error
{ error: { code: 'PRODUCT_NOT_FOUND', message: 'Human readable' } }
```

### Pagination
All list endpoints paginate with `?page=1&limit=20`. Never return unbounded lists.

### Idempotency
`POST /v1/orders` requires `Idempotency-Key` header. Duplicate key = return existing order, no double-processing.

---

## 17. Decisions Log

### Closed Decisions

| # | Question | Decision |
|---|---|---|
| 1 | B2C or B2B? GST included or separate? | Everyone is a customer — B2C model. GST included in price. No GSTIN input at checkout. |
| 2 | Single seller or multi-seller? | Single seller store as of now. One warehouse, one catalog owner. |
| 3 | Porter — which cities? What triggers it? | Details to be defined during Porter integration. Placeholder in architecture. |
| 4 | Brownie points earn/redeem/expiry? | To be decided in a separate session. DB table exists as placeholder. |
| 5 | Free shipping threshold? | To be decided during Porter integration planning. |
| 6 | What goes on the Home tab? | Search bar (visible by default) + horizontal placeholder tile rows (Newly Launched, New Offers, etc.) See Section 19. |
| 7 | "Bakers Info" — seller or buyer profile? | Customer info — the buyer's profile (business name, delivery address, phone). |
| 8 | Voice search — which service? | Implement whichever is most practical. On-device (speech_to_text Flutter package) preferred for privacy and no API cost. |
| 9 | Wishlist — per device or per login? | Per login — synced across devices via `wishlists` table (already in schema). |
| 10 | AI Prompt for product ideas? | Placeholder only — not in current scope. Keep as a future feature tab/button. |

### Still Open
| # | Question | Blocks |
|---|---|---|
| A | Porter integration details | Shipping cost calculation, free shipping threshold |
| B | Brownie points earn/redeem rules | brownie_points tab build |
| C | Transactional email provider (Resend / Postmark / SendGrid / other)? | Back-in-stock emails (§12a) — the design and `stock_notify_requests` table are ready, but nothing can actually send until a provider is picked and its secret is added |

---

## 18. Architecture Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Catalog changes (new categories, fields) break app | High | Medium | Category/subcategory driven by DB — no hardcoded categories in Flutter |
| Price displayed to customer differs from price charged | High | High | Cart checkout re-validates prices server-side before Razorpay order creation |
| Duplicate orders on payment retry | Medium | High | `razorpay_payment_id UNIQUE` constraint + idempotency key on POST /orders |
| Stock goes negative (oversell) | Medium | High | Decrement stock in DB transaction when order confirmed — not at cart add |
| Image storage costs blow up | Low | Medium | Compress to webp on upload, set max 5MB per image, lazy-load in Flutter |
| ~~WhatsApp template rejection by Meta~~ | — | — | Removed 2026-07-12 — no Interakt/WhatsApp integration; in-app + FCM push only (§12) |
| Porter API instability for local delivery | Medium | Medium | Fallback to Shiprocket if Porter fails — order still ships, just slower |
| Admin privilege level misconfiguration exposes data | Low | High | Backend ownership checks independent of privilege levels — service-role key always enforces user_id checks |

---

## 19. Home Tab Architecture

### Layout (top to bottom)

```
┌─────────────────────────────────────────────────────┐
│  [📍 Address ▼]                      [🔔]  [👤]     │
│                                                       │
│  ┌─────────────────────────────────────────────┐    │
│  │  🔍  Search ingredients, packaging...   🎤  │    │  ← Search bar (default visible)
│  └─────────────────────────────────────────────┘    │
│                                                       │
│  ── Newly Launched ──────────────────── See all →   │
│  [ tile ][ tile ][ tile ][ tile ]  ← horizontal scroll│
│                                                       │
│  ── New Offers ──────────────────────── See all →   │
│  [ tile ][ tile ][ tile ][ tile ]  ← horizontal scroll│
│                                                       │
│  ── Trending Now ────────────────────── See all →   │
│  [ tile ][ tile ][ tile ][ tile ]  ← horizontal scroll│
│                                                       │
│  [more sections added here as content grows]          │
│                                                       │
└─────────────────────────────────────────────────────┘
```

### Home Tile Sections (placeholders — content added progressively)

| Section | Data source | Filter |
|---|---|---|
| Newly Launched | `products` table | `created_at DESC`, limit 10 |
| New Offers | `product_variants` | `original_price ≠ current_price`, limit 10 |
| Trending Now | `products` | `is_trending = true`, limit 10 |
| *(more sections TBD)* | — | — |

Each section:
- Horizontal scrollable row of product tiles
- "See all →" navigates to `/catalog` pre-filtered
- Each tile: product image, name, price (struck-through original if discounted), "Add to Cart" button

### Home API
```
GET /v1/home
  → returns { newlyLaunched: [], newOffers: [], trending: [] }
  → single call, all sections in one response
  → cached in Drift — refreshed by Workmanager background sync
```

### Voice Search (on Home)
```dart
// speech_to_text package — on-device, no API cost
final speech = SpeechToText();
await speech.listen(onResult: (result) {
  searchController.text = result.recognizedWords;
  // triggers GET /v1/products?q=<words>
});
```

---

## 20. Checkout Page Architecture

### Checkout is a single scrollable page — NOT a multi-step wizard

Everything is on one screen, sections stacked vertically:

```
┌─────────────────────────────────────────────────────┐
│  ← Back          Your Order                         │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ITEMS IN CART                                        │
│  ┌──────────────────────────────────────────────┐   │
│  │ [img] Product name         Qty: [–] 2 [+]    │   │
│  │       Variant · ₹price                        │   │
│  ├──────────────────────────────────────────────┤   │
│  │ [img] Product name         Qty: [–] 1 [+]    │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  YOU MIGHT ALSO LIKE                                  │
│  [ tile ][ tile ][ tile ]  ← horizontal scroll        │
│  (products from same categories as cart items)        │
│                                                       │
│  BILL DETAILS                                         │
│  ┌──────────────────────────────────────────────┐   │
│  │  Subtotal                          ₹X,XXX    │   │
│  │  Discount (CODE10)               – ₹XXX      │   │
│  │  Delivery charges                  ₹XX       │   │
│  │  ─────────────────────────────────────────   │   │
│  │  Total                             ₹X,XXX    │   │
│  │  [  Enter discount code...    ] [Apply]       │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  CANCELLATION POLICY                                  │
│  ┌──────────────────────────────────────────────┐   │
│  │  Orders can be cancelled within X hours of   │   │
│  │  placement. Once shipped, no cancellation.   │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  DELIVERY ADDRESS                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │  🏠 Home                          [Change →] │   │
│  │  123, Street Name, City – 400001              │   │
│  └──────────────────────────────────────────────┘   │
│  (Change → opens address selector bottom sheet)      │
│                                                       │
│  PAYMENT                                              │
│  ┌──────────────────────────────────────────────┐   │
│  │  Pay via  ○ UPI  ○ Card  ○ Netbanking         │   │
│  │  Amount payable:  ₹X,XXX                      │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  ┌──────────────────────────────────────────────┐   │
│  │         PLACE ORDER  →  ₹X,XXX               │   │  ← sticky bottom CTA
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Address Selector Bottom Sheet (85% screen)

Triggered by tapping "Change →" on delivery address section:

```
┌──────────────────────────────────────────┐
│  Select Delivery Address          [✕]    │
│  ──────────────────────────────────────  │
│  ● Home                                  │
│    123 Street, City – 400001             │
│  ○ Bakery Studio                         │
│    456 Road, City – 400002               │
│  ○ + Add new address                     │
│  ──────────────────────────────────────  │
│  [  Deliver Here  ]                      │
└──────────────────────────────────────────┘
```

### "You Might Also Like" Logic

```typescript
// Backend: GET /v1/checkout/recommendations?cartItemIds=id1,id2,...
// Returns products from the same subcategories as cart items
// Excludes items already in cart
// Limit 10, sorted by is_trending DESC, created_at DESC
```

### Checkout State Machine (Riverpod)

```
CheckoutState
  ├── cartItems       — from cartProvider (Drift)
  ├── selectedAddress — from selectedAddressProvider
  ├── discountCode    — user-entered string
  ├── discountResult  — validated discount (nullable)
  ├── recommendations — "you might also like" products
  ├── billSummary     — computed: subtotal, discount, shipping, total
  └── paymentStatus   — idle | processing | success | failed

Actions
  ├── applyDiscount(code)     → POST /v1/discounts/validate
  ├── changeAddress(id)       → updates selectedAddressProvider
  ├── placeOrder()            → POST /v1/cart/checkout → opens Razorpay
  └── onPaymentResult(result) → POST /v1/orders
```

### Price Re-validation on Checkout

Before opening Razorpay, backend re-validates all prices server-side:
```typescript
POST /v1/cart/checkout
  → for each cart item: fetch current variant.current_price from DB
  → if any price changed since cart was built → return 409 with updated prices
  → Flutter shows "Prices updated" banner, user reviews before retrying
  → if prices unchanged → create Razorpay order → return to Flutter
```

---

## 21. Search Architecture

### Text Search
- Flutter sends `GET /v1/products?q=<term>&page=1&limit=20`
- Backend: Postgres full-text search using `tsvector` on `products.name + description + sub_categories.name`
- Results ranked by relevance + `is_trending`

```sql
-- Migration: add search vector to products
ALTER TABLE products ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, ''))
  ) STORED;

CREATE INDEX idx_products_search ON products USING GIN(search_vector);
```

### Voice Search
- Flutter: `speech_to_text` package — on-device recognition, no external API
- On recognition complete → same `GET /v1/products?q=<term>` call as text search
- Microphone icon shown inside search bar

### Search Scope
- Searches across: product name, description, subcategory name
- Does NOT search categories (too broad)
- Empty query → show trending products

---

## 22. Observability & Analytics (Stack Alignment)

### Crash Reporting — Firebase Crashlytics
```dart
// main.dart — catches all Flutter errors
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### Analytics — PostHog
Key events to track across all screens:

| Event | Properties | Trigger |
|---|---|---|
| `screen_viewed` | screen_name | Every GoRouter navigation |
| `product_viewed` | product_id, category | Product detail opened |
| `add_to_cart` | variant_id, price | Item added to cart |
| `checkout_started` | cart_total, item_count | Checkout page opened |
| `order_placed` | order_id, total, payment_method | Order confirmed |
| `search_performed` | query, result_count | Search executed |
| `voice_search_used` | query | Voice result accepted — **not implemented**; deliberately skipped when voice search shipped 2026-07-18 (not worth tracking at current volume, see `Milestone readme/Voice Search.md`) |

### Error Tracking — Sentry (Backend)
- All Hono Edge Function errors captured
- Payment flow errors flagged as high-priority
- See backend_stack.md Section 15

### Rate Limiting — Upstash Redis (Backend)
- Applied on: `/v1/products` (public), `/v1/cart/checkout`, auth routes
- See backend_stack.md Section 14

---

## 23. Deep Linking — app_links

Deep links allow URLs to open the app at the correct screen:

| URL | Opens |
|---|---|
| `bakerally.in/products/:id` | Product detail screen |
| `bakerally.in/orders/:id` | Order detail screen |
| `bakerally.in/verify?token=x` | Email verification handler |
| `bakerally.in/reset?token=x` | Password reset handler |

```dart
// main.dart
final appLinks = AppLinks();
appLinks.uriLinkStream.listen((uri) {
  router.go(uri.path, extra: uri.queryParameters);
});
```

---

## 24. Background Sync — Workmanager

Workmanager runs background tasks when the app is closed or minimised:

```dart
// Registered on app init
Workmanager().registerPeriodicTask(
  'catalog-sync',
  'syncCatalog',
  frequency: Duration(hours: 1),
  constraints: Constraints(networkType: NetworkType.connected),
);

// Task handler
void callbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    if (taskName == 'syncCatalog') {
      await CatalogSyncService().sync(); // fetches products → updates Drift
    }
    return Future.value(true);
  });
}
```

Syncs:
- Product catalog (prices, stock, new items)
- Active orders (status updates)
- Queued analytics events (PostHog offline queue)

---

## 25. Entity Relationship Diagram (ERD)

```
┌─────────────────┐       ┌─────────────────┐       ┌──────────────────────┐
│  privilege_levels│◄──┐  │     roles        │◄──┐  │        users         │
│─────────────────│   │  │─────────────────│   │  │──────────────────────│
│ id (PK)         │   │  │ id (PK)          │   │  │ id (PK)              │
│ name            │   │  │ name             │   │  │ email                │
│ description     │   └──│ privilege_level_id│   └──│ role_id (FK)         │
└────────┬────────┘      └─────────────────┘      │ privilege_level_id(FK)│
         │                                          │ full_name            │
         │ (1 to many)                              │ business_name        │
         ▼                                          │ gstin                │
┌──────────────────────────┐                       │ avatar_url           │
│ privilege_level_permissions│                      │ is_active            │
│──────────────────────────│                       └──┬──────────┬────────┘
│ id (PK)                  │                          │          │
│ privilege_level_id (FK)  │                          │          │
│ object_name              │                          │          │
│ can_read                 │              ┌───────────┘          │
│ can_edit                 │              │                       │
│ field_overrides (JSONB)  │              ▼                       ▼
│ record_scope             │    ┌──────────────────┐   ┌──────────────────┐
└──────────────────────────┘    │    addresses     │   │    wishlists     │
                                │──────────────────│   │──────────────────│
                                │ id (PK)          │   │ id (PK)          │
                                │ user_id (FK)     │   │ user_id (FK)     │
                                │ label            │   │ variant_id (FK)  │
                                │ line1, city ...  │   └──────────────────┘
                                │ is_default       │
                                └──────────────────┘


┌──────────────┐    ┌─────────────────┐    ┌──────────────────┐    ┌────────────────────┐
│  categories  │    │  sub_categories │    │    products      │    │  product_variants  │
│──────────────│    │─────────────────│    │──────────────────│    │────────────────────│
│ id (PK)      │◄───│ category_id(FK) │◄───│ sub_category_id  │◄───│ product_id (FK)    │
│ name         │    │ id (PK)         │    │ id (PK)          │    │ id (PK)            │
│ image_url    │    │ name            │    │ name             │    │ name (500g, 1kg)   │
│ sort_order   │    │ image_url       │    │ description      │    │ sku (UNIQUE)       │
│ is_active    │    │ sort_order      │    │ is_active        │    │ original_price     │
└──────────────┘    │ is_active       │    │ is_trending      │    │ current_price      │
                    └─────────────────┘    │ sort_order       │    │ stock_qty          │
                                           └──────────────────┘    │ is_active          │
                                                    │               └────────┬───────────┘
                                                    │                        │
                                                    ▼                        ▼
                                           ┌──────────────────┐    ┌────────────────────┐
                                           │  product_images  │    │     cart_items     │
                                           │──────────────────│    │────────────────────│
                                           │ id (PK)          │    │ id (PK)            │
                                           │ product_id (FK)  │    │ cart_id (FK)       │
                                           │ variant_id (FK?) │    │ variant_id (FK)    │
                                           │ public_url       │    │ quantity           │
                                           │ is_primary       │    └────────┬───────────┘
                                           │ sort_order       │             │
                                           └──────────────────┘             │
                                                                             ▼
                                                                    ┌──────────────────┐
                                                                    │      carts       │
                                                                    │──────────────────│
                                                                    │ id (PK)          │
                                                                    │ user_id (FK, UNIQ│
                                                                    └──────────────────┘


┌──────────────┐    ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  discounts   │    │      orders      │    │   order_items    │    │    shipments     │
│──────────────│    │──────────────────│    │──────────────────│    │──────────────────│
│ id (PK)      │◄───│ discount_id (FK?)│    │ id (PK)          │    │ id (PK)          │
│ code         │    │ id (PK)          │◄───│ order_id (FK)    │    │ order_id (FK)    │
│ type         │    │ user_id (FK)     │    │ variant_id (FK)  │    │ shiprocket_id    │
│ value        │    │ address_id (FK)  │    │ product_name ✱   │    │ awb              │
│ is_active    │    │ status           │    │ variant_name ✱   │    │ carrier          │
│ expires_at   │    │ subtotal         │    │ quantity         │    │ status           │
└──────────────┘    │ discount_value   │    │ unit_price ✱     │    │ tracking_url     │
                    │ shipping_cost    │    └──────────────────┘    └──────────────────┘
                    │ total            │
                    │ razorpay_order_id│    ✱ = snapshot at order time (immutable)
                    │ razorpay_pmt_id ◆│
                    └──────────────────┘    ◆ = UNIQUE constraint


┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  notifications   │    │  brownie_points  │    │  webhook_events  │
│──────────────────│    │──────────────────│    │──────────────────│
│ id (PK)          │    │ id (PK)          │    │ id (PK)          │
│ user_id (FK)     │    │ user_id (FK)     │    │ source           │
│ channel          │    │ points (+/-)     │    │ event_id ◆       │
│ type             │    │ reason           │    │ payload (JSONB)  │
│ title, body      │    │ order_id (FK?)   │    │ processed_at     │
│ is_read          │    └──────────────────┘    └──────────────────┘
│ sent_at          │
└──────────────────┘


┌──────────────────┐
│ product_discounts│   ← joins products/variants to discounts
│──────────────────│
│ id (PK)          │
│ product_id (FK?) │
│ variant_id (FK?) │
│ discount_id (FK) │
└──────────────────┘
```

**Key relationships summary:**

| From | To | Type |
|---|---|---|
| users → roles | Many-to-one | Each user has one role |
| users → privilege_levels | Many-to-one (optional) | User-level override, nullable |
| roles → privilege_levels | Many-to-one (optional) | Role-level default, nullable |
| categories → sub_categories | One-to-many | |
| sub_categories → products | One-to-many | |
| products → product_variants | One-to-many | Each variant = size/weight option |
| products → product_images | One-to-many | variant_id nullable (shared or per-variant) |
| users → carts | One-to-one | One active cart per user |
| carts → cart_items | One-to-many | |
| cart_items → product_variants | Many-to-one | |
| users → orders | One-to-many | |
| orders → order_items | One-to-many | Snapshot at order time |
| orders → shipments | One-to-one | |
| orders → discounts | Many-to-one (optional) | |
| product_variants → stock_notify_requests | One-to-many | Not diagrammed above (added after the ERD was drawn) — see §12a |
| products → product_reviews | One-to-many | Not diagrammed above — see §5a |
| order_items → product_reviews | One-to-one (optional) | The specific purchase that proves eligibility; one review per (user, product) via the UNIQUE constraint, not per order_item |

---

## Next Steps — Tab Architecture Files

```
Architecture/
  00_common_architecture.md     ← this file
  01_home_tab.md                ← Milestone 5.5
  02_catalog_tab.md             ← Milestone 2
  03_order_again_tab.md         ← Milestone 5
  04_brownie_points_tab.md      ← placeholder, to be created later
  05_cart_and_checkout.md       ← Milestone 3
  06_profile_and_account.md     ← Milestone 5
  07_admin_web_panel.md         ← to be created
```
