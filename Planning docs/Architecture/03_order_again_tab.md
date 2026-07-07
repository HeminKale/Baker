# Baker Ally — Order Again Tab Architecture
> Third tab in bottom navigation.
> Shows two sections: Frequently Bought Together (group reorders) + Previously Bought (individual items).
> Last updated: July 2026

---

## Table of Contents

1. [What This Tab Is For](#1-what-this-tab-is-for)
2. [Full Page Layout](#2-full-page-layout)
3. [Section 1 — Frequently Bought Together](#3-section-1--frequently-bought-together)
4. [Group Tile Design](#4-group-tile-design)
5. [Group Detail Bottom Sheet](#5-group-detail-bottom-sheet)
6. [Section 2 — Previously Bought](#6-section-2--previously-bought)
7. [Previously Bought Tile Design](#7-previously-bought-tile-design)
8. [Empty & First-Time States](#8-empty--first-time-states)
9. [Data & API](#9-data--api)
10. [Backend Computation Logic](#10-backend-computation-logic)
11. [Riverpod State](#11-riverpod-state)
12. [Flutter Packages Used](#12-flutter-packages-used)

---

## 1. What This Tab Is For

Bakers are **repeat buyers** — they order the same cream, same chocolate, same boxes every week. This tab removes the friction of finding those items again in the catalog.

Two distinct experiences:
- **Frequently Bought Together** — shows *groups* of items the user (or other users) commonly order at the same time. One tap adds a whole bundle to cart.
- **Previously Bought** — shows individual products the logged-in user has bought before. Quick re-add with qty control.

---

## 2. Full Page Layout

```
┌─────────────────────────────────────────────────────┐
│  [📍 Address ▼]                      [🔔]  [👤]     │  ← global top bar
│  [🔍 Search icon]                                    │
├─────────────────────────────────────────────────────┤
│                                                       │
│  Order Again                                          │  ← screen title
│                                                       │
│  ─── FREQUENTLY BOUGHT TOGETHER ───────────────     │
│  ← [ group tile ] [ group tile ] [ group tile ] →   │  ← horizontal scroll
│                                                       │
│  ─── PREVIOUSLY BOUGHT ─────────────────────────    │
│                                                       │
│  ┌──────────────────┐  ┌──────────────────┐         │
│  │ [product tile]   │  │ [product tile]   │         │  ← 2-column grid
│  └──────────────────┘  └──────────────────┘         │
│  ┌──────────────────┐  ┌──────────────────┐         │
│  │ [product tile]   │  │ [product tile]   │         │
│  └──────────────────┘  └──────────────────┘         │
│                                                       │
│  (scrolls vertically — grid continues below)          │
│                                                       │
└─────────────────────────────────────────────────────┘
│  [Home] [Catalog] [Order Again★] [🍪] [Cart 🔴]     │
└─────────────────────────────────────────────────────┘
```

---

## 3. Section 1 — Frequently Bought Together

**Shows user's own groups first, then platform-wide popular groups.**

- Top 10 groups total — horizontal scroll
- Each group = a set of variants that were ordered together in one order
- User's own history shown first (more relevant), then platform-wide groups fill remaining slots
- Section heading: "Frequently Bought Together"

### Priority Order

```
1. User's own order groups — ranked by how often they ordered that combo
2. Platform-wide popular groups — ranked by frequency across all users
   (only shown if user has < 10 personal groups)
```

---

## 4. Group Tile Design

Each group tile is a card in the horizontal scroll row.

```
┌──────────────────────────────────┐
│                                  │
│   [img 1] ➕ [img 2]  +3 items   │  ← 2 product images + overflow count
│                                  │
│   Fresh Cream + Dark Choc...     │  ← truncated group name
│   5 items · ₹1,240               │  ← item count + total price
│                                  │
│   [ Add All to Cart ]            │  ← primary action
│                                  │
└──────────────────────────────────┘
```

**Image display rules:**
- Always show exactly 2 product images side by side with a `➕` between them
- If group has more than 2 items → show `+N items` text overlay on second image
- Images: `cached_network_image`, circular or rounded square

**Group name:**
- Auto-generated from first 2 product names — `"Fresh Cream + Dark Choc..."`
- Truncated with ellipsis if too long

**Price:**
- Sum of `current_price × default_quantity` for all variants in the group
- If any item in group is out of stock → show "Some items unavailable" in amber, "Add All to Cart" still works for in-stock items

**Tap on tile body** → opens Group Detail Bottom Sheet (not Add All)
**Tap "Add All to Cart"** → adds all items in group at qty 1 directly, shows cart badge update

---

## 5. Group Detail Bottom Sheet

Opens when user taps the tile body (not the button). 85% screen height, vertically scrollable.

```
┌──────────────────────────────────────────────────┐
│           ─────  (drag handle)                   │
│  Fresh Cream, Dark Choc & more          [✕]      │
│  ─────────────────────────────────────────────   │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │ [img] Fresh Cream 25%                      │  │
│  │       500ml · Ingredients                  │  │
│  │       ₹95             [ − ] 1 [ + ]        │  │  ← qty stepper per item
│  ├────────────────────────────────────────────┤  │
│  │ [img] Dark Compound Chocolate              │  │
│  │       1kg · Cocoa & Chocolates             │  │
│  │       ₹380            [ − ] 1 [ + ]        │  │
│  ├────────────────────────────────────────────┤  │
│  │ [img] Cake Box 8 inch                      │  │
│  │       Pack of 10 · Packaging               │  │
│  │       ~~₹180~~ ₹150   [ − ] 1 [ + ]        │  │
│  ├────────────────────────────────────────────┤  │
│  │ [img] Vanilla Essence                      │  │
│  │       100ml · Food Flavours                │  │
│  │       ₹65             [ − ] 1 [ + ]        │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ─────────────────────────────────────────────   │
│  Total: ₹690                                     │
│  [ Add Selected Items to Cart ]                  │  ← adds all with chosen qtys
└──────────────────────────────────────────────────┘
```

**Stepper in sheet:**
- Default qty = 1 for each item
- User can adjust individual items before adding
- Deselecting: tap `−` to 0 → item row greys out, excluded from cart add
- Out-of-stock items shown with "Out of Stock" badge — qty stepper disabled for those items

**"Add Selected Items to Cart":**
- Adds all non-zero, in-stock items to cart
- Sheet closes
- Cart badge updates
- Snackbar: "5 items added to cart" with [View Cart] action

---

## 6. Section 2 — Previously Bought

Individual products the logged-in user has ordered before — sorted by most recently bought first. Displayed in a **2-column grid** below the Frequently Bought Together section.

**This section is infinite scroll** — loads 20 items at a time, fetches more as user scrolls down.

---

## 7. Previously Bought Tile Design

Same dimensions as catalog product tile. Identical add-to-cart interaction (button → stepper).

```
┌──────────────────────────┐
│                          │
│      [Product Image]     │
│                          │
│  Fresh Cream 25%         │  ← product name (2 lines max)
│  500ml                   │  ← variant name
│                          │
│  ~~₹120~~  ₹95           │  ← strike price if discounted
│                          │
│  Last bought: 2 Jul      │  ← recency indicator — unique to this tab
│                          │
│  ┌──────────────────┐    │
│  │  + Add to Cart   │    │  ← same interaction as catalog tile
│  └──────────────────┘    │
└──────────────────────────┘
```

**"Last bought" label** — small muted text showing when user last ordered this product. Makes it easy to identify recently used vs long-ago items.

Out-of-stock items:
- Still shown (user may want to wait for restock)
- "Out of Stock" badge overlaid on image
- "Add to Cart" button replaced with "Notify Me" button (future feature — placeholder for now)

---

## 8. Empty & First-Time States

### New user — no orders yet

Both sections are empty. Show a single full-screen empty state:

```
┌─────────────────────────────────────────────────┐
│                                                  │
│                🛒                                │
│                                                  │
│         No order history yet                     │
│   Place your first order and we'll show          │
│   your frequently bought items here              │
│                                                  │
│        [ Browse Catalog → ]                      │
│                                                  │
└─────────────────────────────────────────────────┘
```

### User has orders but no groups (only 1 item per order)

Frequently Bought Together section is hidden entirely. Only Previously Bought section shown.

### User has personal groups but < 10

Platform-wide popular groups fill remaining slots up to 10 total.

---

## 9. Data & API

| Action | Endpoint | Method | Notes |
|---|---|---|---|
| Load frequently bought together | `/v1/order-again/frequently-bought` | GET | Returns user groups first, then platform groups |
| Load previously bought | `/v1/order-again/previously-bought?page=1&limit=20` | GET | Paginated, sorted by last order date |
| Add group to cart | `/v1/cart/items/batch` | POST | `[{ variantId, quantity }]` array |
| Add single item | `/v1/cart/items` | POST | Same as catalog add |

---

## 10. Backend Computation Logic

### Frequently Bought Together

```typescript
// GET /v1/order-again/frequently-bought
// Step 1: Get user's own order groups
const userGroups = await db
  .select({
    orderId: orderItems.orderId,
    variantIds: sql`array_agg(${orderItems.variantId})`,
  })
  .from(orderItems)
  .innerJoin(orders, eq(orders.id, orderItems.orderId))
  .where(eq(orders.userId, jwtUser.id))
  .groupBy(orderItems.orderId)
  .orderBy(desc(orders.createdAt))

// Step 2: Deduplicate groups (same set of variants = same group)
// Sort variantIds within each group → hash → count frequency
// Return top groups ranked by frequency

// Step 3: If user has < 10 personal groups, fill from platform-wide groups
// Same query without WHERE user_id filter, exclude groups already shown
```

### Previously Bought

```typescript
// GET /v1/order-again/previously-bought
const items = await db
  .selectDistinctOn([orderItems.variantId], {
    variantId: orderItems.variantId,
    lastOrderedAt: sql`MAX(${orders.createdAt})`,
    // ... product + variant + image fields via joins
  })
  .from(orderItems)
  .innerJoin(orders, eq(orders.id, orderItems.orderId))
  .innerJoin(productVariants, eq(productVariants.id, orderItems.variantId))
  .innerJoin(products, eq(products.id, productVariants.productId))
  .where(eq(orders.userId, jwtUser.id))
  .groupBy(orderItems.variantId)
  .orderBy(desc(sql`MAX(${orders.createdAt})`))
  .limit(20)
  .offset(page * 20)
```

---

## 11. Riverpod State

```dart
// Frequently bought together groups
final frequentlyBoughtProvider = FutureProvider<List<OrderGroup>>((ref) async {
  return ref.read(orderAgainRepositoryProvider).getFrequentlyBought();
});

// Previously bought — paginated
final previouslyBoughtProvider = StateNotifierProvider<
  PreviouslyBoughtNotifier,
  AsyncValue<List<PreviouslyBoughtItem>>
>((ref) {
  return PreviouslyBoughtNotifier(ref.read(orderAgainRepositoryProvider));
});

// Group detail sheet state — which group is currently open
final activeGroupProvider = StateProvider<OrderGroup?>((ref) => null);
```

---

## 12. Flutter Packages Used

| Package | Purpose |
|---|---|
| `flutter_riverpod` | All state — groups, previously bought, active group sheet |
| `dio` | API calls to `/v1/order-again/*` |
| `cached_network_image` | Product images in group tiles and previously bought grid |
| `drift` | Cache previously bought list locally — available offline |

---

## Key Rules

- **User's own history takes priority** over platform-wide groups in Frequently Bought Together
- **Platform-wide groups are anonymised** — no user data leaked, just aggregate co-purchase patterns
- **Out-of-stock items are shown** in previously bought (not hidden) — user should know the product exists even if temporarily unavailable
- **"Add All to Cart"** on tile adds at qty 1 — user can adjust inside the sheet if they want different quantities
- **Previously bought is infinite scroll** — not paginated with numbered pages, loads seamlessly as user scrolls
- **Last bought date** shown on tile — this tab is about recency, so the date helps users find what they ordered recently vs a long time ago
