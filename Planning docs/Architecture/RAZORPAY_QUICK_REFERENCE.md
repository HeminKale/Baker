# Razorpay Quick Reference — Single Page

---

## The Two Steps

```
STEP 1: Create Order          STEP 2: Confirm Order
───────────────────          ──────────────────

POST /v1/cart/checkout       POST /v1/orders/:id/confirm
      ↓                            ↓
• Validate cart              • Verify signature
• Check stock (live)         • Atomic transaction:
• Recompute prices             - Decrement stock_qty
• Create Razorpay order      - Mark order confirmed
  (external API call)        - Clear cart
• Return { keyId,            - Enqueue shipment job
           orderId,          • Return 201
           amount }
      ↓                            ↓
Razorpay SDK opens           Order confirmed
(user sees payment form)      Payment captured
      ↓
User pays (UPI/Card/NetBanking)
      ↓
Returns {paymentId, signature}
      ↓
      Flutter calls confirm with these
```

---

## Security Boundaries

```
PUBLIC (Sent to Flutter):
  ├─ razorpay_key_id       (e.g., "rzp_test_...")
  ├─ razorpay_order_id     (from Step 1)
  └─ amount                 (in paise)

SECRET (Backend only, Supabase secrets):
  ├─ razorpay_key_secret   (NEVER to Flutter)
  ├─ razorpay_webhook_secret
  └─ Uses: HMAC verification only

THE GUARD:
  Backend verifies: SHA256(secret, orderId|paymentId) === signature
  → If true: we trust the payment
  → If false: reject, return 400
```

---

## Idempotency & Safety

| Scenario | Protection |
|---|---|
| **Retry confirm with same payment_id** | `razorpay_payment_id UNIQUE` + `status='pending'` guard → idempotent return |
| **Concurrent last-unit checkouts** | `UPDATE ... WHERE stock_qty >= qty` → only one succeeds, other gets 409 |
| **Webhook retry (payment.failed)** | `webhook_events(source, event_id) UNIQUE` → processed exactly once |
| **Out of stock at confirm time** | Atomic transaction rolls back stock decrement, order stays pending |

---

## Database Guarantees

```
orders table:
  ├─ razorpay_payment_id UNIQUE
  │  └─ Prevents duplicate payment processing
  ├─ status CHECK ('pending' | 'confirmed' | ...)
  │  └─ Ensures atomic status transition
  └─ user_id (ownership)
     └─ Prevents cross-user access

product_variants table:
  └─ stock_qty INTEGER
     └─ Conditional decrement: WHERE stock_qty >= qty
        Prevents oversell even under concurrency

webhook_events table:
  └─ UNIQUE(source, event_id)
     └─ Dedup Razorpay retries
```

---

## Environment Secrets (Supabase Dashboard)

```
3 Razorpay secrets:

1. RAZORPAY_KEY_ID
   From: Razorpay Dashboard → Settings → API Keys
   Value: rzp_test_... (public, safe)
   Used: Returned to Flutter in Step 1

2. RAZORPAY_KEY_SECRET
   From: Razorpay Dashboard → Settings → API Keys (shown once)
   Value: (private, save securely)
   Used: HMAC verification in Step 2

3. RAZORPAY_WEBHOOK_SECRET
   From: You generate any strong random string
   Value: Match in Razorpay webhook config
   Used: Webhook signature verification
```

Set via:
```bash
supabase secrets set RAZORPAY_KEY_ID=rzp_test_...
supabase secrets set RAZORPAY_KEY_SECRET=...
supabase secrets set RAZORPAY_WEBHOOK_SECRET=your_secret
```

---

## How It Integrates With Shiprocket/Porter

```
POST /orders/:id/confirm (Razorpay + Stock)
  │
  └─→ Atomic transaction completes
      └─→ Order marked 'confirmed'
          └─→ Payment captured (Razorpay handles this)
              └─→ Enqueue pgmq job: 'order_events'
                  └─→ Background worker (separate Edge Function)
                      │
                      ├─ If using Shiprocket:
                      │   POST https://apiv2.shiprocket.in/...
                      │   (create shipment)
                      │
                      ├─ If using Porter (Phase 4):
                      │   POST https://api.porter.in/...
                      │   (create shipment)
                      │
                      └─ Send in-app + FCM notifications
                         (notifications table + Firebase Admin)

KEY: Razorpay decision is made in Step 1 + Step 2 (payment layer).
     Shipping provider choice is made in the background job (fulfillment layer).
     They are DECOUPLED.
```

---

## Test Mode (Now)

| Component | Test Value |
|---|---|
| **Key ID** | `rzp_test_1a2b3c4d5e6f7g8h` (example) |
| **Test Card** | `4111 1111 1111 1111` (any future expiry) |
| **Test UPI** | `success@razorpay` |
| **Test Netbanking** | Any bank code from Razorpay docs |
| **Webhook Secret** | User-generated, same in Razorpay config |

**No real money moves. Orders confirm but are obviously not fulfilled yet (M3 lacks Shiprocket integration).**

---

## Live Mode (Phase 7)

1. Get live API keys from Razorpay Dashboard
2. Swap secrets in Supabase:
   ```bash
   supabase secrets set RAZORPAY_KEY_ID=rzp_live_...
   supabase secrets set RAZORPAY_KEY_SECRET=live_secret_...
   ```
3. **Code changes: ZERO** — verify/confirm logic is identical
4. Real payments now processed, real Shiprocket shipments created

---

## Cost (India, Phase 1 baseline)

| Service | Monthly | Note |
|---|---|---|
| Razorpay | ~₹1,000–2,000 | 1.8% UPI, 2% cards, ₹0 netbanking |
| Shiprocket | ₹2,000–5,000 | Weight-based, per shipment |
| **Total payment layer** | **~₹1,000–2,000** | Razorpay only |

---

## One-Pager: What Each File Does

| File | Purpose |
|---|---|
| `lib/razorpay.ts` | HMAC verify, lazy Razorpay client, webhook verify |
| `routes/checkout.ts` | Step 1 + Step 2 handlers, stock decrement, idempotency guards |
| `routes/webhooks.ts` | Razorpay webhook dedup + payment.failed handling |
| `data/checkout_repository.dart` | Flutter ↔ backend API bridge |
| `presentation/screens/checkout_screen.dart` | Opens Razorpay SDK, handles payment result |
| `presentation/providers/checkout_providers.dart` | Bill math, address/payment state |

---

## Key Insight: Why This Design

**Two-step payment (create → confirm) is NOT specific to Razorpay.** It's a general safety pattern:

- **Step 1 (Create Order):** Everything server-side before exposing payment UI to user
  - Prices recomputed → detect last-minute changes
  - Stock rechecked → prevent oversell
  - Order row created with `status='pending'` → audit trail
  
- **Step 2 (Confirm Order):** Atomic transaction after payment succeeds
  - Signature verified → we trust Razorpay
  - Stock decremented → only if signature valid
  - Cart cleared → idempotent, no double orders

This pattern would be **identical** if we swapped Razorpay for Cashfree, PhonePe, or even Stripe. Only the HMAC verification differs.

---

## Questions for the Business

These decisions are **pending** (for Milestone 4 planning):

1. **Free-shipping threshold?** E.g., free delivery on orders > ₹1000?
2. **Weight-based pricing?** E.g., ₹49 up to 1kg, ₹80 for 1–2kg?
3. **Porter for metro same-day?** E.g., Shiprocket regular, Porter for expedited?
4. **Shipping cost visibility in checkout?** E.g., show live Shiprocket rates in Step 1 before payment?

Currently: **Flat ₹49 hardcoded** (placeholder). This must be decided before Phase 4.
