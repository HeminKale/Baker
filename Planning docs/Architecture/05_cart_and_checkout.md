# Baker Ally — Cart & Checkout Architecture
> Covers: product tile add-to-cart interaction → cart state → checkout page → payment
> Last updated: July 2026

---

## Table of Contents

1. [Product Tile — Add to Cart Interaction](#1-product-tile--add-to-cart-interaction)
2. [Cart State & Sync](#2-cart-state--sync)
3. [Cart Tab (entry point to checkout)](#3-cart-tab-entry-point-to-checkout)
4. [Checkout Page — Full Layout](#4-checkout-page--full-layout)
5. [Fixed Bottom CTA Bar](#5-fixed-bottom-cta-bar)
6. [Address Selector Bottom Sheet](#6-address-selector-bottom-sheet)
7. [Payment Mode Bottom Sheet](#7-payment-mode-bottom-sheet)
8. [You Might Also Like](#8-you-might-also-like)
9. [Discount Code](#9-discount-code)
10. [Order Confirmation Screen](#10-order-confirmation-screen)
11. [Data & API](#11-data--api)
12. [Riverpod State](#12-riverpod-state)
13. [Flutter Packages Used](#13-flutter-packages-used)

---

## 1. Product Tile — Add to Cart Interaction

Every product tile across the app (catalog grid, home tiles, wishlist, order again) follows the same interaction pattern.

### Tile Layout

```
┌──────────────────────────┐
│                          │
│      [Product Image]     │  ← cached_network_image, aspect ratio 1:1
│                          │
│  ~~₹120~~  ₹95           │  ← strike-through original, bold current price
│                          │
│  ┌──────────────────┐    │
│  │   + Add to Cart  │    │  ← outlined button, brand colour
│  └──────────────────┘    │
└──────────────────────────┘
```

### After Tapping "Add to Cart"

The button **transforms in place** into a quantity stepper — no page navigation, no modal:

```
┌──────────────────────────┐
│                          │
│      [Product Image]     │
│                          │
│  ~~₹120~~  ₹95           │
│                          │
│  ┌────┬──────────┬────┐  │
│  │ −  │    1     │ +  │  ← stepper replaces the button
│  └────┴──────────┴────┘  │
└──────────────────────────┘
```

### Stepper Behaviour

| Action | Result |
|---|---|
| Tap `+` | qty + 1, cart updated instantly via Riverpod + Drift |
| Tap `−` when qty > 1 | qty - 1, cart updated |
| Tap `−` when qty = 1 | qty goes to 0, stepper animates back to "Add to Cart" button, item removed from cart |
| Tap `+` beyond stock_qty | `+` button disabled, shows "Max stock reached" tooltip |

### Animation
- Button → stepper: `AnimatedSwitcher` with fade + scale (150ms)
- Stepper → button (on removal): same reverse animation

### Cart Badge on Bottom Nav
Updates instantly on every `+` / `−` tap — driven by `cartProvider.totalItems`.

---

## 2. Cart State & Sync

### Two-layer Architecture

```
User taps + on tile
  → cartProvider (Riverpod) updated immediately   ← UI reflects instantly
  → Drift (local SQLite) written                  ← survives app kill
  → Background Dio call: POST /v1/cart/items      ← server synced async
      → if conflict (out of stock): server corrects Drift + shows snackbar
```

### On App Launch / Login

```
GET /v1/cart
  → server cart loaded into Drift
  → cartProvider initialised from Drift
  → UI renders from cartProvider
```

### Guest User

- Can browse catalog and **add items to cart freely** — stored in Drift locally, no server call
- Cannot checkout — tapping Proceed on checkout shows login bottom sheet
- After login → `POST /v1/cart/merge` sends local Drift items to server cart
- Server merges (quantities added if item already in server cart)
- Drift synced from server response, checkout continues

---

## 3. Cart Tab (entry point to checkout)

Tapping the Cart tab in the bottom nav takes the user directly to the **Checkout Page** — there is no separate intermediate "cart review" screen. The checkout page is the cart.

If cart is empty:

```
┌─────────────────────────────────────────────────┐
│  ← (no back on tab)     Your Cart               │
│                                                  │
│                                                  │
│              🛒                                  │
│         Your cart is empty                       │
│    Add items from the catalog to begin           │
│                                                  │
│       [ Browse Catalog → ]                       │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## 4. Checkout Page — Full Layout

Single scrollable page. All sections stacked vertically. Fixed CTA bar pinned to bottom (never scrolls away).

```
┌─────────────────────────────────────────────────────┐
│  ←          Your Order              🛒 3 items       │  ← top bar
├─────────────────────────────────────────────────────┤
│                                                       │
│  ─── ITEMS IN YOUR CART ────────────────────────    │
│                                                       │
│  ┌───────────────────────────────────────────────┐  │
│  │  [img]  Fresh Cream 25%        [ − ] 2 [ + ]  │  │
│  │         500ml · Ingredients                   │  │
│  │         ~~₹120~~  ₹95                         │  │
│  ├───────────────────────────────────────────────┤  │
│  │  [img]  Dark Compound Chocolate [ − ] 1 [ + ] │  │
│  │         1kg · Cocoa & Chocolates              │  │
│  │         ₹380                                  │  │
│  ├───────────────────────────────────────────────┤  │
│  │  [img]  Cake Box 8 inch        [ − ] 3 [ + ]  │  │
│  │         Pack of 10 · Packaging                │  │
│  │         ~~₹180~~  ₹150                        │  │
│  └───────────────────────────────────────────────┘  │
│                                                       │
│  ─── YOU MIGHT ALSO LIKE ───────────────────────    │
│  [ tile ][ tile ][ tile ][ tile ]  ← horizontal scroll│
│                                                       │
│  ─── BILL DETAILS ──────────────────────────────    │
│  ┌───────────────────────────────────────────────┐  │
│  │  Item total                       ₹1,040      │  │
│  │  Discount (BAKE10)              − ₹104        │  │
│  │  Delivery charges                   ₹49       │  │
│  │  ─────────────────────────────────────────    │  │
│  │  To pay                           ₹985        │  │
│  │                                               │  │
│  │  ┌─────────────────────────┐  ┌──────────┐   │  │
│  │  │ Enter discount code...  │  │  Apply   │   │  │
│  │  └─────────────────────────┘  └──────────┘   │  │
│  └───────────────────────────────────────────────┘  │
│                                                       │
│  ─── CANCELLATION POLICY ───────────────────────    │
│  ┌───────────────────────────────────────────────┐  │
│  │  Orders can be cancelled within 2 hours of    │  │
│  │  placement. Once dispatched, cancellations    │  │
│  │  are not accepted. For returns, contact us    │  │
│  │  within 24 hours of delivery.                 │  │
│  └───────────────────────────────────────────────┘  │
│                                                       │
│  (bottom padding to avoid content hiding behind CTA) │
│                                                       │
└─────────────────────────────────────────────────────┘
```

---

## 5. Fixed Bottom CTA Bar

**Always visible — never scrolls.** Two rows pinned to the very bottom of the screen above the system navigation bar.

```
┌─────────────────────────────────────────────────────┐
│  📍 Home, 123 MG Road, Mumbai     [Change]          │  ← Row 1: Address
├─────────────────────────────────────────────────────┤
│  💳 UPI  ∧              ₹985    [ Proceed → ]       │  ← Row 2: Payment | Amount | CTA
└─────────────────────────────────────────────────────┘
```

### Row 1 — Delivery Address

- Shows selected address label + first line
- **[Change]** button → opens Address Selector bottom sheet (85% height)
- If no address saved → shows "Add delivery address" in red

### Row 2 — Payment Mode | Amount | Proceed

| Element | Behaviour |
|---|---|
| Payment mode label (e.g. "💳 UPI") | Shows currently selected method |
| `∧` up arrow | Taps opens Payment Mode bottom sheet to change |
| Amount `₹985` | Live — updates when qty / discount changes |
| `[ Proceed → ]` button | Triggers order creation flow |

The `∧` arrow makes it clear the payment section is expandable/changeable without being a separate page.

### Proceed Button States

```
Idle:       [ Proceed → ]           ← brand colour, enabled
Loading:    [ ⟳ Placing order... ]  ← spinner, disabled
Disabled:   [ Proceed → ]           ← greyed out if no address selected
```

---

## 6. Address Selector Bottom Sheet

Opens from **[Change]** on CTA bar. 85% screen height, draggable.

```
┌──────────────────────────────────────────────────┐
│           ─────  (drag handle)                   │
│  Select Delivery Address                  [✕]    │
│  ──────────────────────────────────────────────  │
│                                                  │
│  ● Home  (Default)                               │  ← radio selection
│    Priya Sharma · 123 MG Road, Flat 4B           │
│    Mumbai – 400001 · +91 98765 43210             │
│                                                  │
│  ○ Bakery Studio                                 │
│    456 Link Road, Shop 12                        │
│    Mumbai – 400053                               │
│                                                  │
│  ○ + Add New Address                             │  ← opens address form
│                                                  │
│  ──────────────────────────────────────────────  │
│  [ Deliver to Selected Address ]                 │  ← confirms selection, closes sheet
└──────────────────────────────────────────────────┘
```

On "Deliver to Selected Address":
- `selectedAddressProvider` updated
- CTA row 1 updates to show selected address
- Sheet dismisses

---

## 7. Payment Mode Bottom Sheet

Opens from tapping `∧` on CTA bar Row 2.

```
┌──────────────────────────────────────────────────┐
│           ─────  (drag handle)                   │
│  Choose Payment Method                    [✕]    │
│  ──────────────────────────────────────────────  │
│                                                  │
│  ● UPI                                           │  ← recommended, free
│    Google Pay, PhonePe, Paytm, any UPI app       │
│                                                  │
│  ○ Debit / Credit Card                           │
│    Visa, Mastercard, RuPay                       │
│                                                  │
│  ○ Netbanking                                    │
│    All major Indian banks                        │
│                                                  │
│  ──────────────────────────────────────────────  │
│  Note: All payments secured by Razorpay          │
└──────────────────────────────────────────────────┘
```

Selection updates the CTA bar label. Sheet auto-dismisses on selection.

> Note: Actual payment UI (entering UPI ID, card details) is handled by the **Razorpay SDK** — Baker Ally does not build any payment input forms.

---

## 8. You Might Also Like

Shown between cart items and bill details.

```
─── YOU MIGHT ALSO LIKE ─────────────────────────
[ tile ][ tile ][ tile ][ tile ] →
```

- Horizontal scrollable row
- Products from the same subcategories as items in cart
- Excludes items already in cart
- Each tile: image, name, price, + Add to Cart button (same tile interaction as catalog)
- API: `GET /v1/checkout/recommendations?variantIds=id1,id2`

---

## 9. Discount Code

Inside Bill Details section.

```
┌────────────────────────────┐  ┌──────────┐
│  Enter discount code...    │  │  Apply   │
└────────────────────────────┘  └──────────┘
```

States:

```
Idle:      [Enter discount code...]  [Apply]
Loading:   [BAKE10             ]  [ ⟳ ]
Valid:     ✅ BAKE10 applied — ₹104 saved    [Remove]
Invalid:   ❌ Invalid or expired code
```

On valid code:
- Bill Details section updates live (discount line appears)
- CTA bar amount updates
- Code stored in `checkoutProvider.discountCode`

API: `POST /v1/discounts/validate { code, cartTotal }`

---

## 10. Order Confirmation Screen

After successful payment, replaces checkout page (no back navigation to checkout):

```
┌─────────────────────────────────────────────────────┐
│                                                       │
│                    ✅                                 │
│           Order Placed Successfully!                  │
│                                                       │
│           Order ID:  ORD-3392                         │
│           Total paid:  ₹985                           │
│                                                       │
│  ┌───────────────────────────────────────────────┐  │
│  │  📱 You'll receive a WhatsApp confirmation    │  │
│  │     on +91 98765 43210                        │  │
│  └───────────────────────────────────────────────┘  │
│                                                       │
│  Estimated delivery: 9 Jul – 11 Jul 2026              │
│                                                       │
│  ─────────────────────────────────────────────────  │
│                                                       │
│  [ Track Order ]          [ Continue Shopping ]       │
│                                                       │
└─────────────────────────────────────────────────────┘
```

On reaching this screen:
- Cart is cleared (Drift + server)
- `cartProvider` reset to empty
- Cart badge on bottom nav → 0

---

## 11. Data & API

| Action | Endpoint | Method | Notes |
|---|---|---|---|
| Load cart | `/v1/cart` | GET | On app open / login |
| Add item | `/v1/cart/items` | POST | `{ variantId, quantity }` |
| Update qty | `/v1/cart/items/:id` | PATCH | `{ quantity }` |
| Remove item | `/v1/cart/items/:id` | DELETE | — |
| Clear cart | `/v1/cart` | DELETE | After order confirmed |
| Recommendations | `/v1/checkout/recommendations` | GET | `?variantIds=...` |
| Validate discount | `/v1/discounts/validate` | POST | `{ code, cartTotal }` |
| Create pending order + Razorpay order | `/v1/cart/checkout` | POST | Creates `orders` row (status=pending), returns `razorpayOrderId, amount, keyId` |
| Confirm order after payment | `/v1/orders/:id/confirm` | POST | `{ razorpayPaymentId, razorpaySignature }` — updates row to confirmed |

---

## 12. Riverpod State

```dart
// Cart — persisted in Drift, synced with server
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(
    ref.read(cartRepositoryProvider),   // Dio + server
    ref.read(localCartDaoProvider),     // Drift
  );
});

// CartState shape
class CartState {
  final List<CartItem> items;
  final int totalItems;
  final int subtotal;           // paise
  final int discountValue;      // paise
  final int shippingCost;       // paise
  final int total;              // paise
  final String? discountCode;
  final DiscountResult? discount;
}

// Selected address for checkout
final selectedAddressProvider = StateProvider<Address?>((ref) => null);

// Selected payment method
final selectedPaymentMethodProvider = StateProvider<PaymentMethod>((ref) => PaymentMethod.upi);

// Checkout flow status
final checkoutStatusProvider = StateProvider<CheckoutStatus>((ref) => CheckoutStatus.idle);
// idle | validatingPrices | openingRazorpay | confirming | success | failed
```

---

## 13. Flutter Packages Used

| Package | Purpose |
|---|---|
| `flutter_riverpod` | Cart state, checkout state machine |
| `drift` + `drift_flutter` | Local cart persistence — instant UI |
| `dio` | All cart + checkout API calls |
| `razorpay_flutter` | Opens Razorpay payment sheet |
| `cached_network_image` | Product images in cart rows + recommendations |
| `flutter_form_builder` | Discount code input field |
| `flutter_secure_storage` | JWT attached to all Dio calls |

---

## Key Rules

- **Prices re-validated server-side** before Razorpay order is created — if any price changed, user sees updated total before paying
- **Stock check at checkout** — if a cart item went out of stock between add and checkout, user is shown which item is unavailable before payment opens
- **Cart persists across sessions** — Drift keeps cart on device, server is source of truth on login
- **Qty 0 = removal** — tapping `−` to zero removes item and animates button back, no explicit "remove" button needed
- **One active cart per user** — server enforces this via `UNIQUE(user_id)` on `carts` table
- **Razorpay handles all payment UI** — Baker Ally never shows card/UPI input fields directly
