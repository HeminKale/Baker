# Milestone 3 Testing Without Razorpay

**What can we test in Phase 3 without Razorpay credentials.**

---

## ✅ What CAN Be Tested (No Razorpay Needed)

### 1. Guest Cart (Offline, Local Drift Only)
```
✅ Add items to cart as guest
✅ Quantity stepper (+ / − / button ↔ stepper animation)
✅ Cart badge updates on bottom nav
✅ Close and reopen app → cart persists (Drift cache)
✅ Remove items from cart
✅ Clear entire cart
```

**Test path:**
1. Open app (not logged in)
2. Browse catalog
3. Tap "Add to Cart" on any product
4. Verify stepper appears, qty updates
5. Tap back to catalog, add more items
6. Check cart badge shows total items
7. Kill app, reopen → cart still there ✓

---

### 2. Login & Cart Merge
```
✅ Add items as guest (stored in local Drift only)
✅ Tap login (Google or Email OTP)
✅ POST /v1/cart/merge fires automatically
✅ Guest items appear in server cart
✅ Drift synced with server response
✅ Verify no duplicate items
✅ Verify quantities added (not replaced)
```

**Test path:**
1. Add 2x Product A as guest
2. Login (Google)
3. Watch network inspector → `POST /v1/cart/merge` fires
4. Verify cart still shows 2x Product A
5. Add 1x Product B while logged in
6. Verify POST `/v1/cart/items` fires (server sync)
7. Verify cart now shows 2A + 1B ✓

---

### 3. Server Cart Operations (Logged In)
```
✅ GET /v1/cart → loads server cart
✅ POST /v1/cart/items → add/upsert items
✅ PATCH /v1/cart/items/:id → update quantity
✅ DELETE /v1/cart/items/:id → remove item
✅ DELETE /v1/cart → clear entire cart
✅ Quantity capped at stock_qty (max reached banner)
✅ Stepper animates button ↔ counter
```

**Test path:**
1. Login
2. Add items via stepper
3. Watch network tab:
   - First tap: `POST /v1/cart/items`
   - Increment: `PATCH /v1/cart/items/:id`
   - Decrement: `PATCH /v1/cart/items/:id`
   - Remove: `DELETE /v1/cart/items/:id`
4. Tap stepper + at max stock → button disables, snackbar ✓

---

### 4. Checkout UI Layout & Navigation
```
✅ Tap Cart tab → renders full checkout page
✅ Items list with steppers visible
✅ "You Might Also Like" horizontal scroll
✅ Bill Details card visible (subtotal, discount input, total)
✅ Cancellation policy visible
✅ Fixed bottom CTA bar (address row + payment row + Proceed)
✅ All text renders, no crashes
✅ Responsive layout (no layout overflow)
```

**Test path:**
1. Add items to cart (logged in)
2. Tap Cart tab
3. Scroll down, verify all sections visible
4. Screenshot for visual review
5. No crashes ✓

---

### 5. Address Selector (GET + POST)
```
✅ Tap "Add" on address bar → bottom sheet opens
✅ See existing addresses (if any)
✅ "Add New Address" form opens
✅ Fill in form: line1, city, state, pincode
✅ POST /v1/addresses → creates new address
✅ Address appears in list
✅ Tap address → selects it
✅ Bottom sheet closes
✅ Address shown on CTA bar
```

**Test path:**
1. In checkout, tap address "Add" button
2. See empty list (first address)
3. Tap "Add New Address"
4. Fill: "123 Main St", "Mumbai", "Maharashtra", "400001"
5. Tap Save
6. Watch network: `POST /v1/addresses` fires
7. Address appears in list + is selected
8. Bottom sheet closes
9. Address shown on CTA bar ✓

---

### 6. Discount Code Validation (GET + PATCH Bill)
```
✅ Tap discount input field
✅ Type "BAKE10" (seeded demo code)
✅ Tap Apply
✅ POST /v1/discounts/validate fires
✅ Response: { code: 'BAKE10', type: 'percent', value: 10, discountValue: xxx }
✅ Bill updates:
   - New line: "−10% (BAKE10) − ₹XX"
   - Total drops by discount amount
✅ Tap Remove → discount clears
✅ Bill recalculates
✅ Try invalid code → 404 error, snackbar shown
```

**Test path:**
1. In checkout, scroll to Bill Details
2. Type "BAKE10" in discount input
3. Tap Apply
4. Watch network: `POST /v1/discounts/validate`
5. Verify response: 10% off
6. Verify bill shows: −₹XX discount
7. Total reduced ✓
8. Try "INVALID" → snackbar "Invalid or expired code" ✓
9. Tap Remove on applied discount
10. Bill recalculates ✓

---

### 7. "You Might Also Like" Recommendations
```
✅ GET /v1/checkout/recommendations?variantIds=a,b,c fires
✅ Returns products from same subcategories
✅ Excludes products already in cart
✅ Displays horizontally (carousel)
✅ Can tap to view product detail
✅ Can add to cart from recommendations
```

**Test path:**
1. Add items from one subcategory
2. In checkout, scroll to recommendations
3. Watch network: `GET /checkout/recommendations`
4. Verify products from same subcategory appear
5. Verify products NOT in cart are shown
6. Tap one → product detail opens
7. Tap "Add to Cart" → added to cart ✓

---

### 8. Bill Calculation (Local Math, No Server Call)
```
✅ Subtotal = sum of (variant.currentPrice * quantity) for all items
✅ Discount value recomputed from type+value:
   - Percent: (subtotal * value / 100)
   - Flat: min(value, subtotal)
   - Free shipping: (discount value = 0, but shippingCost = 0)
✅ Shipping = ₹49 (flat placeholder, no discount) OR 0 if free shipping
✅ Total = subtotal - discountValue + shippingCost
✅ Changes instantly when cart/discount changes
```

**Test path:**
1. Add 2x ₹100 items = ₹200 subtotal
2. Bill shows: Subtotal ₹200
3. Apply BAKE10 (10% = ₹20 off)
4. Bill shows: Discount −₹20, Total ₹169 (200 - 20 + 49 shipping)
5. Remove discount
6. Bill shows: Total ₹249 (200 + 49 shipping) ✓

---

### 9. Empty Cart State
```
✅ Delete all items from cart
✅ Tab switches to "Empty Cart" view
✅ Shows icon + message
✅ "Browse Catalog" button works → navigates to catalog
```

**Test path:**
1. With items in cart, tap delete on each
2. Last item deleted → page transitions to empty state
3. Tap "Browse Catalog" → navigates to Catalog tab ✓

---

### 10. Stock Recheck Before Checkout (Server-Side Preview)
```
✅ Stock displayed next to each item ("In Stock" or "Low Stock (2 left)")
✅ Stock_qty capped at variant.stock_qty
✅ No actual checkout attempt (Razorpay skipped)
```

**Test path:**
1. Add item with low stock (< 5 units)
2. In checkout, verify "Low Stock" badge shown
3. Try to add more via stepper → blocked at max ✓

---

## ⚠️ What CANNOT Be Tested (Razorpay Required)

### These endpoints need stubbing or will fail:

```
❌ POST /v1/cart/checkout
   └─ Fails at: razorpay.orders.create() (no API key)
   └─ Need to: Stub out Razorpay order creation, return mock order

❌ POST /v1/orders/:id/confirm
   └─ Fails at: verifyPaymentSignature() (no signature to verify)
   └─ Need to: Stub the confirm logic

❌ POST /v1/webhooks/razorpay
   └─ Won't be triggered (no Razorpay account to send webhooks)

❌ Razorpay SDK Payment Sheet
   └─ Won't open on Flutter (no Key ID to configure)

❌ Stock Decrement
   └─ Happens in confirm step → skipped without Razorpay

❌ Cart Clear After Order
   └─ Happens in confirm step → skipped without Razorpay

❌ Order Confirmation Screen
   └─ Only reachable after confirm → can't test visually
```

---

## How to Stub Razorpay (If You Want to Test Checkout UI)

### Option A: Stub in Backend (Easiest)

Edit `baker_ally_backend/routes/checkout.ts`:

```typescript
// Stub: Skip Razorpay order creation, return mock order
const razorpayOrder = {
  id: `razorpay_order_stub_${Date.now()}`,
  amount: totalInPaise,
  currency: 'INR',
}

// Or skip entire Razorpay flow and test confirm directly
```

### Option B: Stub in Flutter (App-Side)

Edit `baker_ally_flutter/lib/features/checkout/presentation/screens/checkout_screen.dart`:

```dart
// Replace _placeOrder with stub that skips Razorpay
Future<void> _placeOrder() async {
  // Bypass checkout, go straight to confirmation
  context.go('/checkout/confirmation', extra: {
    'orderId': 'mock_order_${DateTime.now().millisecondsSinceEpoch}',
    'total': ref.read(billSummaryProvider).total,
  });
}
```

---

## Summary: What You CAN Test Now

| Feature | Testable | Notes |
|---|---|---|
| **Guest cart** | ✅ | Local only, no server |
| **Login & merge** | ✅ | POST /cart/merge |
| **Server cart CRUD** | ✅ | GET/POST/PATCH/DELETE items |
| **Address management** | ✅ | GET/POST addresses |
| **Discount validation** | ✅ | POST /discounts/validate + BAKE10 |
| **Bill calculation** | ✅ | Live math in Flutter |
| **Recommendations** | ✅ | GET /checkout/recommendations |
| **Checkout UI layout** | ✅ | Renders, no crashes |
| **Cart stepper** | ✅ | Button ↔ counter animation |
| **Cart badge** | ✅ | Bottom nav updates |
| **Checkout procedure** | ⚠️ | Needs Razorpay stub to test confirm |
| **Stock decrement** | ❌ | Happens in confirm → skipped |
| **Order confirmation** | ❌ | Unreachable without Razorpay |
| **Webhooks** | ❌ | No Razorpay account to test |

---

## Recommended Test Flow (Without Razorpay)

1. **Guest flow:**
   - Add items to cart (offline)
   - Close app, reopen → items persist ✓

2. **Login & merge:**
   - Login with Google/OTP
   - Watch `POST /cart/merge` fire
   - Items appear in server cart ✓

3. **Checkout page:**
   - Navigate to Cart tab
   - Verify all UI renders
   - No crashes ✓

4. **Address add:**
   - Tap address button
   - Add new address
   - Verify `POST /addresses` fires
   - Address selected ✓

5. **Discount code:**
   - Type "BAKE10"
   - Tap Apply
   - Verify discount applied
   - Bill updates ✓

6. **Recommendations:**
   - Scroll to "You Might Also Like"
   - Verify products shown
   - Can add to cart ✓

7. **Empty cart:**
   - Remove all items
   - Verify empty state
   - Browse Catalog button works ✓

---

## If You Want to Test Confirm Flow

**Option 1:** Set up Razorpay (takes 10 minutes)
- Best for end-to-end validation
- Real payment gateway testing

**Option 2:** Stub Razorpay in code (5 minutes)
- Quick visual testing of order confirmation screen
- Skip payment signature verification
- Mock stock decrement

**I recommend: Do the full Razorpay setup** (takes ~30 min) so you can test the real payment flow. Otherwise, 90% of your tests will pass but the last 10% (payment + confirm) needs either:
- Real Razorpay keys, OR
- Backend/Flutter stubs

---

## Next Steps

**Without Razorpay:**
1. Deploy Milestone 3 code as-is
2. Run through the 7 test flows above (✅ testable)
3. When ready, add Razorpay setup (10 min) to complete end-to-end testing

**Shall I create a step-by-step test guide for the 7 flows?**
