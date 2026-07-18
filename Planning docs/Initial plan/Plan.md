# Baker Ally — Full Production Stack Plan

> **Superseded note (2026-07-12):** This is the original planning draft. Current source of truth is `Phase_Plan_Technical.md` + `Architecture/*.md`. One decision made since this doc was written: **no Interakt/WhatsApp Business API integration** — order-status updates are in-app notifications + Firebase push (FCM) only; Shiprocket sends its own WhatsApp/SMS delivery updates independently. All "WhatsApp"/"Interakt" mentions below are historical and no longer planned.
> **Do-not-cite note (2026-07-18):** this entire document is an early draft, superseded before any milestone was built, and should not be shown externally or treated as describing current state — too much of it is now factually wrong, not just "decided differently." Specifics found in a doc-vs-code audit:
> - **§"WhatsApp \| Interakt (locked)"** (further down) directly contradicts the superseded note above it — Interakt was cancelled, not locked. The architecture diagram near the bottom still draws Interakt as a live integration box.
> - **"Next.js 14 (App Router)"** — the actual admin panel (Milestone 6) is built on **Next.js 16**, which has real breaking-change implications (`middleware.ts` → `proxy.ts`, async-only `cookies()`/`headers()`) not reflected anywhere in this doc.
> - **Zod, Supabase Queues (pgmq), the in-app notification bell** — all described here as built/standard. None exist in the actual codebase: Zod validation was never adopted (routes validate manually), pgmq/background workers were never built (Phase 4 is deferred), the notification bell needs the `notifications` table which doesn't exist.
> - **Database schema section** lists `shipments`, `notifications`, `brownie_points` tables as current — none exist. Phase 4 (Shiprocket/fulfillment) is deferred pending the Porter-vs-Shiprocket decision; Brownie Points remains a placeholder tab only.
> - **CI/CD table** (Codemagic, Vercel auto-deploy) describes both as already operational — neither is set up as of 2026-07-18 (see `Milestone readme/18 July pending steps.md`).
> - **API route examples** use unversioned paths (`/auth/verify`, `/admin/products`); the real API is versioned (`/v1/auth/me`, `/v1/admin/products`).
> For a current, accurate picture, use `Phase_Plan_Technical.md`, `backend_stack.md`, `flutter_library_stack.md` (both already carry their own 2026-07-18 status notes), and the per-milestone docs in `Milestone readme/`.

## Context

Baker Ally is a product marketplace app for India — 10,000 concurrent users. Customers use a Flutter mobile app (iOS + Android) to browse, order, and pay. Admins manage the entire store from a web browser. A Node.js backend on Supabase Edge Functions handles all business logic — payments, shipping, WhatsApp notifications, and order processing.

---

##  App Overview

### Product
| General information | Plan |
|---|---|
| App type | B2B and B2C marketplace — single seller store |
| App users | Home bakers and small bakery businesses |
| Concurrent users | 10,000 |
| GST model | B2C — GST included in price, B2B can enter GSTIN of their firm |
| Admin access | Web browser only — Next.js admin panel, zero admin code in Flutter app |

### Frontend
| Functionality | Tech stack |
|---|---|
| Framework | Flutter (iOS + Android) — single codebase |
| State management | Riverpod |
| Navigation | GoRouter |
| Networking | Dio (all API calls — no direct DB from Flutter) |
| Local cache | Drift (SQLite on device — offline support + instant UI) |
| Auth (client) | `supabase_flutter` — auth only (OTP, Google Sign-In, JWT issuance) |
| Payments (client) | `razorpay_flutter` — opens Razorpay sheet |
| Voice search | `speech_to_text` — on-device, no API cost |
| Push notifications | `firebase_messaging` (FCM) |
| Analytics | PostHog |
| Crash reporting | Firebase Crashlytics |
| Full library stack | See `flutter_library_stack.md` |

### Backend
| Functionality | Tech stack |
|---|---|
| Runtime | Deno (Supabase Edge Functions) — full npm compatibility |
| Framework | Hono (TypeScript-first, works on Deno natively) |
| Validation | Zod (all request bodies) |
| ORM | Drizzle (type-safe queries) |
| Hosting | Supabase Edge Functions — included in Pro, no extra server |
| DB connection | Supavisor pooler port 6543, `prepare: false` — not direct 5432 |
| Async jobs | Supabase Queues (pgmq) — Shiprocket + WhatsApp + FCM run async after order |
| Rate limiting | Upstash Redis |
| Error tracking | Sentry |

### Database & Storage
| Functionality | Tech stack |
|---|---|
| Database | Supabase Postgres (Pro plan) |
| Migrations | Supabase CLI — versioned SQL files, never manual dashboard edits |
| File storage | Supabase Storage — product images, avatars, category images |
| Environments | Local (Supabase CLI) → Staging (free Supabase project) → Production (Pro) |

### Integrations (India-specific)
| Functionality | Tech stack |
|---|---|
| Payments | Razorpay (primary) — Cashfree as fallback at scale |
| Shipping | Shiprocket (pan-India) — Porter integration deferred (details TBD) |
| WhatsApp | Interakt (locked — not WATI) |
| Email | Resend — configured as Supabase Auth SMTP only, no custom email code |
| CI/CD (Flutter) | Codemagic — only needed for App Store / Play Store submission |
| Admin web hosting | Vercel (auto-deploy on git push) |

### Pending (Not Yet Decided)
| Decision | Blocks |
|---|---|
| Porter — cities, trigger rules vs Shiprocket | Shipping cost, free shipping threshold, checkout delivery ETA |
| Brownie Points — earn rate, redemption, expiry | Brownie Points tab, cart discount logic |

---

## Full Stack

### 1. Flutter Customer App

The app customers download from App Store / Play Store. Built with Flutter for iOS and Android from a single codebase. **Contains zero admin code** — it is a pure customer app.

**Full library stack:** See [flutter_library_stack.md](flutter_library_stack.md)

**Key responsibilities:**

*Discovery*
- Browse product catalog — categories → subcategories → products → variants
- Search products by text (full-text) and voice (on-device, speech_to_text)
- Filter by price range, availability; sort by relevance / price / newest

*Shopping*
- Add items to cart with quantity stepper (button → − qty + transform, no page change)
- Guest cart: browse and add without login, cart saved locally; checkout requires login
- Apply discount codes at checkout; see struck-through original price vs discounted price
- "You might also like" recommendations on checkout page

*Ordering*
- Checkout on a single page: items → recommendations → bill summary → address → payment
- Pay via Razorpay (UPI, cards, netbanking, wallets)
- Select or change delivery address from saved addresses
- Order confirmation with WhatsApp notification and estimated delivery date

*Post-order*
- Track active orders with live status (confirmed → processing → shipped → delivered)
- View full order history with re-order shortcuts
- Frequently Bought Together — tap to re-add a whole group to cart
- Previously Bought — individual items with last-bought date

*Account*
- OTP (phone) and Google Sign-In via Supabase Auth
- Manage profile: name, business name, GSTIN, avatar
- Manage multiple delivery addresses (default + others)
- Wishlist — save products, synced across devices
- View receipts and download invoice PDFs
- In-app notification bell — order and promo updates (Dio-polled, 30s interval)
- Brownie Points balance (placeholder — visible but not yet functional)

**How auth works — `supabase_flutter`:**
`supabase_flutter` handles login only — OTP (phone number), Google Sign-In, Apple Sign-In. After login, Supabase issues a JWT. That JWT is stored in `flutter_secure_storage` and Dio attaches it to every API call automatically. `supabase_flutter` does not query the database directly — all data flows through Dio → Hono backend. See [flutter_library_stack.md Section 15](flutter_library_stack.md) for full detail.

```
User logs in (supabase_flutter)
  → JWT issued by Supabase Auth
  → stored in flutter_secure_storage
  → Dio interceptor attaches JWT to every request
  → Hono backend verifies JWT on every route
```

**How data flows — Dio:**
Every screen (products, cart, orders) fetches data from the Hono backend via Dio. No direct database calls from Flutter.

**Push notifications — firebase_messaging:**
Backend triggers FCM when order status changes. Flutter receives and displays the notification. Tapping routes user to the correct order screen via GoRouter.

**Note on RevenueCat:**
RevenueCat (`purchases_flutter`) is in the base Flutter library stack but is **not needed for Baker Ally's core e-commerce flow**. Baker Ally uses Razorpay for product purchases — RevenueCat is only relevant if you later add a **premium subscription tier** (e.g. "Baker Ally Pro" with exclusive products or free delivery). It is included in the pubspec for future use but should not be initialised until a subscription model is decided.

### 2. Admin Panel — Web Only (Next.js)

All admin work happens in a web browser. No admin code exists in the Flutter app. Admins open the web panel on a laptop or phone browser, log in with the same Supabase Auth (OTP / Google), and are granted access based on their role.

**Why web-only:**
- Admin tasks (editing records, uploading images, managing 500 orders) are desktop tasks — better keyboard, larger screen, multi-tab workflow
- Zero admin code ships to customer devices
- Next.js already in the stack — no extra tooling
- Mobile-responsive design means admins can use it on a phone browser when needed
- Privilege levels (future) fit naturally in a web dashboard — this is how Shopify, Salesforce, and ERPNext are built

**What the web panel covers:**
- Product management — add, edit, pricing, variants, images
- Category management
- Discount codes
- Order management and status updates
- Stock management
- Reports and analytics view

**Tech:**
- **Framework:** Next.js 14 (App Router) + TypeScript
- **UI:** shadcn/ui + Tailwind CSS — mobile-responsive
- **Auth:** Supabase Auth (same JWT — admin role enforced by Hono, not just the UI)
- **Calls:** Same Hono backend API as Flutter app
- **Hosting:** Vercel (free tier, instant deploys)

**Privilege levels (future):**
The `role` field on users is the starting point. Baker Ally will evolve this into privilege levels — fine-grained control over which objects, fields, and records a user can access. Architecture for this is not planned yet and will be designed separately when requirements are defined.

### 4. Backend — Supabase Edge Functions
- **Runtime:** Deno (with full NPM + Node.js compatibility — all npm packages work)
- **Framework:** Hono (works on Deno natively)
- **Validation:** Zod (all request bodies validated)
- **ORM:** Drizzle (type-safe queries against Supabase Postgres)
- **Auth middleware:** Supabase JWT verification on every protected route
- **Hosting:** Supabase Edge Functions — included in Supabase Pro, no extra cost
- **Scaling:** Auto-scales globally, no server management needed

### 5. Database — Supabase Postgres
- **Host:** Supabase (Pro plan — no pausing, backups enabled)
- **Migrations:** Supabase CLI — all schema changes as versioned SQL files
- **RLS:** Enabled — customers see only their own orders, admins see everything
- **Storage:** Supabase Storage — product images, uploaded by admin

---

## Third-Party Integrations (India-specific)

### Payments — Gateway Options

All four gateways work with Supabase Edge Functions. "Supabase compatibility" means: does an npm package exist that runs on Deno with npm: imports? All four do — Supabase has no restriction on which payment gateway you use. Stripe is the only one with an official Supabase example, but that is documentation coverage, not a technical limitation.

| Gateway | Flutter SDK | Node/Deno npm package | UPI support | Transaction fee | Best for |
|---|---|---|---|---|---|
| **Razorpay** | `razorpay_flutter` (official) | `razorpay` (official) | Yes — free | Cards 2%, UPI 0% | India-first, most widely used |
| **Cashfree** | `cashfree_pg` (official) | `cashfree-pg` (official) | Yes — free | Cards 1.75%, UPI 0% | Slightly cheaper on cards |
| **PhonePe PG** | No official Flutter SDK | No official npm SDK | Yes | Custom / negotiated | High UPI volume only, raw HTTP integration required |
| **Stripe** | `flutter_stripe` (official) | `stripe` (official, Supabase has example) | No UPI support in India | Cards 2%, International 3% | International customers only |

#### Verdict per gateway

**Razorpay** — Recommended default. Best Flutter + Node SDK quality in India. Largest merchant base, best documentation, battle-tested webhook reliability. Supabase community has working examples.

**Cashfree** — Strong alternative if card transaction volume is high (saves 0.25% vs Razorpay on cards). Official SDKs on both Flutter and Node. UPI free. Slightly less mature developer tooling than Razorpay.

**PhonePe PG** — Only consider if >80% of your transactions are UPI and you want a branded PhonePe checkout experience. No official Flutter or Node SDK — you write raw HTTP with HMAC-SHA256 yourself. Adds 2–3 weeks of integration work.

**Stripe** — Not recommended as primary gateway for Baker Ally. No UPI support confirmed in India, invitation-only onboarding for Indian businesses, higher fees on international cards. Use only if you later add international customers.

#### Recommendation for Baker Ally

**Razorpay as primary. Cashfree as fallback if card fees become significant at scale.**

The integration pattern is identical for all gateways:
- Flutter: opens payment SDK → returns payment IDs to backend
- Backend (Edge Function): verifies signature → creates order → enqueues job
- Secret keys: Supabase Edge Function secrets vault only — never in Flutter

### Shipping — Shiprocket
- Backend only — Flutter never calls Shiprocket directly
- Flow: Order confirmed → backend calls Shiprocket API to create shipment → tracking ID stored in DB → status synced via Shiprocket webhook
- Supported carriers: BlueDart, Delhivery, Ecom Express (Shiprocket aggregates all)

### Porter
- contact their team directly to set up a business or enterprise account.

### ~~WhatsApp — Interakt or WATI~~
## RESOLVED (2026-07-12): No — in-app notifications + push cover this. Shiprocket sends its own WhatsApp/SMS delivery updates independently; Baker Ally doesn't build or pay for a WhatsApp Business API.

### Push Notifications — Firebase Messaging
- Backend sends FCM push via `firebase-admin` Node SDK
- Triggers: same as WhatsApp (order updates) + admin-initiated promotions

### Transactional Email — Resend
- OTP, magic link, password reset emails only — sent automatically by Supabase Auth
- Configured as Supabase Auth SMTP provider — no custom code needed
- All order updates handled by WhatsApp + push, not email

---

## Database Schema (Core Tables)

### Access & Identity
```
roles                — id, name (customer_individual | admin), privilege_level_id
privilege_levels     — id, name, description
privilege_level_permissions — id, privilege_level_id, object_name, can_read, can_edit,
                              field_overrides (JSONB), record_scope (own | all)
users                — id, email, phone, full_name, business_name, gstin, avatar_url,
                       role_id FK, privilege_level_id FK (nullable — overrides role),
                       is_active, created_at
```

### Catalog
```
categories           — id, name, image_url, sort_order, is_active
sub_categories       — id, category_id FK, name, image_url, sort_order, is_active
products             — id, sub_category_id FK, name, description,
                       is_active, is_trending, sort_order, created_at
product_variants     — id, product_id FK, name (500g / 1kg / 5L), sku UNIQUE,
                       original_price, current_price, stock_qty, is_active, sort_order
                       (prices in paise — ₹1 = 100 paise)
product_images       — id, product_id FK, variant_id FK (nullable — null = all variants),
                       storage_path, public_url, sort_order, is_primary
```

### Discounts
```
discounts            — id, code UNIQUE (nullable = auto-applied), name, type (percent | flat | free_shipping),
                       value, min_order_value, max_uses, uses_count, is_active, starts_at, expires_at
product_discounts    — id, product_id FK (nullable), variant_id FK (nullable), discount_id FK
```

### Cart & Orders
```
carts                — id, user_id FK UNIQUE (one active cart per user), created_at
cart_items           — id, cart_id FK, variant_id FK, quantity
addresses            — id, user_id FK, label (Home | Bakery | Other), line1, line2,
                       city, state, pincode, is_default
orders               — id, user_id FK, address_id FK, status (pending | confirmed | processing |
                       shipped | delivered | cancelled), subtotal, discount_id FK,
                       discount_value, shipping_cost, total, razorpay_order_id,
                       razorpay_payment_id UNIQUE, notes, created_at
                       (row created at checkout with status=pending; updated to confirmed after payment)
order_items          — id, order_id FK, variant_id FK, product_name ✱, variant_name ✱,
                       quantity, unit_price ✱  (✱ = snapshot at order time — immutable)
shipments            — id, order_id FK, shiprocket_order_id, awb (tracking number),
                       carrier, status, tracking_url, estimated_delivery
```

### Supporting
```
wishlists            — id, user_id FK, variant_id FK  UNIQUE(user_id, variant_id)
notifications        — id, user_id FK, channel (push | whatsapp | email), type,
                       title, body, is_read, sent_at
brownie_points       — id, user_id FK, points (+earned / −redeemed), reason, order_id FK
webhook_events       — id, source (razorpay | shiprocket), event_id UNIQUE,
                       payload JSONB, processed_at
```

### Required Indexes
```sql
CREATE INDEX idx_subcategories_category  ON sub_categories(category_id) WHERE is_active = true;
CREATE INDEX idx_products_subcategory    ON products(sub_category_id) WHERE is_active = true;
CREATE INDEX idx_variants_product        ON product_variants(product_id) WHERE is_active = true;
CREATE INDEX idx_product_images_product  ON product_images(product_id);
CREATE INDEX idx_orders_user_created     ON orders(user_id, created_at DESC);
CREATE INDEX idx_order_items_order       ON order_items(order_id);
CREATE INDEX idx_cart_items_cart         ON cart_items(cart_id);
CREATE INDEX idx_wishlists_user          ON wishlists(user_id);
CREATE INDEX idx_notifications_unread    ON notifications(user_id) WHERE is_read = false;
CREATE INDEX idx_brownie_points_user     ON brownie_points(user_id);
```

### Idempotency Constraints
```sql
ALTER TABLE orders         ADD CONSTRAINT orders_razorpay_payment_id_key UNIQUE (razorpay_payment_id);
ALTER TABLE webhook_events ADD CONSTRAINT webhook_source_event_key UNIQUE (source, event_id);
```

> Full annotated schema with relationships: see `Architecture/00_common_architecture.md §4 and §25 (ERD)`

---

## API Structure (Hono Backend)

```
POST   /auth/verify          — verify Supabase JWT, return user profile + role
GET    /categories           — public, paginated
GET    /products             — public, filter by category, search, sort
GET    /products/:id         — single product with variants
POST   /cart/checkout        — validate cart, apply discount, create Razorpay order
POST   /orders               — verify payment, create order, enqueue job → return 200 immediately
GET    /orders/:id           — order detail (customer sees own, admin sees all)
POST   /admin/products       — create product (admin only)
PUT    /admin/products/:id   — update price/images/stock (admin only)
POST   /admin/discounts      — create discount code (admin only)
POST   /webhooks/razorpay    — payment webhook
POST   /webhooks/shiprocket  — shipping status webhook
```

---

## Auth Flow

**Customer (Flutter app):**
```
Opens Flutter app
  → Supabase Auth — OTP or Google sign-in
  → JWT issued with role: customer
  → Stored in flutter_secure_storage
  → Dio attaches JWT to every request
  → Hono verifies JWT — customer routes only
```

**Admin (Web browser):**
```
Opens Next.js web panel
  → Supabase Auth — OTP or Google sign-in
  → JWT issued with role: admin
  → Stored in browser session
  → fetch() attaches JWT to every request
  → Hono verifies JWT + adminMiddleware checks role: admin
  → Non-admin JWT → 403 on all /admin/* routes
```

---

## CI/CD + Releases

| Layer | Tool |
|---|---|
| Flutter app (customer only) | Codemagic — builds, signs, uploads to App Store + Play Store |
| Backend (Hono) | Supabase Edge Functions — deploy via Supabase CLI |
| Admin web | Vercel — auto-deploy on push to main |
| DB migrations | Supabase CLI in CI pipeline before backend deploy |

---

## Architecture Diagram

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                              CLIENT TIER                                     ║
║                                                                              ║
║  ┌──────────────────────────────────┐  ┌────────────────────────────────────┐ ║
║  │  Flutter App (iOS + Android)     │  │  Admin Web Panel (Browser)         │ ║
║  │  Customer only — zero admin code │  │  Next.js 14 · shadcn/ui · Tailwind │ ║
║  │                                  │  │  Hosted on Vercel                  │ ║
║  │  Browse · Cart · Pay · Track     │  │                                    │ ║
║  │                                  │  │  Products · Categories · Pricing   │ ║
║  │  Riverpod · GoRouter · Dio       │  │  Orders · Discounts · Stock        │ ║
║  │  Drift · razorpay_flutter        │  │  Images · Reports                  │ ║
║  │  supabase_flutter (auth only)    │  │  Mobile-responsive for phone use   │ ║
║  └────────────────┬─────────────────┘  └──────────────────┬─────────────────┘ ║
╚═══════════════════╪════════════════════════════════════════╪══════════════════╝
              │                         │                         │
              │      ┌──────────────────┴─────────────────────┐  │
              │      │        Supabase Auth                    │  │
              │      │  OTP · Google OAuth · Apple Sign-In     │  │
              │      │  Issues signed JWT with role claim      │  │
              │      │  Flutter: stored in flutter_secure_storage  │
              │      └──────────────────┬─────────────────────┘  │
              │                         │                         │
              └─────────────────────────┴─────────────────────────┘
                                        │
                           HTTPS · Authorization: Bearer JWT
                                        │
╔═══════════════════════════════════════▼════════════════════════════════════╗
║                  BACKEND TIER — Supabase Edge Functions                     ║
║                                                                              ║
║                    Hono · Deno · TypeScript · NPM compatible                ║
║                                                                              ║
║   ┌──────────────────────────────────────────────────────────────────────┐  ║
║   │  Middleware Pipeline                                                  │  ║
║   │  authMiddleware  → verify Supabase JWT on every protected route      │  ║
║   │  adminMiddleware → check role = 'admin' claim                        │  ║
║   │  Zod             → validate + type-check every request body          │  ║
║   │  Drizzle         → type-safe SQL queries to Supabase Postgres        │  ║
║   └──────────────────────────────────────────────────────────────────────┘  ║
║                                                                              ║
║   Public              Customer (JWT)         Admin (JWT + role)             ║
║   GET /categories     GET /orders/:id        POST /admin/products           ║
║   GET /products       POST /cart/checkout    PUT  /admin/products/:id       ║
║   GET /products/:id   POST /orders           POST /admin/discounts          ║
║                                                                              ║
║   Webhooks (inbound)                                                         ║
║   POST /webhooks/razorpay    ← Razorpay calls this on payment events        ║
║   POST /webhooks/shiprocket  ← Shiprocket calls this on delivery updates    ║
╚══════════════╤═════════════════════════════════════════════════════════════╝
               │
       ┌───────┴─────────────────────────────────────────────────────┐
       │ SQL via Drizzle                              Outbound calls  │
       ▼                                                              ▼
╔══════════════════════════════╗     ╔══════════════════════════════════════╗
║      DATA TIER               ║     ║         EXTERNAL SERVICES            ║
║                              ║     ║                                      ║
║  Supabase PostgreSQL (Pro)   ║     ║  ┌─────────────────────────────────┐ ║
║  ┌──────────────────────┐    ║     ║  │ Razorpay                        │ ║
║  │ users                │    ║     ║  │ UPI · Cards · Netbanking        │ ║
║  │ categories           │    ║     ║  │ Webhook → /webhooks/razorpay    │ ║
║  │ products             │    ║     ║  └─────────────────────────────────┘ ║
║  │ variants             │    ║     ║  ┌─────────────────────────────────┐ ║
║  │ orders               │    ║     ║  │ Shiprocket                      │ ║
║  │ order_items          │    ║     ║  │ BlueDart · Delhivery · Ecom     │ ║
║  │ addresses            │    ║     ║  │ Webhook → /webhooks/shiprocket  │ ║
║  │ shipments            │    ║     ║  └─────────────────────────────────┘ ║
║  │ discounts            │    ║     ║  ┌─────────────────────────────────┐ ║
║  │ notifications        │    ║     ║  │ Interakt (WhatsApp Business)    │ ║
║  └──────────────────────┘    ║     ║  │ Order confirmed · Shipped       │ ║
║                              ║     ║  │ Out for delivery · Delivered    │ ║
║  Supabase Storage            ║     ║  └─────────────────────────────────┘ ║
║  (product + category images) ║     ║  ┌─────────────────────────────────┐ ║
║                              ║     ║  │ Firebase FCM (push)             │ ║
║  RLS — customers see only    ║     ║  │ firebase-admin Node SDK         │ ║
║  their own orders/addresses  ║     ║  └─────────────────────────────────┘ ║
╚══════════════════════════════╝     ║  ┌─────────────────────────────────┐ ║
                                     ║  │ Resend (email)                  │ ║
                                     ║  │ Welcome · Order confirm         │ ║
                                     ║  └─────────────────────────────────┘ ║
                                     ╚══════════════════════════════════════╝

─────────────────────────────────────────────────────────────────────────────
  CI / CD
─────────────────────────────────────────────────────────────────────────────
  Flutter (customer + admin)  →  Codemagic  →  App Store + Play Store
  Admin web (Next.js)        →  Vercel      →  auto-deploy on git push
  DB schema changes          →  Supabase CLI migrations before backend deploy
```

---

## Pending Decisions

These are explicitly open and must be resolved before building the affected features:

| # | Decision | Blocks |
|---|---|---|
| A | Porter integration — which cities? what triggers Porter vs Shiprocket? | Shipping cost calculation, checkout delivery estimate, free shipping threshold |
| B | Brownie points — earn rate, redemption value, expiry rules | Brownie Points tab, cart discount logic |

All other decisions are closed. See `Architecture/00_common_architecture.md §17` for the full decisions log.

---

## Production Readiness Checklist

### Security
- [ ] Ownership check `WHERE user_id = jwt_user` in every order/address route (RLS does NOT cover API routes — service-role key bypasses it)
- [ ] `Idempotency-Key` header enforced on `POST /orders` + unique constraint on `razorpay_payment_id`
- [ ] Webhook event deduplication via `webhook_events` table before processing
- [ ] Rate limiting on `/products`, `/cart/checkout`, and auth routes
- [ ] All secrets in Supabase Edge Function secrets vault — never in code

### Database
- [ ] Supavisor pooler (port 6543, `prepare: false`) used in Edge Functions — NOT direct port 5432
- [ ] Direct port 5432 used only for migrations (Supabase CLI)
- [ ] All indexes created (see schema above)

### Resilience
- [ ] POST /orders enqueues job via Supabase Queues (pgmq) — does NOT call Shiprocket/WhatsApp inline
- [ ] Background worker drains `order_events` queue via Supabase Cron
- [ ] Webhook handlers idempotent — check `webhook_events` before processing

### Observability
- [ ] Sentry configured in Edge Functions for error tracking
- [ ] Structured logging on all order + payment flows

### Performance
- [ ] p99 target: < 800ms (accounts for Edge Function cold start of 300–500ms)
- [ ] Hot paths (`/products`, `/webhooks/*`) kept warm via Supabase Cron scheduled pings

## Verification Plan

1. Auth: Customer signs up → JWT issued → Dio attaches token → backend verifies → 200
2. Catalog: Admin adds product via web panel → appears in customer Flutter app
3. Cart + Payment: Customer adds item → checkout → Razorpay test mode → order created in DB → 200 returned immediately
4. Queue: Order job enqueued → background worker processes → Shiprocket + WhatsApp triggered async
5. Duplicate order: Same `razorpay_payment_id` submitted twice → second request rejected by unique constraint
6. WhatsApp: Order status change → Interakt → message delivered to test number
7. Admin role guard: Customer JWT hits `/admin/products` → 403 returned
8. Connection pooling: 100 concurrent requests → all routed through Supavisor port 6543 → no "too many connections" error
9. k6 load test → p99 < 800ms at 10k users
