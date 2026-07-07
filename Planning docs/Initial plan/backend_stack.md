# Backend Stack — Complete Reference

> Supabase Edge Functions + TypeScript backend for Baker Ally (India, 10,000 concurrent users)
> Last updated: July 2026

---

## Table of Contents

1. [Runtime — Deno (via Supabase Edge Functions)](#1-runtime--nodejs-22)
2. [Framework — Hono](#2-framework--hono)
3. [Validation — Zod](#3-validation--zod)
4. [ORM — Drizzle](#4-orm--drizzle)
5. [Auth — Supabase JWT Middleware](#5-auth--supabase-jwt-middleware)
6. [Database — Supabase Postgres](#6-database--supabase-postgres)
7. [File Storage — Supabase Storage](#7-file-storage--supabase-storage)
8. [Payments — Razorpay](#8-payments--razorpay)
9. [Shipping — Shiprocket](#9-shipping--shiprocket)
10. [WhatsApp — Interakt (locked)](#10-whatsapp--interakt)
11. [Push Notifications — Firebase Admin](#11-push-notifications--firebase-admin)
12. [Email — Resend](#12-email--resend)
13. [Background Jobs — Supabase Queues](#13-background-jobs--supabase-queues-pgmq)
14. [Rate Limiting](#14-rate-limiting)
15. [Observability — Sentry](#15-observability--sentry)
16. [Hosting — Supabase Edge Functions](#16-hosting--supabase-edge-functions)
17. [Quick Reference Table](#quick-reference-table)
18. [Dependencies](#dependencies)

---

## 1. Runtime — Deno (via Supabase Edge Functions)

### What it is
The runtime that executes your backend code inside Supabase Edge Functions. Deno is the next-generation JavaScript/TypeScript runtime by the creator of Node.js.

### Why Deno via Supabase Edge Functions
- Full NPM + Node.js built-in API compatibility — all npm packages including Razorpay and firebase-admin work
- TypeScript-native — no separate build step needed
- Globally distributed — functions run close to your users
- Included in Supabase Pro — no separate hosting bill (saves ₹4,200/month vs Railway)
- Auto-scales — no server management

### Why not Railway / standalone Node.js
Railway costs ₹4,200–6,700/month extra. Since Supabase Edge Functions now support npm packages fully, there is no technical reason to pay for a separate server for this app's workload.

---

## 2. Framework — Hono

**Package:** `hono`

### What it is
A lightweight, TypeScript-first HTTP framework. Faster than Express, simpler than NestJS.

### The problem it solves
Express is old — no TypeScript-first design, no built-in validation hooks, slower request handling. Hono gives you a modern API with zero overhead.

### What it does
- Defines API routes (`GET /products`, `POST /orders`)
- Middleware pipeline (auth, logging, error handling)
- Works on Deno, Node.js, Bun, and Cloudflare Workers — portable
- Built-in request/response type safety

### Basic example
```typescript
import { Hono } from 'hono'

const app = new Hono()

app.get('/products', async (c) => {
  const products = await db.select().from(productsTable)
  return c.json(products)
})

app.post('/orders', authMiddleware, async (c) => {
  const body = await c.req.json()
  // create order logic
  return c.json({ orderId: '123' }, 201)
})

export default app
```

### Why Hono over alternatives
| Alternative | Problem |
|---|---|
| Express | Old, no TypeScript-first design, slow |
| Fastify | Good but heavier than Hono |
| NestJS | Massive overhead, overkill for this app |
| Hono | Lightweight, type-safe, modern |

---

## 3. Validation — Zod

**Package:** `zod`

### What it is
A TypeScript-first schema validation library. Validates and types every request body before it touches your database.

### The problem it solves
Without validation, a user can send `{ price: "banana" }` and your code crashes or corrupts the DB. Zod rejects invalid input at the boundary with a clear error message.

### What it does
- Defines schemas for every request body
- Validates types, formats, required fields, min/max values
- Returns typed objects — TypeScript knows the exact shape after validation
- Powers Hono's request validation middleware

### Basic example
```typescript
import { z } from 'zod'

const CreateOrderSchema = z.object({
  items: z.array(z.object({
    variantId: z.string().uuid(),
    quantity: z.number().int().min(1),
  })).min(1),
  addressId: z.string().uuid(),
  discountCode: z.string().optional(),
})

// In route handler
const body = await c.req.json()
const parsed = CreateOrderSchema.safeParse(body)

if (!parsed.success) {
  return c.json({ error: parsed.error.flatten() }, 400)
}

// parsed.data is now fully typed
const { items, addressId } = parsed.data
```

---

## 4. ORM — Drizzle

**Package:** `drizzle-orm`, `drizzle-kit`

### What it is
A TypeScript ORM that writes SQL for you — but keeps you in control. Lightweight alternative to Prisma.

### The problem it solves
Raw SQL strings have no type safety — a typo in a column name only fails at runtime. Drizzle catches errors at compile time.

### What it does
- Defines your database schema in TypeScript
- Generates and runs migrations via `drizzle-kit`
- Type-safe queries — autocomplete on column names
- Direct Postgres connection via `postgres.js`

### Schema definition example
```typescript
import { pgTable, uuid, text, integer, timestamp, boolean } from 'drizzle-orm/pg-core'

export const products = pgTable('products', {
  id: uuid('id').primaryKey().defaultRandom(),
  categoryId: uuid('category_id').notNull(),
  name: text('name').notNull(),
  basePrice: integer('base_price').notNull(), // paise (₹1 = 100 paise)
  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow(),
})
```

### Query example
```typescript
import { eq } from 'drizzle-orm'

// Type-safe — TypeScript knows the shape of result
const product = await db
  .select()
  .from(products)
  .where(eq(products.id, productId))
  .limit(1)
```

### Why Drizzle over alternatives
| Alternative | Problem |
|---|---|
| Prisma | Heavy, slow cold starts, magic client generation |
| TypeORM | Decorator-based, complex, buggy edge cases |
| Raw SQL (pg) | No type safety, manual query strings |
| Drizzle | Lightweight, type-safe, close to SQL |

---

## 5. Auth — Supabase JWT Middleware

**Package:** `@supabase/supabase-js`, `hono/jwt`

### What it is
Middleware that verifies the JWT token sent by Flutter on every protected route.

### How the full auth flow works
```
Flutter app
  → User logs in via Supabase Auth (OTP / Google)
  → Supabase issues a signed JWT with user id + role claim
  → Flutter stores JWT in flutter_secure_storage
  → Dio interceptor attaches: Authorization: Bearer <token>
  → Hono middleware verifies JWT signature on every request
  → Route handler gets user id + role from verified token
```

### Middleware implementation
```typescript
import { createMiddleware } from 'hono/factory'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export const authMiddleware = createMiddleware(async (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')
  if (!token) return c.json({ error: 'Unauthorized' }, 401)

  const { data: { user }, error } = await supabase.auth.getUser(token)
  if (error || !user) return c.json({ error: 'Unauthorized' }, 401)

  c.set('user', user)
  await next()
})

export const adminMiddleware = createMiddleware(async (c, next) => {
  const user = c.get('user')
  if (user?.app_metadata?.role !== 'admin') {
    return c.json({ error: 'Forbidden' }, 403)
  }
  await next()
})
```

### Usage on routes
```typescript
// Public route — no auth
app.get('/products', getProductsHandler)

// Customer must be logged in (Flutter app)
app.get('/orders', authMiddleware, getOrdersHandler)

// Admin only (Next.js web panel — admin JWT required)
app.post('/admin/products', authMiddleware, adminMiddleware, createProductHandler)
```

---

## 6. Database — Supabase Postgres

**Service:** Supabase (Pro plan)

### What it is
A managed PostgreSQL database. Supabase hosts it, handles backups, connection pooling, and provides a dashboard.

### Why Supabase Postgres
- Managed — no server to maintain
- Built-in connection pooler (PgBouncer) — handles 10k concurrent connections
- Automatic daily backups on Pro plan
- Supabase CLI manages schema migrations as versioned SQL files
- Row Level Security (RLS) — database-level access control

### Connection — use Supavisor pooler in Edge Functions, NOT direct connection

Supabase docs confirm: serverless/Edge Functions must use the **transaction-mode pooler on port 6543**. Direct port 5432 is IPv6-only on Free/Pro and each isolate opens its own connection — at real concurrency this exhausts Postgres slots.

```typescript
import postgres from 'npm:postgres'

// Transaction-mode pooler — use in ALL Edge Functions
// Secret name must NOT start with SUPABASE_ (that prefix is reserved by Supabase)
const client = postgres(Deno.env.get('DB_POOL_URL')!, {
  prepare: false,  // transaction mode does not support prepared statements
})

export const db = drizzle(client)
```

Connection strings:
```
DB_POOL_URL   = postgresql://postgres.[ref]:[password]@aws-[region].pooler.supabase.com:6543/postgres
                ↑ use this in Edge Functions (transaction mode, port 6543)

Direct 5432   = use only for migrations via Supabase CLI — never in Edge Functions
```

### Migrations with Supabase CLI
```bash
# Create a new migration
supabase migration new add_products_table

# Apply migrations to production (uses direct 5432 — correct for CLI)
supabase db push

# Pull remote schema changes locally
supabase db pull
```

### Important — store prices in paise (integer), not rupees (float)
```
₹99.50  →  store as  9950  (paise)
₹1,000  →  store as  100000 (paise)
```
Floating point arithmetic on money causes rounding errors. Always integer paise, divide by 100 only for display.

### RLS does NOT protect API routes
The backend uses the `service_role` key which bypasses RLS entirely. Ownership checks must be enforced in code on every route that touches user data:

```typescript
// REQUIRED on every order/address query — RLS will not protect this
const orders = await db
  .select()
  .from(ordersTable)
  .where(eq(ordersTable.userId, jwtUser.id))  // ← must be explicit in code
```

RLS only applies when Flutter uses the `supabase_flutter` SDK directly (e.g. for Auth). It does not run on any Hono Edge Function route.

---

## 7. File Storage — Supabase Storage

**Package:** `@supabase/supabase-js`

### What it is
S3-compatible object storage built into Supabase. Used for product images uploaded by the admin.

### What it stores
- Product images (uploaded via admin web/app)
- Category images
- User avatars

### Upload from backend
```typescript
const { data, error } = await supabase.storage
  .from('product-images')
  .upload(`products/${productId}/${filename}`, fileBuffer, {
    contentType: 'image/webp',
    upsert: true,
  })

// Get public URL
const { data: { publicUrl } } = supabase.storage
  .from('product-images')
  .getPublicUrl(`products/${productId}/${filename}`)

// Store publicUrl in products table
```

---

## 8. Payments — Razorpay

**Package:** `razorpay` (official Node SDK) — see Plan.md for full gateway comparison (Cashfree, PhonePe, Stripe)

### What it is
India's leading payment gateway. Handles UPI, cards, netbanking, and wallets. Recommended default — best SDK quality and documentation. Cashfree is a direct swap if card fees need optimising (same integration pattern).

### How the payment flow works
```
Flutter
  → User taps "Pay"
  → Flutter calls backend: POST /cart/checkout
      Backend creates Razorpay order → returns { orderId, amount, key }
  → Flutter opens Razorpay SDK with those values
  → User pays (UPI / card / netbanking)
  → Razorpay returns { razorpay_payment_id, razorpay_order_id, razorpay_signature }
  → Flutter sends these to backend: POST /orders
      Backend verifies signature (HMAC-SHA256)
      If valid → creates order in DB → triggers Shiprocket + WhatsApp
```

### Backend — create Razorpay order
```typescript
import Razorpay from 'razorpay'

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID!,
  key_secret: process.env.RAZORPAY_KEY_SECRET!,
})

// Step 1: Create order (called before Flutter opens payment sheet)
const order = await razorpay.orders.create({
  amount: totalInPaise,      // e.g. 50000 = ₹500
  currency: 'INR',
  receipt: `receipt_${orderId}`,
})

return c.json({
  razorpayOrderId: order.id,
  amount: order.amount,
  currency: order.currency,
  keyId: process.env.RAZORPAY_KEY_ID,  // public key only
})
```

### Backend — verify payment signature
```typescript
import crypto from 'crypto'

const verifyPayment = (
  razorpayOrderId: string,
  razorpayPaymentId: string,
  razorpaySignature: string
): boolean => {
  const body = razorpayOrderId + '|' + razorpayPaymentId
  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET!)
    .update(body)
    .digest('hex')
  return expectedSignature === razorpaySignature
}
```

### Critical security rule
`RAZORPAY_KEY_SECRET` lives only in Supabase Edge Function secrets. It is never sent to Flutter. Flutter only receives the public `key_id`.

### Order creation — async queue pattern (do NOT call Shiprocket/WhatsApp inline)

Calling Shiprocket + Interakt + FCM synchronously inside `POST /orders` means a slow external API hangs the customer's checkout. Instead, write to DB + enqueue a job + return 200 immediately:

```typescript
app.post('/orders', authMiddleware, async (c) => {
  const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = await c.req.json()

  // 1. Verify payment signature
  const valid = verifyPayment(razorpayOrderId, razorpayPaymentId, razorpaySignature)
  if (!valid) return c.json({ error: 'Invalid payment' }, 400)

  // 2. Create order in DB (unique constraint on razorpay_payment_id prevents duplicates)
  const order = await db.insert(ordersTable).values({ ...orderData }).returning()

  // 3. Enqueue job — Shiprocket + WhatsApp + FCM handled async by background worker
  await supabase.schema('pgmq_public').rpc('send', {
    queue_name: 'order_events',
    message: { orderId: order.id, type: 'created' },
  })

  // 4. Return immediately — customer is not blocked
  return c.json({ orderId: order.id }, 201)
})
```

Background worker (scheduled Edge Function via Supabase Cron) drains the queue:

```typescript
// Runs every 30 seconds via Supabase Cron
const { data: messages } = await supabase
  .schema('pgmq_public')
  .rpc('pop', { queue_name: 'order_events' })

for (const msg of messages) {
  await createShiprocketShipment(msg.message.orderId)
  await sendWhatsAppUpdate(msg.message.orderId, 'confirmed')
  await sendPushNotification(msg.message.orderId)
  // archive message on success
}
```

### Webhook (refunds, disputes) — with idempotency check

Razorpay retries webhooks on failure. Always check `webhook_events` before processing:

```typescript
app.post('/webhooks/razorpay', async (c) => {
  const signature = c.req.header('x-razorpay-signature')
  const body = await c.req.text()

  const expected = crypto
    .createHmac('sha256', Deno.env.get('RAZORPAY_WEBHOOK_SECRET')!)
    .update(body)
    .digest('hex')

  if (expected !== signature) return c.json({ error: 'Invalid' }, 400)

  const event = JSON.parse(body)
  const eventId = event.payload.payment.entity.id

  // Idempotency — ignore already-processed events
  const existing = await db.select().from(webhookEventsTable)
    .where(and(eq(webhookEventsTable.source, 'razorpay'), eq(webhookEventsTable.eventId, eventId)))
  if (existing.length > 0) return c.json({ ok: true })  // already handled

  await db.insert(webhookEventsTable).values({ source: 'razorpay', eventId })

  if (event.event === 'payment.failed') {
    await markOrderFailed(event.payload.payment.entity.notes.orderId)
  }
  return c.json({ ok: true })
})
```

---

## 9. Shipping — Shiprocket

**Package:** `axios` (no official Node SDK — raw HTTP calls)

### What it is
India's largest shipping aggregator. Single API covers BlueDart, Delhivery, Ecom Express, and 25+ carriers.

### How the shipping flow works
```
Order confirmed (payment verified)
  → Backend calls Shiprocket: create shipment
  → Shiprocket assigns carrier + AWB (tracking number)
  → Backend stores AWB in shipments table
  → Shiprocket webhook fires on status changes
      → Backend updates order status
      → Backend sends WhatsApp update to customer
```

### Create shipment
```typescript
const shiprocketToken = await getShiprocketToken()

const shipment = await axios.post(
  'https://apiv2.shiprocket.in/v1/external/orders/create/adhoc',
  {
    order_id: order.id,
    order_date: new Date().toISOString(),
    pickup_location: 'Primary',
    billing_customer_name: customer.name,
    billing_address: address.line1,
    billing_city: address.city,
    billing_state: address.state,
    billing_pincode: address.pincode,
    billing_country: 'India',
    billing_phone: customer.phone,
    order_items: items.map(item => ({
      name: item.productName,
      sku: item.variantId,
      units: item.quantity,
      selling_price: item.unitPrice / 100,  // Shiprocket wants rupees
    })),
    payment_method: 'Prepaid',
    sub_total: order.total / 100,
    length: 10, width: 10, height: 10, weight: 0.5,
  },
  { headers: { Authorization: `Bearer ${shiprocketToken}` } }
)

await db.update(shipmentsTable)
  .set({ shiprocketOrderId: shipment.data.order_id, status: 'created' })
  .where(eq(shipmentsTable.orderId, order.id))
```

### Webhook (status updates)
```typescript
app.post('/webhooks/shiprocket', async (c) => {
  const event = await c.req.json()
  const { awb, current_status, order_id } = event

  await db.update(shipmentsTable)
    .set({ status: current_status })
    .where(eq(shipmentsTable.shiprocketOrderId, order_id))

  // Trigger WhatsApp notification
  await sendWhatsAppUpdate(order_id, current_status)
  return c.json({ ok: true })
})
```

---

## 10. WhatsApp — Interakt

**Service:** Interakt (interakt.co) — WhatsApp Business API provider — **locked choice, WATI ruled out**

### What it is
A WhatsApp Business API platform. Lets your backend send template messages to customers programmatically.

### What it sends
| Trigger | Message |
|---|---|
| Order confirmed | "Your Baker Ally order #123 is confirmed! Total: ₹500" |
| Shipped | "Your order is on the way! Track: [AWB link]" |
| Out for delivery | "Your order will be delivered today" |
| Delivered | "Order delivered! Rate your experience" |

### Setup requirement
WhatsApp Business API requires pre-approved message templates. Submit templates to Interakt → they get approved by Meta (1-2 days).

### Send a WhatsApp message
```typescript
const sendWhatsAppUpdate = async (
  phone: string,
  templateName: string,
  variables: string[]
) => {
  await axios.post(
    'https://api.interakt.ai/v1/public/message/',
    {
      countryCode: '+91',
      phoneNumber: phone,
      callbackData: 'order_update',
      type: 'Template',
      template: {
        name: templateName,
        languageCode: 'en',
        bodyValues: variables,
      },
    },
    {
      headers: {
        Authorization: `Basic ${process.env.INTERAKT_API_KEY}`,
        'Content-Type': 'application/json',
      },
    }
  )
}

// Usage
await sendWhatsAppUpdate(customer.phone, 'order_confirmed', [
  customer.name,
  order.id,
  `₹${order.total / 100}`,
])
```

---

## 11. Push Notifications — Firebase Admin

**Package:** `firebase-admin`

### What it is
The server-side Firebase SDK. Lets your backend send push notifications directly to a specific Flutter app user.

### How it works with Flutter
```
Flutter app registers with FCM on first launch
  → Gets a device token
  → Flutter sends token to backend: POST /users/fcm-token
  → Backend stores token in users table

When order status changes:
  → Backend looks up user's FCM token
  → Backend calls firebase-admin to send push
  → Flutter receives it via firebase_messaging
```

### Send a push notification
```typescript
import admin from 'firebase-admin'

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  }),
})

const sendPush = async (fcmToken: string, title: string, body: string, data?: Record<string, string>) => {
  await admin.messaging().send({
    token: fcmToken,
    notification: { title, body },
    data,
    apns: { payload: { aps: { sound: 'default' } } },
    android: { notification: { sound: 'default' } },
  })
}

// Usage
await sendPush(
  user.fcmToken,
  'Order Shipped!',
  'Your Baker Ally order is on the way',
  { route: '/orders/123', orderId: '123' }
)
```

---

## 12. Email — Resend (via Supabase SMTP, no custom code)

**Service:** Resend free tier — configured as Supabase Auth's SMTP provider

### What it is
Resend is plugged into Supabase Auth as the outbound email provider. No custom email code is written — Supabase Auth handles all email sending automatically.

### Why no custom email code is needed
All transactional order updates (confirmed, shipped, delivered) are already covered by WhatsApp (Interakt) and push notifications (FCM). Email is only needed for auth flows, which Supabase Auth handles natively.

### What Supabase Auth sends via Resend
| Email | Trigger |
|---|---|
| OTP / magic link | User logs in with email |
| Password reset | User requests reset |
| Email verification | New signup |

### Setup — one-time in Supabase dashboard
```
Supabase Dashboard → Project Settings → Auth → SMTP Settings
  Host:     smtp.resend.com
  Port:     465
  Username: resend
  Password: your-resend-api-key
  Sender:   Baker Ally <auth@bakerally.in>
```

That's it. No code to write.

### Volume
~2,000–2,500 emails/month (OTPs + resets). Resend free tier covers 3,000/month — never needs upgrading.

**Monthly cost: ₹0 (free tier, never exceeded)**

---

## 13. Background Jobs — Supabase Queues (pgmq)

**Service:** Supabase Queues — included in Supabase Pro, built on pgmq extension

### What it is
A Postgres-native durable message queue. Messages persist in the database — if a worker crashes, messages are not lost. Guaranteed exactly-once delivery within a configurable visibility window.

### Setup
Enable via Supabase Dashboard → Integrations → Queues → Enable pgmq, then create the queue:

```sql
-- Run once in Supabase SQL editor after enabling pgmq
SELECT pgmq.create('order_events');
```

### Why queues for Baker Ally
`POST /orders` must return fast (customer is waiting). Shiprocket, Interakt, and FCM are called async by a background worker — if any of them fails, the customer's order is already confirmed and the job retries from the queue.

### Enqueue (from order handler)
```typescript
await supabase.schema('pgmq_public').rpc('send', {
  queue_name: 'order_events',
  message: { orderId: '...', type: 'created' },
})
```

### Drain (background worker Edge Function)
```typescript
// Triggered by Supabase Cron every 30 seconds
const { data } = await supabase
  .schema('pgmq_public')
  .rpc('pop', { queue_name: 'order_events' })

for (const msg of data ?? []) {
  await processOrderEvent(msg.message)
}
```

---

## 14. Rate Limiting

**Package:** `hono/middleware` + Upstash Redis (free tier)

### What needs rate limiting
| Route | Risk without limiting |
|---|---|
| `POST /auth/verify` | OTP spam / credential stuffing |
| `GET /products` | Scraping |
| `POST /cart/checkout` | Checkout flooding |
| `POST /webhooks/*` | Must be IP-allowlisted to Razorpay/Shiprocket IPs only |

### Implementation with Hono + Upstash
```typescript
import { Ratelimit } from 'npm:@upstash/ratelimit'
import { Redis } from 'npm:@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(20, '1m'),  // 20 requests per minute per IP
})

export const rateLimitMiddleware = createMiddleware(async (c, next) => {
  const ip = c.req.header('x-forwarded-for') ?? 'anonymous'
  const { success } = await ratelimit.limit(ip)
  if (!success) return c.json({ error: 'Too many requests' }, 429)
  await next()
})

// Apply to sensitive routes only
app.post('/cart/checkout', rateLimitMiddleware, authMiddleware, checkoutHandler)
```

Upstash Redis free tier: 10,000 requests/day — sufficient for rate limiting metadata.

---

## 15. Observability — Sentry

**Package:** `npm:@sentry/deno`

### What it is
Error tracking and performance monitoring for Edge Functions. Essential for a payments app — you need to know immediately when a payment flow throws an error.

### What to capture
- Unhandled exceptions in all Edge Functions
- Payment verification failures
- Shiprocket / Interakt API errors
- Slow transactions (p95 > 1s)

### Setup in Edge Function
```typescript
import * as Sentry from 'npm:@sentry/deno'

Sentry.init({
  dsn: Deno.env.get('SENTRY_DSN'),
  tracesSampleRate: 0.2,  // 20% of requests traced
})

// Wrap handler
app.onError((err, c) => {
  Sentry.captureException(err)
  return c.json({ error: 'Internal server error' }, 500)
})
```

**Monthly cost: Free tier (5,000 errors/month) — sufficient for Baker Ally**

---

## 16. Hosting — Supabase Edge Functions

**Service:** Supabase (included in Pro plan — no extra cost)

### What it is
Serverless functions that run inside Supabase's infrastructure, globally distributed, with full npm and Node.js API compatibility.

### What Supabase Edge Functions handles
- Deploy functions via Supabase CLI — no separate hosting account needed
- Environment secrets vault (same dashboard as your DB)
- Auto-scaling globally — no server management
- Runs close to users — low latency
- Included in Supabase Pro — saves ₹4,200/month vs Railway

### Environment secrets to set in Supabase dashboard
```
DB_POOL_URL=               ← Supavisor pooler URL (port 6543) — NOT the direct 5432 URL
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
RAZORPAY_WEBHOOK_SECRET=
SHIPROCKET_EMAIL=
SHIPROCKET_PASSWORD=
INTERAKT_API_KEY=
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
SENTRY_DSN=
```
Note: `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are automatically available inside Edge Functions — no need to set them manually. Secret names must NOT start with `SUPABASE_` (that prefix is reserved).

### Deployment
```bash
# Deploy a single function
supabase functions deploy orders

# Deploy all functions
supabase functions deploy

# Set a secret
supabase secrets set RAZORPAY_KEY_SECRET=your_secret_here
```

### Edge Function limits (from Supabase docs)
| Limit | Value |
|---|---|
| Wall-clock time (paid) | 400s |
| CPU time | 2s (async I/O does NOT count) |
| Memory | 256MB |
| Request idle timeout | 150s |

### Cold starts
Edge Functions have a ~300–500ms cold start after idle. p99 target is set at **< 800ms** to account for this. Keep high-traffic routes (`/products`, `/webhooks/*`) warm via Supabase Cron scheduled pings every 5 minutes.

---

## Quick Reference Table

| Library/Service | Package/Tool | One job |
|---|---|---|
| Hono | `hono` | HTTP framework — defines API routes |
| Zod | `zod` | Validates every request body |
| Drizzle | `drizzle-orm` | Type-safe queries against Supabase Postgres |
| Supabase Auth | `@supabase/supabase-js` | Verifies JWTs from Flutter |
| Supabase Storage | `@supabase/supabase-js` | Stores product images |
| Razorpay | `razorpay` | Accepts payments (UPI, cards, netbanking) |
| Shiprocket | `axios` | Creates shipments, tracks delivery |
| Interakt | `axios` | Sends WhatsApp order updates |
| Firebase Admin | `firebase-admin` | Sends push notifications to Flutter |
| Resend | Supabase SMTP config | Sends auth emails (OTP, reset) via Supabase — no custom code |
| Supabase Queues (pgmq) | Supabase Dashboard | Async background jobs — order processing queue |
| Upstash Redis | `@upstash/ratelimit` | Rate limiting on public + auth routes |
| Sentry | `@sentry/deno` | Error tracking + performance monitoring |
| Supabase Edge Functions | (hosting) | Runs and scales the backend — included in Supabase Pro |

---

## package.json Dependencies

Supabase Edge Functions use Deno — dependencies are imported via npm specifiers, not a package.json.

```typescript
// Import npm packages inside your Edge Function
import { Hono } from 'npm:hono@^4.6.0'
import { z } from 'npm:zod@^3.23.0'
import { drizzle } from 'npm:drizzle-orm@^0.36.0/postgres-js'
import postgres from 'npm:postgres@^3.4.0'
import Razorpay from 'npm:razorpay@^2.9.0'
import admin from 'npm:firebase-admin@^12.7.0'
import { Resend } from 'npm:resend@^4.0.0'
import axios from 'npm:axios@^1.7.0'
```

For local development, use `supabase functions serve` which runs functions locally via Deno.

---

*This document covers the backend stack only. For Flutter frontend stack see [flutter_library_stack.md](flutter_library_stack.md).*
