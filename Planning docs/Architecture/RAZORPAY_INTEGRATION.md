# Razorpay Integration Architecture

**Document scope:** How Razorpay is integrated into Baker Ally (Milestone 3), how it's documented in the architecture, and how it will scale with Shiprocket/Porter integration (Milestone 4+).

---

## 1. Documented Architecture (from backend_stack.md §8)

The backend_stack.md contains the complete spec. Here's the key pattern:

### Payment Flow (Two-Step)

```
Flutter App
  ↓
User taps "Proceed" on checkout screen
  ↓
Flutter calls: POST /v1/cart/checkout
  ├─ Backend validates prices + stock (server is source of truth)
  ├─ Backend creates Razorpay order: razorpay.orders.create({ amount, currency: INR, receipt })
  ├─ Returns: { razorpayOrderId, amount, keyId }
  ↓
Flutter opens Razorpay SDK with those values
  ├─ User pays (UPI / card / netbanking)
  ├─ Razorpay returns: { razorpay_payment_id, razorpay_order_id, razorpay_signature }
  ↓
Flutter calls: POST /v1/orders/:orderId/confirm
  ├─ Backend verifies HMAC-SHA256 signature (this is the security boundary)
  ├─ If valid: atomic transaction (stock decrement + order confirm)
  ├─ Enqueues job to pgmq queue: order_events → Shiprocket/in-app/FCM
  ├─ Returns: 201 { orderId, status: 'confirmed' }
  ↓
Order confirmed, cart cleared, redirect to confirmation screen
```

---

## 2. Security Model

### Client-Side (Flutter)
- Flutter receives: `razorpayOrderId`, `amount`, `keyId` (public key only)
- Flutter opens Razorpay sheet (Razorpay's official UI, not ours)
- User pays via Razorpay's secure payment form
- Razorpay returns: `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature`

### Server-Side (Backend)
- **NEVER expose the secret key to Flutter**
- Backend only verifies: `HMAC-SHA256(SECRET_KEY, orderId|paymentId) === signature`
- This proves Razorpay signed the result; we trust it
- `razorpay_payment_id UNIQUE` constraint prevents double-decrement on retry

### The Critical Security Rule
```
┌──────────────────────────────────────────────────────────┐
│ RAZORPAY_KEY_SECRET lives ONLY in Supabase Edge Function │
│ secrets. It is NEVER sent to Flutter, NEVER in .env file,│
│ NEVER logged anywhere.                                   │
└──────────────────────────────────────────────────────────┘
```

---

## 3. How We Implemented It in Milestone 3

### Backend Code Structure

**File: `baker_ally_backend/lib/razorpay.ts`**
```typescript
// Lazy client — only instantiated if someone tries to create an order
let client: Razorpay | null = null

export function razorpayKeyId(): string {
  return Deno.env.get("RAZORPAY_KEY_ID") ?? ""  // public key, safe to return
}

function getClient(): Razorpay {
  if (!client) {
    const keyId = Deno.env.get("RAZORPAY_KEY_ID")
    const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET")
    if (!keyId || !keySecret) throw new Error("Razorpay secrets not set")
    client = new Razorpay({ key_id: keyId, key_secret: keySecret })
  }
  return client
}

// HMAC-SHA256 verification with timing-safe compare
export function verifyPaymentSignature(
  razorpayOrderId: string,
  razorpayPaymentId: string,
  razorpaySignature: string
): boolean {
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET")
  if (!keySecret) return false
  
  const expected = createHmac("sha256", keySecret)
    .update(`${razorpayOrderId}|${razorpayPaymentId}`)
    .digest("hex")
  
  return timingSafeEqual(Buffer.from(expected), Buffer.from(razorpaySignature))
}

// Webhook verification — same pattern, different body
export function verifyWebhookSignature(rawBody: string, signature: string): boolean {
  const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET")
  if (!webhookSecret) return false
  
  const expected = createHmac("sha256", webhookSecret)
    .update(rawBody)  // MUST be raw body, not re-serialized JSON
    .digest("hex")
  
  return timingSafeEqual(...)
}
```

**File: `baker_ally_backend/routes/checkout.ts`**

Step 1 — Create order:
```typescript
POST /v1/cart/checkout { addressId, discountCode?, expectedTotal }

  1. Validate: cart not empty, address belongs to user
  2. Load cart items with LIVE prices (never stale)
  3. Stock check: if any item has quantity > current stock_qty → 409 OUT_OF_STOCK
  4. Re-validate discount server-side (never trust client math)
  5. Recompute: subtotal - discountValue + shippingCost = total
  6. If total !== expectedTotal → 409 PRICE_CHANGED (return corrected breakdown)
  7. DB transaction:
       - INSERT orders (status='pending', razorpay_order_id=null)
       - INSERT order_items (snapshot of product_name/variant_name/unit_price)
  8. Outside transaction:
       - razorpayOrder = createRazorpayOrder({ amount: total, receipt: `receipt_${orderId}` })
       - UPDATE orders SET razorpay_order_id = razorpayOrder.id
  9. Return: { orderId, razorpayOrderId, amount: total, keyId }
```

Step 2 — Confirm order:
```typescript
POST /v1/orders/:id/confirm { razorpayPaymentId, razorpaySignature }

  1. Load order by id + user_id (ownership check)
  2. If already confirmed with same payment_id → return 200 idempotently
  3. If not pending → return 409 ORDER_NOT_PENDING
  4. Verify signature: verifyPaymentSignature(order.razorpayOrderId, razorpayPaymentId, razorpaySignature)
     → if false: return 400 INVALID_PAYMENT
  5. DB transaction (ATOMIC — this is the critical section):
       For each order_item:
         - UPDATE product_variants SET stock_qty = stock_qty - quantity
           WHERE id = variant_id AND stock_qty >= quantity
           RETURNING id
         - If zero rows → throw OUT_OF_STOCK → rollback entire transaction
       
       UPDATE orders SET status='confirmed', razorpay_payment_id=..., updated_at=now()
       WHERE id = :id AND status = 'pending'
       If zero rows → throw ALREADY_CONFIRMED → catch and return 200 (idempotent)
       
       INCREMENT discounts.uses_count (if discount was applied)
       
       CLEAR cart_items for this user
  
  6. If transaction throws OUT_OF_STOCK → return 409 (order stays pending, no stock lost)
  7. If transaction throws ALREADY_CONFIRMED → return 200 (race lost, but idempotent)
  8. On success:
       - Enqueue job: pgmq.send('order_events', { orderId, type: 'created' })
       - Return 201 { orderId, status: 'confirmed' }
```

**File: `baker_ally_backend/routes/webhooks.ts`**

Razorpay can retry webhooks. Dedup via `webhook_events(source, event_id)` UNIQUE:
```typescript
POST /v1/webhooks/razorpay

  1. Verify: x-razorpay-signature against HMAC(RAZORPAY_WEBHOOK_SECRET, rawBody)
  2. If invalid → return 400
  3. Parse body as event JSON
  4. Extract event_id (Razorpay's idempotency key)
  5. INSERT webhook_events (source='razorpay', event_id) ON CONFLICT DO NOTHING
     → If already exists: return 200 early (idempotent)
  6. If event.event === 'payment.failed':
       - Mark the pending order 'cancelled' (refund handled by Razorpay)
  7. Return 200 { ok: true }
```

### Flutter Code Structure

**File: `baker_ally_flutter/lib/features/checkout/data/checkout_repository.dart`**

Holds the Razorpay client interaction:
```dart
class CheckoutSession {
  final String orderId;
  final String razorpayOrderId;
  final int amount;    // paise
  final String keyId;  // public key
}

Future<CheckoutSession> createCheckout({
  required String addressId,
  String? discountCode,
  required int expectedTotal,
}) async {
  final response = await _dio.post(
    '/v1/cart/checkout',
    data: {
      'addressId': addressId,
      if (discountCode != null) 'discountCode': discountCode,
      'expectedTotal': expectedTotal,
    },
  );
  // Parse and return CheckoutSession
}

Future<void> confirmOrder({
  required String orderId,
  required String razorpayPaymentId,
  required String razorpaySignature,
}) async {
  await _dio.post(
    '/v1/orders/$orderId/confirm',
    data: {
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    },
  );
}
```

**File: `baker_ally_flutter/lib/features/checkout/presentation/screens/checkout_screen.dart`**

Opens Razorpay and handles the callback:
```dart
// Inside CheckoutScreen state
late final Razorpay _razorpay;

@override
void initState() {
  super.initState();
  _razorpay = Razorpay();
  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
}

Future<void> _placeOrder() async {
  // 1. Gate: is logged in?
  if (!ref.read(authProvider).isLoggedIn) {
    showLoginRequiredSheet(context);
    return;
  }
  
  // 2. Gate: has address?
  final address = ref.read(selectedAddressProvider);
  if (address == null) {
    AddressSelectorSheet.show(context);
    return;
  }
  
  // 3. Get the bill
  final bill = ref.read(billSummaryProvider);
  
  // 4. Call backend to create order
  final session = await checkoutRepository.createCheckout(
    addressId: address.id,
    discountCode: appliedDiscount?.code,
    expectedTotal: bill.total,
  );
  
  // 5. Open Razorpay SDK with the session data
  _razorpay.open({
    'key': session.keyId,          // public key from backend
    'order_id': session.razorpayOrderId,
    'amount': session.amount,      // paise
    'currency': 'INR',
  });
}

void _onPaymentSuccess(PaymentSuccessResponse response) {
  // 6. User paid — now confirm on backend
  await checkoutRepository.confirmOrder(
    orderId: _pendingOrderId,
    razorpayPaymentId: response.paymentId!,
    razorpaySignature: response.signature!,
  );
  
  // 7. Clear cart and navigate to confirmation
  await ref.read(cartProvider.notifier).clearAfterOrder();
  context.go('/checkout/confirmation', extra: { 'orderId': ... });
}

void _onPaymentError(PaymentFailureResponse response) {
  // Order stays pending (recoverable)
  showSnackBar('Payment failed. Try again or contact support.');
}
```

---

## 4. Idempotency & Safety Properties

### Double-Confirm Prevention
```
Scenario: Network glitch — Flutter confirms, Razorpay response lost,
          Flutter retries confirm with same payment_id

Backend response:
  1. Load order by id + user_id
  2. If status='confirmed' AND razorpay_payment_id = incoming_id
     → return 200 immediately (idempotent early return)
  3. In the UPDATE WHERE status='pending', zero rows affected
     → throw ALREADY_CONFIRMED in the catch block
     → return 200 idempotent response

Result: Stock decremented only once, payment captured only once.
```

### Concurrent Last-Unit Checkouts
```
Scenario: Product has 1 unit in stock. Two users buy simultaneously.

User A confirms first:
  UPDATE product_variants SET stock_qty = 0
  WHERE id = variant_id AND stock_qty >= 1
  → 1 row updated ✓

User B confirms (race):
  UPDATE product_variants SET stock_qty = -1
  WHERE id = variant_id AND stock_qty >= 1
  → 0 rows updated
  → throw OUT_OF_STOCK → rollback
  → Order stays pending

Result: User B's payment is authorized but order is not confirmed.
        User B can retry on another product or contact support for refund.
```

### Webhook Dedup
```
Razorpay sends payment.failed webhook.

Try 1:
  INSERT webhook_events (source='razorpay', event_id='...')
  → succeeds
  → Mark order cancelled
  → Return 200

Try 2 (Razorpay retry):
  INSERT webhook_events (source='razorpay', event_id='...')
  → UNIQUE constraint violation
  → ON CONFLICT DO NOTHING
  → Return 200 early
  → Order not marked cancelled again

Result: Webhook processed exactly once.
```

---

## 5. Test Mode vs. Live Mode

### Milestone 3 (Now)
- **Test API Keys**: `RAZORPAY_KEY_ID=rzp_test_...`, `RAZORPAY_KEY_SECRET=...`
- **Test Webhook Secret**: User-generated random string
- **Test Payment Methods**:
  - Card: `4111 1111 1111 1111` (any future expiry)
  - UPI: `success@razorpay`
- **No real money moves**. Orders are confirmed but obviously not fulfilled (no Shiprocket/fulfillment in M3 yet).

### Live Mode (Phase 7 — after all other features deployed)
- Swap to live API keys in Supabase secrets
- No code changes needed — same verify/confirm logic
- Real payments processed, real Shiprocket shipments created

---

## 6. How Porter Integrates (Milestone 4+)

The plan references **two open decisions** about shipping:

### Decision A: Free-Shipping Threshold vs. Weight-Based vs. Porter

**Current state (Milestone 3):**
- Flat ₹49 shipping hardcoded in two places:
  - Backend: `FLAT_SHIPPING_PAISE = 4900` in `routes/checkout.ts`
  - Flutter: `kFlatShippingPaise = 4900` in `checkout_providers.dart`
- If they disagree → checkout returns `PRICE_CHANGED` (mismatch detected, checkout fails)

**When Porter integration happens (Milestone 4+):**

**Option 1: Integrate Shiprocket + Porter as a fallback**
```
Existing: Shiprocket covers most carriers
New: Porter added for high-value same-day/next-day deliveries in metro areas

Checkout flow:
  POST /v1/cart/checkout
    1. Load order items, calculate weight
    2. Check destination pincode
    3. If in-metro + order value > ₹2000 AND weight < 5kg:
         → Call Porter API: getShippingCost()
         → Use Porter rate
    4. Else:
         → Call Shiprocket API: getShippingRates()
         → Use cheapest Shiprocket carrier
    5. Include shipping cost in total
    6. Order created with carrier preference
  
  POST /orders/:id/confirm
    → order.carrier_preference = 'porter' | 'shiprocket'
    → (stock decrement unchanged)
  
  Background job (pgmq):
    if carrier = 'porter':
      createPorterShipment(order)
    else:
      createShiprocketShipment(order)
```

**Option 2: Swappable Shipping Provider via Feature Flag**
```
Supabase config table:
  shipping_provider = 'shiprocket' | 'porter' | 'hybrid'

If hybrid:
  getShippingCost() → returns Shiprocket + Porter options
  User picks in checkout (new UI)
  Order stores chosen provider
```

**Option 3: Pure Porter (unlikely)**
```
Replace Shiprocket entirely with Porter for all orders.
One-line backend change: update shipping provider config.
```

### Key Point: Razorpay Is Upstream

**Razorpay has ZERO dependency on Shiprocket/Porter:**
- Payment confirmed → Order created in DB → Stock decremented
- THEN a background job handles shipping

```
POST /orders/:id/confirm (Razorpay + stock)
  ↓ (async, no impact on payment)
pgmq.send('order_events', { orderId, ... })
  ↓ (background worker drains queue)
if shiprocket: createShiprocketShipment(order)
else if porter: createPorterShipment(order)
```

If Shiprocket/Porter fails, the order is already confirmed and payment already captured. Admins can manually create shipments later via the web panel.

---

## 7. Monthly Cost Breakdown

| Service | Plan | Monthly Cost | Notes |
|---|---|---|---|
| Razorpay | Pay-per-transaction | ~₹1,000–2,000* | 1.8% UPI, 2% card, ₹0 netbanking — estimated for Phase 1 order volume |
| Shiprocket | Volume-based | ₹2,000–5,000 | Weight-based, per shipment |
| Supabase (Edge Functions) | Included in Pro | ₹0 | Razorpay calls run on Edge Functions |

*Razorpay pricing: UPI 1.8%, Cards 2%, Netbanking ₹0. On ₹50,000 monthly orders (rough M3 baseline), ~₹1,400/month.

---

## 8. Secrets Required (Supabase Dashboard)

```
RAZORPAY_KEY_ID              ← Public key, shown in Razorpay dashboard
RAZORPAY_KEY_SECRET          ← Secret key, shown once when generated
RAZORPAY_WEBHOOK_SECRET      ← Your own random string, matched in Razorpay webhook config
```

Set via:
```bash
supabase secrets set RAZORPAY_KEY_ID=rzp_test_...
supabase secrets set RAZORPAY_KEY_SECRET=...
supabase secrets set RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
```

Verify:
```bash
supabase secrets list
```

---

## 9. Flow Diagram (ASCII)

```
                            Baker Ally Payment Flow

                                  Flutter App
                                      │
                                      ├─ User adds items to cart
                                      ├─ Taps "Proceed" checkout
                                      │
                 ┌────────────────────┴─────────────────────┐
                 │                                          │
            [STEP 1]                                   [STEP 2]
         Create Order                              Confirm Order
                 │                                          │
    POST /v1/cart/checkout                   POST /v1/orders/:id/confirm
         (Razorpay)                               (Razorpay)
                 │                                          │
         Backend:                                Backend:
    ┌────────────────────────────┐        ┌────────────────────────────┐
    │ 1. Validate cart/address   │        │ 1. Verify HMAC signature   │
    │ 2. Check stock (live)      │        │ 2. Atomic transaction:     │
    │ 3. Recompute prices        │        │    - Decrement stock_qty   │
    │ 4. Create Razorpay order   │        │    - Update order status   │
    │ 5. Return keyId + orderId  │        │    - Clear cart            │
    └────────────────────────────┘        │ 3. Enqueue pgmq job       │
             │                            │ 4. Return 201 confirmed   │
             └────────────────────┬───────┘
                                  │
                    Flutter opens Razorpay SDK
                    User pays (UPI/Card/NetBanking)
                    Returns {paymentId, signature}
                                  │
                                  └─→ Backend confirms order
                                      │
                                      └─→ Background Worker
                                          (pgmq queue drains)
                                              │
                                    ┌─────────┼─────────┐
                                    │         │         │
                            Shiprocket     In-app     FCM Push
                            (shipment)   (confirmed)  (notification)
                                    │         │         │
                                    └─────────┴─────────┘
                                            │
                                   User receives order confirmation
```

---

## Summary

**Razorpay integration in Milestone 3:**
- ✅ Two-step flow: create → confirm
- ✅ HMAC signature verification
- ✅ Idempotent retries
- ✅ Webhook dedup
- ✅ Atomic stock decrement
- ✅ Test mode ready, live mode on Phase 7 secret swap

**Porter integration (Milestone 4+):**
- Razorpay is **upstream** — independent of shipping provider
- Shipping provider chosen at order-creation time or via UI selector
- Background job (pgmq) routes to Shiprocket OR Porter after payment confirmed
- Zero impact on payment flow

**Open decision:** Which shipping model (flat, weight-based, hybrid Shiprocket + Porter) — decide before Phase 4.
