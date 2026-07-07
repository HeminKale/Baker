# Baker Ally — Technical Phase Plan
> For: Engineering team
> Purpose: What to build, in what order, with what acceptance criteria
> Last updated: July 2026

---

## Overview

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7
Foundation  Catalog   Cart &    Orders &   Account   Admin     Polish &
            & Search  Payments  Fulfill.   & Discov.  Panel    Launch

  Week 1-2   Week 3-4  Week 5-6  Week 7-8   Week 9-10  Week 11-12  Week 13-14
```

Each phase produces working, testable code — not partial features. A phase is done only when all its acceptance criteria pass.

---

## Dependency Chain

```
                    ┌─────────────────────────────────────────────────┐
                    │                  Phase 1                         │
                    │   Foundation: DB + Auth + Project Scaffold       │
                    └────────────────────┬────────────────────────────┘
                                         │ all phases depend on Phase 1
              ┌──────────────────────────┼──────────────────────────┐
              ▼                          ▼                           ▼
    ┌─────────────────┐       ┌─────────────────┐        (admin panel
    │    Phase 2      │       │    Phase 2       │         needs Phase 3)
    │  Catalog +      │       │  (same — must    │
    │  Search         │       │  complete before  │
    └────────┬────────┘       │  Phase 3)        │
             │                └─────────────────┘
             ▼
    ┌─────────────────┐
    │    Phase 3      │
    │  Cart +         │
    │  Payments       │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │    Phase 4      │
    │  Orders &       │
    │  Fulfillment    │
    └────────┬────────┘
             │
    ┌────────┴────────────────┐
    ▼                         ▼
┌──────────────┐     ┌────────────────┐
│   Phase 5    │     │    Phase 6     │
│  Account &   │     │  Admin Web     │
│  Discovery   │     │  Panel         │
└──────┬───────┘     └───────┬────────┘
       └──────────┬──────────┘
                  ▼
         ┌────────────────┐
         │    Phase 7     │
         │  Polish &      │
         │  Launch        │
         └────────────────┘
```

---

## Phase 1 — Foundation
**Duration:** Week 1–2
**Goal:** Everything required before any feature can be built. No UI beyond login.

### What gets built

#### 1.1 Project Scaffold
- Flutter project initialised with all approved packages from `flutter_library_stack.md`
- Folder structure: `lib/features/`, `lib/core/`, `lib/shared/`
- Riverpod setup, GoRouter configured with placeholder routes
- Dio instance with JWT interceptor wired to `flutter_secure_storage`
- `envied` configured — `.env` file with Supabase URL and anon key

#### 1.2 Supabase Setup
- Supabase project created (Pro plan)
- All Phase 1 tables migrated via Supabase CLI:
  ```
  roles, privilege_levels, privilege_level_permissions,
  users, addresses
  ```
- JWT custom claim hook configured — role name written into `app_metadata`
- Supavisor pooler connection string (port 6543) configured as `DB_POOL_URL`
- Supabase Storage bucket `product-images` created (public)
- Staging Supabase project created — mirrors production schema

#### 1.3 Hono Backend Scaffold
- Supabase Edge Functions project initialised
- `index.ts` with Hono app, `authMiddleware`, `adminMiddleware`
- Health check endpoint: `GET /v1/health`
- Auth endpoint: `POST /v1/auth/me` — returns user profile + role from JWT
- Zod validation middleware wired
- Drizzle schema file created matching all current tables
- Upstash Redis connected — rate limiting middleware ready
- Sentry initialised — all unhandled errors captured
- All secrets set in Supabase dashboard

#### 1.4 Authentication (Flutter)
- Login screen: phone OTP input → verify OTP
- Google Sign-In button
- On success: JWT stored in `flutter_secure_storage`
- On login: `POST /v1/auth/me` called to hydrate `authProvider` + `profileProvider`
- Logout: clears JWT, Drift, navigates to `/login`
- GoRouter `redirect` guard: unauthenticated → `/login`

#### 1.5 User Profile API
- `GET /v1/users/me` — returns user + role
- `PATCH /v1/users/me` — update name, business name, GSTIN
- `POST /v1/users/fcm-token` — stores FCM device token
- On new signup: Edge Function hook creates `users` row with `customer_individual` role

### Acceptance Criteria
- [ ] User can sign up via OTP, receives JWT, is stored in `users` table with correct role
- [ ] User can sign in via Google
- [ ] JWT contains role claim — verified in Hono middleware
- [ ] Non-authenticated requests to protected routes return 403
- [ ] User can log out — JWT cleared, Drift cleared, redirected to login
- [ ] `GET /v1/health` returns 200 from Edge Function
- [ ] Staging environment mirrors production schema

### Schema Migrations (Phase 1)
```sql
-- Roles seeded
INSERT INTO roles (name) VALUES ('customer_individual'), ('admin');
```

---

## Phase 2 — Catalog & Search
**Duration:** Week 3–4
**Depends on:** Phase 1 complete
**Goal:** Full product catalog browsable in Flutter. Admin can seed data via SQL/Supabase dashboard.

### What gets built

#### 2.1 DB Tables
```
categories, sub_categories, products,
product_variants, product_images
```
All indexes from architecture doc created.

#### 2.2 Catalog APIs
```
GET /v1/categories                              — all active categories + subcategory count
GET /v1/categories/:id/subcategories            — subcategories for a category
GET /v1/products?subCategoryId=&page=&limit=    — products for subcategory, paginated
GET /v1/products?categoryId=&page=&limit=       — all products for category (all subcats)
GET /v1/products/:id                            — product detail with variants + images
GET /v1/products?q=&page=&limit=                — full-text search
GET /v1/products/:id/related                    — products in same subcategory
```

Full-text search: Postgres `tsvector` on `products.name + description + sub_categories.name`

#### 2.3 Catalog Flutter Screens
- **Catalog tab Level 1** — categories as section headings, subcategory horizontal tiles
- **Catalog tab Level 2** — 5% left subcategory strip + 95% product grid, scroll-spy sync
- **Catalog tab Level 3 — Product detail** — swipeable image gallery, variant chips, pricing, fixed Add to Cart CTA
- **Global search** — icon on all pages (except Home where bar is default), `speech_to_text` mic button
- Product tile component — image, name, variant, price, strike-price, badges (Trending / Low Stock / Out of Stock / New / Sale), Add to Cart button → stepper

#### 2.4 Drift Caching
- Categories + subcategories cached in Drift on first load
- Products per category cached in Drift
- `Workmanager` hourly background sync registered

#### 2.5 Wishlist (DB only — UI in Phase 5)
- `wishlists` table created
- `POST /v1/wishlist { variantId }` and `DELETE /v1/wishlist/:variantId` endpoints ready
- Wishlist heart on product detail page (functional, data persisted)

### Acceptance Criteria
- [ ] All 6 categories + subcategories render correctly from DB — no hardcoded values in Flutter
- [ ] Left strip + product grid scroll-spy sync works in both directions
- [ ] Product tile badges render correctly based on DB flags
- [ ] Variant selection updates price, stock status, and Add button correctly
- [ ] Search returns relevant results within 800ms (p99)
- [ ] Voice search triggers text search correctly
- [ ] Catalog data served from Drift cache when offline — "Last updated X hours ago" shown if stale
- [ ] Product images load via `cached_network_image` with shimmer placeholder

---

## Phase 3 — Cart & Payments
**Duration:** Week 5–6
**Depends on:** Phase 2 complete
**Goal:** User can add items to cart and complete a payment. End-to-end happy path working.

### What gets built

#### 3.1 DB Tables
```
carts, cart_items, discounts, product_discounts
```

#### 3.2 Cart APIs
```
GET    /v1/cart                         — load server cart (on login / app open)
POST   /v1/cart/items                   — add item { variantId, quantity }
PATCH  /v1/cart/items/:id               — update quantity
DELETE /v1/cart/items/:id               — remove item
DELETE /v1/cart                         — clear cart (after order confirmed)
POST   /v1/cart/merge                   — merge guest (local) items on login
GET    /v1/checkout/recommendations     — "you might also like" ?variantIds=...
POST   /v1/discounts/validate           — validate discount code { code, cartTotal }
```

#### 3.3 Checkout API (order creation — two-step)
```
POST   /v1/cart/checkout
  → validates all prices server-side (if changed → 409 with updated prices)
  → creates orders row with status = 'pending' + razorpay_order_id
  → snapshots cart into order_items
  → creates Razorpay order
  → returns { orderId, razorpayOrderId, amount, keyId }

POST   /v1/orders/:id/confirm
  → verifies HMAC signature (razorpayOrderId + razorpayPaymentId)
  → updates order status to 'confirmed'
  → stores razorpay_payment_id (UNIQUE — prevents duplicate confirmation)
  → enqueues job to pgmq 'order_events' queue
  → returns 201 immediately
```

#### 3.4 Razorpay Webhook
```
POST /v1/webhooks/razorpay
  → verifies signature
  → checks webhook_events dedup (source + event_id UNIQUE)
  → handles payment.failed → marks order cancelled
```

#### 3.5 Cart Flutter
- Add to cart interaction: button → stepper (AnimatedSwitcher, 150ms)
- Qty to 0 → stepper → button reverse animation
- Cart badge on bottom nav (live, from `cartProvider.totalItems`)
- Guest cart: items stored in Drift only — no server call until login
- On login: `POST /v1/cart/merge` with local items

#### 3.6 Checkout Flutter Page
- Single scrollable page:
  1. Items in cart with inline qty stepper
  2. You Might Also Like (horizontal scroll)
  3. Bill Details (subtotal, discount line, delivery, total)
  4. Discount code input + Apply/Remove states
  5. Cancellation policy text
- Fixed bottom CTA:
  ```
  Row 1: 📍 [Address label]              [Change]
  Row 2: 💳 [Payment mode] ∧  ₹Total   [Proceed →]
  ```
- Address selector bottom sheet (85% height) — radio select
- Payment mode bottom sheet (85% height) — UPI / Card / Netbanking
- Price re-validation: if prices changed since cart was built → banner shown before Razorpay opens

#### 3.7 Order Confirmation Screen
- Clears cart (Drift + server)
- Shows order ID, total paid, WhatsApp confirmation note, estimated delivery
- No back navigation to checkout

### Acceptance Criteria
- [ ] Guest user can add items, log in, and see items merged into cart
- [ ] Qty stepper animates correctly — qty 0 reverts to Add button
- [ ] Server-side price re-validation catches changed prices before payment opens
- [ ] Razorpay payment sheet opens with correct amount
- [ ] Successful payment creates `confirmed` order in DB
- [ ] `razorpay_payment_id` UNIQUE constraint rejects duplicate confirmations
- [ ] Webhook dedup prevents double-processing of Razorpay events
- [ ] Discount code applies correctly — bill updates live
- [ ] Cart cleared after successful order

---

## Phase 4 — Orders & Fulfillment
**Duration:** Week 7–8
**Depends on:** Phase 3 complete
**Goal:** Orders flow to Shiprocket, customers get WhatsApp + push updates automatically.

### What gets built

#### 4.1 DB Tables
```
shipments, notifications, webhook_events (already exists from Phase 3)
```

#### 4.2 Supabase Queues (pgmq)
- Enable pgmq via Supabase dashboard
- Create queue: `order_events`
- Background worker Edge Function (triggered by Supabase Cron every 30s):
  - Reads from `order_events` queue
  - Calls Shiprocket API → creates shipment → stores AWB
  - Calls Interakt API → sends WhatsApp "order confirmed" template
  - Calls Firebase Admin → sends FCM push notification

#### 4.3 Shiprocket Integration
```
POST to Shiprocket: create shipment on order confirmed
  → store shiprocket_order_id + awb in shipments table

POST /v1/webhooks/shiprocket
  → verifies source IP (Shiprocket allowlist)
  → dedup via webhook_events table
  → updates shipments.status
  → updates orders.status
  → enqueues notification job
```

#### 4.4 Interakt (WhatsApp) Integration
Triggered by queue worker:
```
order_confirmed  → template: "Your Baker Ally order #X is confirmed. Total: ₹X"
shipped          → template: "Your order is on the way! Track: [AWB link]"
out_for_delivery → template: "Your order will be delivered today"
delivered        → template: "Order delivered! How was your experience?"
```
All templates pre-approved by Meta before deployment.

#### 4.5 FCM Push Notifications
- `firebase-admin` initialised in Edge Function
- Same 4 triggers as WhatsApp — parallel send
- Notification tap → deep links to `/orders/:id` via `app_links`

#### 4.6 Notification Bell (Flutter)
- `GET /v1/notifications/unread-count` polled every 30s
- Bell badge updates in top bar
- On tap: `GET /v1/notifications?page=1&limit=20` → bottom sheet
- `PATCH /v1/notifications/:id` marks as read

#### 4.7 Order APIs
```
GET /v1/orders?page=&limit=             — user's order history
GET /v1/orders?status=active            — in-progress orders only
GET /v1/orders/:id                      — order detail + items + shipment
```

### Acceptance Criteria
- [ ] After payment, queue job fires within 60s — Shiprocket shipment created
- [ ] WhatsApp message delivered to test number on each order status change
- [ ] FCM push received on test device on each status change
- [ ] Shiprocket webhook updates order status in DB correctly
- [ ] Webhook dedup: same Shiprocket event delivered twice → only processed once
- [ ] Notification bell shows correct unread count
- [ ] Order history renders in Flutter with correct status badges
- [ ] Deep link from push notification opens correct order detail screen

### Fulfillment Flow Diagram
```
Order confirmed (DB)
         │
         ▼
  pgmq 'order_events'
         │
         ▼ (Cron worker, every 30s)
  ┌──────┴────────────────────┐
  │                           │
  ▼                           ▼
Shiprocket API          Interakt API + FCM
(create shipment)       (WhatsApp + push)
  │
  ▼
AWB stored in shipments table
  │
  ▼ (webhook from Shiprocket)
Order status updated
  │
  ▼
Notification enqueued → WhatsApp + push sent
```

---

## Phase 5 — Account & Discovery
**Duration:** Week 9–10
**Depends on:** Phase 4 complete
**Goal:** Repeat purchase features, full profile management, Order Again tab.

### What gets built

#### 5.1 Profile (Flutter + API)
- Profile bottom sheet (avatar, name, GSTIN, business name)
- Edit profile screen — avatar upload to Supabase Storage
- `PATCH /v1/users/me` — all profile fields
- Avatar upload: `avatars/{user_id}.webp` in Supabase Storage

#### 5.2 Addresses (Flutter + API)
```
GET    /v1/addresses
POST   /v1/addresses
PATCH  /v1/addresses/:id
DELETE /v1/addresses/:id
```
- Address list screen with default badge
- Address form using `flutter_form_builder`
- Set as default — server enforces single default

#### 5.3 Wishlist (Flutter)
- Wishlist screen (grid) — APIs already built in Phase 2
- Heart icon on product detail (optimistic update)
- Wishlist synced across devices via DB

#### 5.4 Order Again Tab (Flutter + API)
```
GET /v1/order-again/frequently-bought
  → user's own order groups first, then platform-wide
  → precomputed nightly via Supabase Cron + materialised table
  → endpoint reads precomputed results — no heavy on-request computation

GET /v1/order-again/previously-bought?page=&limit=20
  → DISTINCT variants from user's order history, sorted by last order date
```
- Frequently Bought Together: horizontal scroll of group tiles
- Group detail bottom sheet: per-item qty stepper, selective add to cart
- Previously Bought: 2-column grid, "Last bought: X" label, same stepper interaction

#### 5.5 Frequently Bought Together — Precomputation
```sql
-- Nightly job (Supabase Cron at 2am)
-- Computes co-occurrence groups, ranks by frequency
-- Stores results in: order_group_cache table
-- Edge Function endpoint reads from cache — not computed on request
-- (avoids hitting 2s CPU budget in Edge Functions)
```

New table:
```
order_group_cache   — user_id (nullable = platform), variant_ids JSONB,
                      frequency, product_details JSONB, updated_at
```

#### 5.6 Receipts & Invoices
```
GET /v1/orders?paid=true    — paid orders list
GET /v1/orders/:id/invoice  — returns signed Supabase Storage URL to PDF
```
PDF generated server-side by Edge Function (using a PDF library), stored in Supabase Storage, returned as signed URL.

#### 5.7 Profile Screens
All profile overlay screens functional:
- Your Orders, Order Status, Wishlist, Receipts, Addresses, Contact Us, Help, Log Out

### Acceptance Criteria
- [ ] Avatar upload stores webp in Supabase Storage, URL updates in profile card
- [ ] Wishlist persists across devices (DB-backed, not local-only)
- [ ] Frequently Bought Together shows user's own groups first, platform groups fill to 10
- [ ] Group detail bottom sheet: qtys adjustable, out-of-stock items disabled
- [ ] "Add all to cart" adds at qty 1, sheet closes, cart badge updates
- [ ] Previously Bought shows last-bought date, infinite scroll works
- [ ] Invoice PDF accessible from Receipts screen

---

## Phase 6 — Admin Web Panel
**Duration:** Week 11–12
**Depends on:** Phase 3+ (needs orders to exist)
**Goal:** Admin can fully manage the store without touching Supabase dashboard.

### What gets built

#### 6.1 Next.js Project Setup
- Next.js 14 App Router, TypeScript, shadcn/ui, Tailwind CSS
- Supabase Auth wired — admin login via OTP / Google
- JWT sent on all fetch calls — same Hono middleware verifies role
- Mobile-responsive layout

#### 6.2 Product & Catalog Management
- Category list + create/edit/deactivate
- Subcategory list + create/edit/deactivate
- Product list (filterable by category, subcategory, active/inactive)
- Product create/edit form:
  - Name, description, subcategory, is_active, is_trending
  - Variant management: add/edit/remove variants (name, SKU, original_price, current_price, stock_qty)
  - Image upload per product/variant — drag and drop, webp conversion, Supabase Storage
- Bulk stock update

#### 6.3 Order Management
- Order list (filterable by status, date range, search by order ID / customer name)
- Order detail: items, customer, address, payment, shipment status
- Manual order status update (processing → shipped for non-Shiprocket orders)
- Order cancel button (pre-shipment)

#### 6.4 Discount Management
- Discount list + create/edit
- Fields: code, type (percent/flat/free_shipping), value, min order, max uses, expiry, active toggle
- Product-specific discounts: link discount to product or variant

#### 6.5 User Management (Settings)
```
Settings page — vertical tabs:
  ├── Profiles        — list of role profiles, create/edit
  ├── Users           — list all users, invite user (sends OTP), assign role
  └── Privilege Levels — list, create, edit
        Privilege Level editor:
          ├── Name + description
          ├── Object selector (dropdown of table names)
          └── Field list with Read / Edit checkboxes
                (Edit auto-checks Read)
                Record scope: own / all
```

#### 6.6 Admin API Endpoints
```
POST   /v1/admin/categories
PUT    /v1/admin/categories/:id
POST   /v1/admin/sub-categories
PUT    /v1/admin/sub-categories/:id
POST   /v1/admin/products
PUT    /v1/admin/products/:id
POST   /v1/admin/products/:id/images
DELETE /v1/admin/products/:id/images/:imgId
PATCH  /v1/admin/variants/:id/stock
POST   /v1/admin/discounts
PUT    /v1/admin/discounts/:id
GET    /v1/admin/orders?status=&from=&to=&q=
PATCH  /v1/admin/orders/:id/status
GET    /v1/admin/users
POST   /v1/admin/users/invite
PATCH  /v1/admin/users/:id/role
```

### Acceptance Criteria
- [ ] Admin can log in — customer JWT on admin routes returns 403
- [ ] Admin can create product with variants and images — appears in Flutter app catalog
- [ ] Admin can update stock_qty — "Out of Stock" badge reflects on Flutter app
- [ ] Admin can create discount code — applies correctly in checkout
- [ ] Admin can view and manually update order status
- [ ] Privilege Level editor: saving a level stores correct field_overrides JSONB
- [ ] All admin pages mobile-responsive

---

## Phase 7 — Polish & Launch
**Duration:** Week 13–14
**Goal:** App Store + Play Store submission ready. Production-grade hardening.

### What gets built

#### 7.1 Performance
- Flutter: profile mode testing — no jank on catalog scroll, cart animation
- Left strip scroll-spy: optimize `ScrollController` listener, debounce
- Image loading: verify shimmer placeholders on all image surfaces
- API: k6 load test at 1,000 concurrent users → p99 < 800ms target

#### 7.2 CI/CD
- Codemagic configured for Flutter: builds, signs, uploads to TestFlight + Play Internal
- Vercel auto-deploy connected to `main` branch (admin web — already works by default)
- Supabase CLI migration step in CI pipeline before Edge Function deploy
- GitHub Actions or Codemagic: run `flutter test` on every PR

#### 7.3 App Store & Play Store Setup
- Apple Developer account — provisioning profile, App Store Connect app record
- Google Play Console — app created, signing keystore stored in Codemagic
- App icons, splash screens, screenshots prepared
- Privacy policy URL (required by both stores)
- TestFlight build distributed to internal testers

#### 7.4 Production Hardening
- Razorpay live keys set in Supabase secrets (replace test keys)
- Interakt WhatsApp templates approved by Meta
- Rate limiting verified: `/v1/products`, `/v1/cart/checkout` limits tested
- Sentry alerts configured: payment failure → immediate Slack/email alert
- Supabase DB backups verified (Pro plan daily backups)
- Staging → Production migration runbook written

#### 7.5 Monitoring Setup
- PostHog events verified for all key flows (add to cart, checkout, order placed)
- Firebase Crashlytics live — test crash triggered and verified in dashboard
- Sentry Edge Function errors verified

### Acceptance Criteria
- [ ] Flutter app passes App Store review guidelines checklist
- [ ] k6 load test: p99 < 800ms at 1,000 concurrent users on `/v1/products`
- [ ] Razorpay live payment end-to-end tested with real ₹1 transaction
- [ ] WhatsApp messages delivered on live order flow
- [ ] Codemagic auto-build triggers on `main` push → TestFlight upload
- [ ] Crashlytics receives a test crash within 5 minutes
- [ ] All environment secrets confirmed as production values (no test keys in prod)

---

## Summary Table

| Phase | Duration | Deliverable | Key Dependency |
|---|---|---|---|
| 1 — Foundation | Week 1–2 | Auth, DB scaffold, Hono scaffold | None |
| 2 — Catalog & Search | Week 3–4 | Full browsable catalog in Flutter | Phase 1 |
| 3 — Cart & Payments | Week 5–6 | End-to-end purchase flow | Phase 2 |
| 4 — Orders & Fulfillment | Week 7–8 | Shiprocket + WhatsApp + Push | Phase 3 |
| 5 — Account & Discovery | Week 9–10 | Profile, Wishlist, Order Again | Phase 4 |
| 6 — Admin Web Panel | Week 11–12 | Full store management UI | Phase 3 |
| 7 — Polish & Launch | Week 13–14 | App Store ready, load tested | Phase 5 + 6 |

**Total: 14 weeks** (with single developer — parallelise Phase 5 + 6 with a second developer to reduce to ~12 weeks)

---

## Risk Register

| Risk | Phase | Mitigation |
|---|---|---|
| Left strip scroll-spy performance | 2 | Budget extra time; debounce listeners |
| Razorpay test → live key switch | 7 | Verify early in Phase 3, not at Phase 7 |
| Interakt template approval delay (1–2 days Meta review) | 4 | Submit templates at start of Phase 4, not end |
| App Store rejection | 7 | Review Apple guidelines before Phase 7; test on real device throughout |
| Shiprocket sandbox vs live API differences | 4 | Test against Shiprocket sandbox in Phase 4; live in Phase 7 |
| Porter integration (not yet planned) | Post-launch | Architecture placeholder exists; does not block launch |
| Brownie Points (not yet designed) | Post-launch | Placeholder tab ships in Phase 2; feature added post-launch |
