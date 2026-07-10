# Baker Ally — Catalog Tab Architecture
> Second tab in bottom navigation.
> Three-level navigation: Category grid → Subcategory with product grid → Product detail.
> Last updated: July 2026

---

## Table of Contents

1. [Overview & Navigation Flow](#1-overview--navigation-flow)
2. [Level 1 — Category Grid](#2-level-1--category-grid)
3. [Level 2 — Subcategory + Product Grid](#3-level-2--subcategory--product-grid)
4. [Level 3 — Product Detail Page](#4-level-3--product-detail-page)
5. [Product Tile — Full Spec](#5-product-tile--full-spec)
6. [Wishlist Heart](#6-wishlist-heart)
7. [Filters & Sorting](#7-filters--sorting)
8. [Empty & Edge States](#8-empty--edge-states)
9. [Data & API](#9-data--api)
10. [Riverpod State](#10-riverpod-state)
11. [Flutter Packages Used](#11-flutter-packages-used)

---

## 1. Overview & Navigation Flow

```
Catalog Tab (tap)
  → Level 1: All categories as section headings, subcategories as horizontal tiles
      → Tap a subcategory tile
          → Level 2: Product grid, left strip pre-selected to tapped subcategory
              → Tap a product tile
                  → Level 3: Product Detail Page
                      → Add to Cart → stays on page, cart badge updates
                      → ← Back → returns to Level 2
```

GoRouter paths:
```
/catalog                            → Level 1: full category+subcategory scroll
/catalog/:categoryId/:subId         → Level 2: product grid, subcategory pre-selected
/product/:productId                 → Level 3: product detail
```

---

## 2. Level 1 — Category Screen (Scrollable, No Category Tiles)

Entry point for the Catalog tab. The screen is a **single vertical scroll** — each category occupies its own named section with a horizontal row of its subcategory tiles directly below.

No category tiles. Categories are just bold section headings. Subcategories are the tappable units.

```
┌─────────────────────────────────────────────────────┐
│  [📍 Address ▼]                      [🔔]  [👤]     │
│  [🔍 Search icon]                                    │
├─────────────────────────────────────────────────────┤
│                                                       │
│  Catalog                                              │
│                                                       │
│  Ingredients                                          │  ← category label (bold, not tappable)
│  ← [ img      ] [ img      ] [ img      ] →          │  ← horizontal scroll
│    [Creams    ] [Cocoa &   ] [Fruit     ]             │
│                 [Chocolates] [Fillings  ]             │
│                                                       │
│  Packaging                                            │
│  ← [ img      ] [ img      ] [ img      ] →          │
│    [Cake Boxes] [Dessert   ] [PVC &     ]             │
│                 [Boxes    ] [Acrylic   ]              │
│                                                       │
│  Tools & Equipment                                    │
│  ← [ img      ] [ img      ] [ img      ] →          │
│    [Speciality] [Kitchen   ] [Structure ]             │
│    [Tools    ] [Appliances] [Tools    ]               │
│                                                       │
│  Cake Decorations                                     │
│  ← [ img      ] [ img      ] [ img      ] →          │
│    [Edible    ] [Non Edible] [Add-ons  ]              │
│    [Decoratio.] [Decoratio.]                          │
│                                                       │
│  Seasonal & New Collections                           │
│  ← [ img      ] [ img      ] [ img      ] →          │
│    [Collections] [Stock     ] [New      ]             │
│    [for Festive] [Clearance ] [Arrivals ]             │
│                                                       │
│  Bakeware                                             │
│  ← [ img      ] [ img      ] [ img      ] →          │
│    [Cake      ] [Dessert   ] [Paper    ]              │
│    [Moulds   ] [Moulds    ] [Moulds   ]               │
│                                                       │
├─────────────────────────────────────────────────────┤
│  [Home] [Catalog★] [Order Again] [🍪] [Cart 🔴]     │  ← bottom nav always visible
└─────────────────────────────────────────────────────┘
```

### Subcategory Tile (the tappable unit)

```
┌──────────────────┐
│                  │
│  [subcat image]  │  ← square image, aspect 1:1
│                  │
│  Creams          │  ← subcategory name, centred, 2 lines max
└──────────────────┘
```

- Fixed width (~100–110px), image fills width
- Name below image, centred, 2 lines max with ellipsis
- Image from `sub_categories.image_url` via Supabase Storage
- Tapping → Level 2 screen for that subcategory (product grid, left strip pre-selected to this subcategory)

### Category Label

- Bold section heading — **not tappable**, purely a label
- Visually separates sections as user scrolls
- Driven from `categories` table — no hardcoded labels in Flutter

---

## 3. Level 2 — Subcategory + Product Grid

**This is the most important screen in the catalog.**

Layout: vertical subcategory strip on the **left (5% width)** + product grid on the **right (95% width)**.

Per Plan_Architect.md: *"5% width should be of vertical scrolling of the subcategory in that category chosen"*

```
┌─────────────────────────────────────────────────────┐
│  ←              Ingredients           [⚙ Filter]    │  ← ← goes back to Level 1
├──────┬──────────────────────────────────────────────┤
│      │                                               │
│  C   │  ─── Creams ─────────────────────── 24 ────  │  ← subcategory label + count
│  r ◀ │                                               │
│  e   │  ┌────────────┐  ┌────────────┐             │
│  a   │  │ [product]  │  │ [product]  │             │
│  m   │  └────────────┘  └────────────┘             │
│  s   │  ┌────────────┐  ┌────────────┐             │
│  ─   │  │ [product]  │  │ [product]  │             │
│  C   │  └────────────┘  └────────────┘             │
│  o   │                                               │
│  c   │  ─── Cocoa & Chocolates ──────── 18 ────    │
│  o   │                                               │
│  a   │  ┌────────────┐  ┌────────────┐             │
│  ─   │  │ [product]  │  │ [product]  │             │
│  F   │  └────────────┘  └────────────┘             │
│  r   │                                               │
│  u   │  (continues scrolling down...)               │
│  i   │                                               │
│  t   │                                               │
│  s   │                                               │
│  ─   │                                               │
│  ...  │                                               │
│      │                                               │
├──────┴──────────────────────────────────────────────┤
│  [Home] [Catalog★] [Order Again] [🍪] [Cart 🔴]     │
└─────────────────────────────────────────────────────┘
```

### Left Strip — Vertical Subcategory Navigator (5% width)

- Rotated text labels, one per subcategory, stacked vertically
- Active subcategory highlighted with brand colour accent bar
- **Scrolls independently** from the product grid
- Tapping a subcategory label → product grid scrolls to that subcategory section AND highlights label

```
│  C  │  ← Creams (active — highlighted)
│  r  │
│  e  │
│  a  │
│  m  │
│  s  │
│  ─  │  ← divider between subcategories
│  C  │  ← Cocoa & Chocolates
│  o  │
│  c  │
│  ...│
```

### Right Side — Product Grid (95% width)

- Full scrollable list of ALL subcategories for the selected category
- Each subcategory has:
  - Section header: subcategory name + product count
  - 2-column product tile grid below it
- Products from all subcategories shown continuously — user scrolls through everything
- When user scrolls, the left strip auto-highlights the current subcategory in view

### Sync between strip and grid

```
User scrolls product grid
  → detect which subcategory section is in viewport (using ScrollController)
  → update activeSubcategoryProvider
  → left strip highlights correct label
  → left strip auto-scrolls if needed

User taps subcategory label on left strip
  → product grid scrolls to that subcategory's section header (using scrollController.animateTo)
  → activeSubcategoryProvider updated
```

### Filter / Sort Button (top right)

`[⚙ Filter]` — opens filter bottom sheet. See Section 7.

---

## 4. Level 3 — Product Detail Page

Full screen. Opened by tapping any product tile. Has a back button to return to Level 2.

```
┌─────────────────────────────────────────────────────┐
│  ←              Fresh Cream 25%                     │  ← ← goes back to Level 2
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌───────────────────────────────────────────────┐  │
│  │                                               │  │
│  │            [Primary Product Image]            │  │  ← large image, aspect 1:1
│  │                                               │  │
│  └───────────────────────────────────────────────┘  │
│  ○ ● ○ ○  ← image gallery dots (swipeable)          │
│                                                       │
│  Fresh Cream 25%                  ❤  (wishlist)      │  ← name + wishlist heart
│  Ingredients · Creams                                 │  ← breadcrumb
│                                                       │
│  ~~₹120~~  ₹95   🏷️ 21% off                          │  ← pricing
│                                                       │
│  Select Variant                                       │
│  ┌────────┐  ┌────────┐  ┌────────┐                 │
│  │ 200ml  │  │ 500ml● │  │  1 L   │                 │  ← variant selector chips
│  └────────┘  └────────┘  └────────┘                 │
│  (● = selected)                                       │
│                                                       │
│  ─── Description ──────────────────────────────     │
│  High-quality fresh cream ideal for whipping,        │
│  ganache, and mousse. No added preservatives.        │
│                                                       │
│  ─── Product Details ──────────────────────────     │
│  Brand:       Baker's Choice                         │
│  Weight:      500ml                                  │
│  Storage:     Refrigerate below 4°C                  │
│  Shelf life:  7 days from opening                    │
│                                                       │
│  ─── You Might Also Like ──────────────────────     │
│  [ tile ][ tile ][ tile ]  ← horizontal scroll       │
│                                                       │
│  ─── Reviews & Ratings ─────────────────────────     │
│  4.6 ★★★★★           410 reviews    (See all →)      │
│  [ring][ring][ring][ring]  Quality/Value/Pkg/Accuracy│
│  [ review card ][ review card ]  ← horizontal scroll │
│  [ Add Review ]  ← only if verified-purchase eligible│
│                                                       │
│  (scroll padding for fixed CTA)                       │
└─────────────────────────────────────────────────────┘
│  ┌───────────────────────────────────────────────┐  │
│  │   + Add to Cart    ·    ₹95                   │  │  ← fixed CTA (above bottom nav)
│  └───────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────┤
│  [Home] [Catalog★] [Order Again] [🍪] [Cart 🔴]     │  ← bottom nav always visible
└─────────────────────────────────────────────────────┘
```

### Image Gallery

- Swipeable horizontally — `PageView` in Flutter
- Dots indicator below image showing position
- All images from `product_images` table for this product
- `cached_network_image` with shimmer placeholder while loading

### Variant Selector

- Horizontal row of chips — one per variant (e.g. 200ml, 500ml, 1L)
- Selected variant highlighted with brand colour
- Price, stock status, and "Add to Cart" all update when variant changes
- Out-of-stock variant: chip shown but greyed out with strikethrough, not selectable

### Fixed Bottom CTA

```
Idle:          [  + Add to Cart  ·  ₹95  ]
In cart:       [  − 1 +  ·  ₹95  ]          ← stepper replaces button
Out of stock:  [  Notify Me  ]               ← see 00_common_architecture.md §12a
```

Same button → stepper transition as catalog tile (AnimatedSwitcher). The out-of-stock state is currently built as a plain disabled "Out of Stock" button (Milestone 2) — swapping it for a functional "Notify Me" button is designed but not yet built, blocked on choosing an email provider (§17 open decision C in `00_common_architecture.md`).

### Wishlist Heart (top right of product name)

- Outlined heart = not in wishlist
- Filled red heart = in wishlist
- Tap toggles — immediate optimistic update, API call in background
- Requires login — if not logged in, shows login bottom sheet

### You Might Also Like (bottom of page)

- Products from same subcategory, excluding current product
- Same horizontal scroll tile row as checkout recommendations
- API: `GET /v1/products/:id/related`

### Reviews & Ratings (below You Might Also Like)

**Not built yet — designed, scheduled to Phase 5.** Full architecture (DB table, eligibility rules, category definitions, API, Add Review form, Riverpod state) lives in `00_common_architecture.md` §5a — this page only owns the layout slot. Product-level only, verified-purchase gated (must have a `delivered` order for this product), one review per user per product.

---

## 5. Product Tile — Full Spec

Used on Level 2 grid, Home tab rows, Order Again grid, Wishlist. One consistent design everywhere.

```
┌──────────────────────────┐
│  [Trending]  [Low Stock] │  ← badge row — only shown if applicable
│                          │
│      [Product Image]     │  ← cached_network_image, 1:1 ratio
│                          │
│  Fresh Cream 25%         │  ← product name, 2 lines max, ellipsis
│  500ml                   │  ← default variant name, muted
│                          │
│  ~~₹120~~  ₹95           │  ← strike price only if original ≠ current
│                          │
│  ┌──────────────────┐    │
│  │  + Add to Cart   │    │  ← transforms to stepper on tap
│  └──────────────────┘    │
└──────────────────────────┘
```

### Badge Rules

| Badge | Colour | Condition |
|---|---|---|
| Trending | Amber | `products.is_trending = true` |
| Low Stock | Orange | `stock_qty > 0 AND stock_qty ≤ 5` |
| Out of Stock | Red | `stock_qty = 0` — replaces Add button |
| Sale | Green | `original_price ≠ current_price` |
| New | Blue | `created_at` within last 30 days |

Maximum 2 badges shown simultaneously — priority order: Out of Stock > Low Stock > Sale > Trending > New.

### Price display rules

```
original_price = current_price  → show only current_price (no strikethrough)
original_price > current_price  → show ~~original~~ current_price + % off badge
```

### Tile dimensions

- 2-column grid → each tile = (screen width - padding) / 2
- Image: square, fills full tile width
- Text + button below image: fixed height area
- Consistent height across all tiles regardless of text length (fixed 2-line name clamp)

---

## 6. Wishlist Heart

Appears on **product detail page** (top right of product name). Does NOT appear on catalog grid tiles to keep tiles clean.

```dart
// Optimistic update — UI changes instantly, API syncs in background
void toggleWishlist(String variantId) {
  // Immediately update UI
  wishlistNotifier.toggle(variantId);
  // Background API call
  dio.post/delete('/v1/wishlist/$variantId');
}
```

---

## 7. Filters & Sorting

Opens as a bottom sheet from `[⚙ Filter]` on Level 2.

```
┌──────────────────────────────────────────────────┐
│           ─────  (drag handle)                   │
│  Filter & Sort                  [Reset]   [✕]    │
│  ──────────────────────────────────────────────  │
│                                                  │
│  Sort by                                         │
│  ○ Relevance (default)                           │
│  ○ Price: Low to High                            │
│  ○ Price: High to Low                            │
│  ○ Newest First                                  │
│                                                  │
│  ──────────────────────────────────────────────  │
│  Availability                                    │
│  ☑ In Stock                                      │
│  ☐ Include Out of Stock                          │
│                                                  │
│  ──────────────────────────────────────────────  │
│  Price Range                                     │
│  ₹0 ──────────●────────────── ₹5,000            │
│       ₹50                ₹2,000  (selected)      │
│                                                  │
│  ──────────────────────────────────────────────  │
│  [ Apply Filters ]                               │
└──────────────────────────────────────────────────┘
```

Filter state is **ephemeral** — not persisted between sessions. Cleared on leaving the catalog screen.

Active filters shown as chips below the category name:

```
← Back    Ingredients    [Price ✕] [In Stock ✕]    [⚙ Filter]
```

---

## 8. Empty & Edge States

### Subcategory has no active products

```
─── Food Colours ──────────────── 0 ────
  Coming soon — check back later!
```
Subcategory section still shown but with placeholder message. Admin can add products without app update.

### Search returns no results (on catalog search)

```
No results for "fondant sugar"
Try a different spelling or browse categories
[ Browse All → ]
```

### All products in subcategory out of stock

Products still shown with "Out of Stock" badge — not hidden. Bakers may want to check back.

---

## 9. Data & API

| Action | Endpoint | Notes |
|---|---|---|
| Load all categories | `GET /v1/categories` | Includes subcategory count. Cached in Drift. |
| Load category + subcategories | `GET /v1/categories/:id` | Returns category + all its subcategories |
| Load products for category | `GET /v1/products?categoryId=:id&page=1&limit=40` | All subcategories, grouped server-side |
| Load products for subcategory | `GET /v1/products?subCategoryId=:id` | Filtered to one subcategory |
| Load product detail | `GET /v1/products/:id` | Includes variants, images, description |
| Related products | `GET /v1/products/:id/related` | Same subcategory, excludes current |
| Toggle wishlist | `POST /v1/wishlist { variantId }` | Add |
| Toggle wishlist | `DELETE /v1/wishlist/:variantId` | Remove |
| Search | `GET /v1/products?q=:term` | Full-text search across name + description |
| Load reviews + rating summary | `GET /v1/products/:id/reviews?page=&limit=` | Not built yet — Phase 5, see `00_common_architecture.md` §5a |
| Check review eligibility | `GET /v1/products/:id/reviews/eligibility` | Not built yet — Phase 5 |
| Submit a review | `POST /v1/products/:id/reviews` | Not built yet — Phase 5, verified-purchase gated |

### Caching Strategy

```
Categories list     → Drift cache, refreshed by Workmanager hourly
Products per cat    → Drift cache, refreshed by Workmanager hourly
Product detail      → in-memory only (Riverpod), not Drift-cached
Wishlist state      → Drift-cached (needed offline to show heart state)
```

---

## 10. Riverpod State

```dart
// All categories — loaded once, cached
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(catalogRepositoryProvider).getCategories();
});

// Products for a specific category — lazy loaded on nav
final categoryProductsProvider = FutureProvider.family<CategoryProducts, String>(
  (ref, categoryId) async {
    return ref.read(catalogRepositoryProvider).getProductsByCategory(categoryId);
  }
);

// Active subcategory selection (drives left strip highlight + grid scroll)
final activeSubcategoryProvider = StateProvider.family<String?, String>(
  (ref, categoryId) => null  // null = show all, string = specific sub id
);

// Product detail
final productDetailProvider = FutureProvider.family<ProductDetail, String>(
  (ref, productId) async {
    return ref.read(catalogRepositoryProvider).getProduct(productId);
  }
);

// Filter state — per category screen, ephemeral
final catalogFilterProvider = StateProvider.family<CatalogFilter, String>(
  (ref, categoryId) => CatalogFilter.defaults()
);

// Wishlist set — for fast O(1) lookup on heart state
final wishlistIdsProvider = StateNotifierProvider<WishlistNotifier, Set<String>>((ref) {
  return WishlistNotifier(ref.read(wishlistRepositoryProvider));
});

// Reviews & ratings — not built yet (Phase 5), full definition in
// 00_common_architecture.md §5a:
//   productReviewsProvider     FutureProvider.family<ReviewSummary, String>
//   reviewEligibilityProvider  FutureProvider.family<ReviewEligibility, String>
```

---

## 11. Flutter Packages Used

| Package | Purpose |
|---|---|
| `flutter_riverpod` | All state — categories, products, active subcategory, filters, wishlist |
| `dio` | All catalog API calls |
| `drift` | Cache categories + products locally for offline browsing |
| `cached_network_image` | All product + category images |
| `go_router` | Navigation between catalog levels + product detail |

---

## Key Rules

- **No hardcoded categories in Flutter** — all driven from DB. Admin can add/remove categories without app update.
- **Left strip + product grid are always in sync** — tapping strip scrolls grid, scrolling grid updates strip highlight.
- **Out-of-stock products are shown** — not hidden. Bakers need to see what exists even if temporarily unavailable.
- **Filter state is ephemeral** — cleared on leaving the screen. No persisted filters between sessions.
- **Variant selection on detail page** — price, stock, and Add to Cart all reflect the *selected* variant, not the product's default.
- **Wishlist is optimistic** — heart toggles instantly, API call fires in background. On failure, heart reverts.
- **Category images are mandatory** — admin must upload before making a category active. No broken image placeholders in the category grid.
