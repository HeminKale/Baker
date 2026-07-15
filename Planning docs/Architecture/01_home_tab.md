# Baker Ally — Home Tab Architecture
> First tab in bottom navigation. Currently a placeholder screen.
> Scheduled as **Milestone 5.5** — an addendum after Milestone 5 (Account & Discovery),
> before Milestone 6 (Admin Panel). Chosen as 5.5 rather than folding into Milestone 6
> because it's a pure customer-facing screen with zero admin-panel dependencies, and
> every backend/frontend primitive it needs (ProductTile, search, cart, address sheet)
> already exists from Milestones 2, 3 and 5 — there's nothing to build first.
> Last updated: July 2026

---

## Table of Contents

1. [What This Tab Is For](#1-what-this-tab-is-for)
2. [Full Page Layout](#2-full-page-layout)
3. [Top Bar — What's Reused vs. Excluded](#3-top-bar--whats-reused-vs-excluded)
4. [Search Bar](#4-search-bar)
5. [Voice Search — Deferred](#5-voice-search--deferred)
6. [The Three Sections](#6-the-three-sections)
7. [Section Tile Design](#7-section-tile-design)
8. ["See All" Screens](#8-see-all-screens)
9. [Backend — GET /v1/home](#9-backend--get-v1home)
10. [Backend — New Offers Query Nuance](#10-backend--new-offers-query-nuance)
11. [Drift Caching](#11-drift-caching)
12. [Riverpod State](#12-riverpod-state)
13. [New Files](#13-new-files)
14. [Empty States](#14-empty-states)
15. [Out of Scope for 5.5](#15-out-of-scope-for-55)

---

## 1. What This Tab Is For

Home is the default landing tab — the first thing a customer sees on open. Its job is
discovery: surface what's new, what's discounted, and what's popular, without requiring
the customer to already know what they're looking for (that's what Catalog and its
search are for).

Reference mockup (provided by stakeholder):

- Top bar: default address selector, notification bell, avatar
- Full-width search bar (always visible, not an icon)
- Three horizontal-scroll product sections: **Newly Launched**, **New Offers**,
  **Trending Now** — each with a "See all →" link
- Standard product tile per card: image, name, variant size, strike-through original
  price + current price, "+ Add to Cart" button

This matches `00_common_architecture.md` §19 (Home Tab Architecture, written during
initial planning) almost exactly — that section is the source of truth this doc expands
on with the concrete implementation plan.

---

## 2. Full Page Layout

```
┌─────────────────────────────────────────────────────┐
│  [📍 Home ▾]                          [🔔]  [P]     │  ← top bar
│  ┌─────────────────────────────────────────────┐    │
│  │ 🔍  Search ingredients, packaging...          │    │  ← always-visible search bar
│  └─────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────┤
│  Newly Launched                          See all →   │
│  ← [ tile ] [ tile ] [ tile ] →                       │  ← horizontal scroll
│                                                       │
│  New Offers                              See all →   │
│  ← [ tile ] [ tile ] [ tile ] →                       │
│                                                       │
│  Trending Now                            See all →   │
│  ← [ tile ] [ tile ] [ tile ] →                       │
│                                                       │
│  (scrolls vertically — sections stack below)          │
└─────────────────────────────────────────────────────┘
│  [Home★] [Catalog] [Order Again] [🍪] [Cart 🔴]      │
└─────────────────────────────────────────────────────┘
```

---

## 3. Top Bar — What's Reused vs. Excluded

The top bar (`shared/widgets/app_shell.dart`) already renders globally on every tab —
Home doesn't get its own top bar, it just uses the shell's.

| Element | Status | Notes |
|---|---|---|
| Default address label | ✅ Already built (Milestone 5) | `_DefaultAddressLabel` in `app_shell.dart`. Tapping it currently does nothing — **5.5 adds** a tap handler that opens the existing `AddressSelectorSheet.show(context)` (built for checkout in Milestone 3), reused as-is. |
| Avatar → Profile Overlay | ✅ Already built (Milestone 5) | No change needed. |
| Notification bell | ❌ **Excluded from 5.5** | The mockup shows a bell, but there is no `notifications` table in the schema and no Dio-polling infra — that's its own build (`00_common_architecture.md` §12: `GET /v1/notifications/unread-count` polled every 30s). Building the bell now means building that whole feature un-scoped. Top bar stays avatar + address only until that's a planned milestone. |

This mirrors the same reasoning already applied to the order-confirmation screen's
WhatsApp banner in Milestone 5 — the mockup reflects an earlier full-vision design;
some elements in it are intentionally sequenced into later work, not omissions.

---

## 4. Search Bar

Catalog already has working search: `searchProvider` (debounced 400ms, `StateNotifierProvider.autoDispose`)
backed by `CatalogRepository.search(query)` → `GET /v1/products?q=`, rendered as a
`ProductTile` grid (`catalog_screen.dart`'s `_CatalogSearchResults`).

Home's search bar is the **same provider and the same results grid**, just presented
differently per `00_common_architecture.md` §2's "Search behaviour" table:

| Screen | Search display |
|---|---|
| Home | Full search bar visible by default, no toggle |
| All other screens | Icon that expands into the same bar |

Implementation: Home's search bar is a permanently-expanded `TextField` (no
`_searchExpanded` toggle state like Catalog has — it's just always in the "expanded"
visual state). Typing drives `searchProvider` exactly like Catalog does; when the query
is non-empty, the three home sections are replaced by the same `_CatalogSearchResults`-style
grid (reuse the widget, don't fork it).

---

## 5. Voice Search — Deferred

The mockup and `00_common_architecture.md` §19/§21 both spec a mic button
(`speech_to_text` package, on-device). **Not included in 5.5.**

Reason: `Phase_Plan_Technical.md`'s Milestone 1 Update (2026-07-09) removed
`speech_to_text` from the dependency tree due to a Kotlin 2.0 build incompatibility,
and explicitly deferred it "to Phase 5" for re-evaluation. This is that
re-evaluation point, and the call here is to **defer again**: re-litigating a native
Android build/plugin-compatibility issue mid-milestone is a different kind of risk than
the rest of 5.5 (which is pure Dart/UI reuse), and nothing else in 5.5 depends on it —
the search bar works text-only with no gap in functionality, just no mic icon.

Revisit when either `speech_to_text` publishes a Kotlin-2.0-compatible release, or a
native-platform-API alternative is evaluated (both options are already logged in
`Phase_Plan_Technical.md`).

---

## 6. The Three Sections

| Section | Definition | Sort |
|---|---|---|
| **Newly Launched** | Active products, most recent first | `createdAt DESC` |
| **New Offers** | Active products with at least one active variant where `currentPrice < originalPrice` | Discount % `DESC` (biggest deal first) |
| **Trending Now** | Active products with `isTrending = true` | `createdAt DESC` |

All three reuse the existing `products` / `productVariants` / `productImages` tables —
**zero new Postgres migrations**. `isTrending` already exists and already drives
Catalog's search ranking and product-detail badges; this just surfaces it on Home too.

Each section returns up to 10 products for the Home preview (matching Order Again's
"top 10" convention from Milestone 5), with a full paginated version behind "See all".

---

## 7. Section Tile Design

**No new tile widget.** `ProductTile` (`features/catalog/presentation/widgets/product_tile.dart`)
already says in its own doc comment: *"used by Level 2's grid (and, later, Home / Order
Again / Wishlist)"* — it was built anticipating this. Home wraps it exactly like
checkout's "You Might Also Like" section already does:

```dart
SizedBox(
  height: 300,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: products.length,
    separatorBuilder: (_, __) => const SizedBox(width: 8),
    itemBuilder: (_, i) => SizedBox(width: 160, child: ProductTile(product: products[i])),
  ),
)
```

This gets badges (Trending / Sale / New / Low Stock / Out of Stock), the Add to
Cart → stepper transition, wishlist heart, and tap-to-detail navigation for free —
all already correct and tested from Milestones 2 and 3.

---

## 8. "See All" Screens

Each section's "See all →" needs a full paginated list, not just the top 10. Rather
than build three bespoke screens, one generic screen parameterized by section:

```
GoRoute('/home/section/:section')
  → HomeSectionScreen(section: 'newly-launched' | 'new-offers' | 'trending')
```

Renders a title (from the section key) + a vertical `ProductTile` grid (2-column, same
`childAspectRatio` as Catalog's Level 2 grid) with page-based "Load More", following the
same pattern already used for Order Again's Previously Bought pagination in Milestone 5
(local widget-level page state, not a new provider-layer pagination primitive).

---

## 9. Backend — GET /v1/home

New file: `routes/home.ts`. Public route (no `authMiddleware`), same as `catalog.ts`.

```
GET /v1/home
  → { data: { newlyLaunched: Product[], newOffers: Product[], trending: Product[] } }
  (each array: top 10, same shape as GET /v1/products — id, subCategoryId, name,
   isTrending, createdAt, displayVariant, displayImageUrl)

GET /v1/home/newly-launched?page&limit   → paginated, for "See all"
GET /v1/home/new-offers?page&limit       → paginated, for "See all"
GET /v1/home/trending?page&limit         → paginated, for "See all"
```

All four reuse `attachDisplayInfo()` from `routes/catalog.ts` (already exported) for
Newly Launched and Trending — same batch-join, N+1-safe pattern already established.
New Offers needs a variant, see §10.

```ts
// Newly Launched
db.select().from(products)
  .where(eq(products.isActive, true))
  .orderBy(desc(products.createdAt))
  .limit(10)

// Trending
db.select().from(products)
  .where(and(eq(products.isActive, true), eq(products.isTrending, true)))
  .orderBy(desc(products.createdAt))
  .limit(10)
```

---

## 10. Backend — New Offers Query Nuance

**This is the one non-obvious part of 5.5.** `attachDisplayInfo()` always picks each
product's *lowest-sortOrder active variant* as the display variant — that's correct for
Catalog and Trending, where any variant of the product is representative. It is **not**
correct for New Offers.

A product can have variant A (sortOrder 0, full price) and variant B (sortOrder 1,
discounted). The product qualifies for New Offers because variant B exists, but
`attachDisplayInfo` would still attach variant A as the display — the tile would show
in the "New Offers" section with a full, non-discounted price. That's a real bug if
built naively, not a style nit.

Fix: New Offers is queried variant-first, not product-first — select directly from
`productVariants` where `currentPrice < originalPrice AND isActive`, join to `products`,
and attach *that specific variant* as the display variant (skip `attachDisplayInfo`'s
generic picker entirely for this one section):

```ts
const discounted = await db
  .select({ product: products, variant: productVariants })
  .from(productVariants)
  .innerJoin(products, eq(productVariants.productId, products.id))
  .where(and(
    eq(products.isActive, true),
    eq(productVariants.isActive, true),
    sql`${productVariants.currentPrice} < ${productVariants.originalPrice}`,
  ))
  .orderBy(sql`(${productVariants.originalPrice} - ${productVariants.currentPrice})::float / ${productVariants.originalPrice} DESC`)
  .limit(10);
```

Then attach each row's own `productImages` lookup (primary image, same fallback rule as
`attachDisplayInfo`) directly, bypassing the variant-picker half of that helper.

---

## 11. Drift Caching

Home follows the same network-first + Drift fallback pattern as Catalog and Orders
(`00_common_architecture.md` §15), **but needs its own table** — reusing `CachedProducts`
was considered and rejected: that table's primary key is `{id}` (one row per real
product), and its `categoryId` column holds the product's actual category for the
existing category-scoped fallback query. Tagging rows with a synthetic
`categoryId: 'home:trending'` to scope them for Home would silently overwrite that real
category value the next time the same product is cached from a genuine Catalog browse
(or vice versa) — a correctness bug in the *existing* Catalog offline fallback, not just
a Home concern.

New table instead, keyed by `(section, productId)`:

```dart
class CachedHomeSections extends Table {
  TextColumn get section => text()();      // 'newlyLaunched' | 'newOffers' | 'trending'
  TextColumn get productId => text()();
  TextColumn get subCategoryId => text()();
  TextColumn get name => text()();
  BoolColumn get isTrending => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer()();  // preserves section ordering on fallback read
  TextColumn get variantId => text().nullable()();
  TextColumn get variantName => text().nullable()();
  IntColumn get originalPrice => integer().nullable()();
  IntColumn get currentPrice => integer().nullable()();
  IntColumn get stockQty => integer().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {section, productId};
}
```

Drift schema bump v4 → v5, additive `onUpgrade` block — same mechanics as the
`CachedOrders` table added in Milestone 5.

---

## 12. Riverpod State

```dart
final homeRepositoryProvider = Provider<HomeRepository>((ref) => ...);

final homeSectionsProvider = FutureProvider.autoDispose<HomeSections>((ref) {
  return ref.watch(homeRepositoryProvider).getHomeSections();
});

final homeSectionPageProvider =
    FutureProvider.autoDispose.family<List<Product>, ({String section, int page})>((ref, args) {
  return ref.watch(homeRepositoryProvider).getSection(args.section, page: args.page);
});
```

Same shape as `orderDetailProvider`/`ordersProvider` from Milestone 5 — nothing new
architecturally.

---

## 13. New Files

**Backend:**
- `routes/home.ts` (new)
- `index.ts` — register `homeRoute`

**Flutter:**
- `features/home/data/models/home_sections.dart`
- `features/home/data/home_repository.dart`
- `features/home/presentation/providers/home_providers.dart`
- `features/home/presentation/screens/home_screen.dart` — replaces `PlaceholderScreen(title: 'Home')` in `app_router.dart`
- `features/home/presentation/screens/home_section_screen.dart` — "See all" destination
- `shared/local_db/app_database.dart` — add `CachedHomeSections` table, bump to v5

No changes needed to `ProductTile`, `cartProvider`, `searchProvider`, `AddressSelectorSheet`,
or `CatalogRepository` — all reused verbatim.

---

## 14. Empty States

| Condition | Behaviour |
|---|---|
| A section has 0 qualifying products | That section is hidden entirely (not shown with an empty message) — matches Order Again's "hide, don't apologize" convention for sparse sections |
| All three sections empty (fresh catalog, nothing seeded yet) | Home shows just the search bar + a "Browse the catalog" prompt linking to `/catalog` |
| Network failure, no Drift cache yet | Standard error state with retry, matching Catalog's pattern |

---

## 15. Out of Scope for 5.5

Explicitly **not** built in this milestone, to keep it a clean, self-contained addendum:

- Notification bell (§3) — needs its own `notifications` table + polling infra
- Voice search mic button (§5) — Kotlin 2.0 plugin incompatibility, deferred again
- Workmanager background refresh — also Kotlin-2.0-deferred per `Phase_Plan_Technical.md`;
  Home's Drift fallback is read-through only (refreshes on next successful network call),
  not proactively synced in the background
- Personalized/ML-ranked sections — "Newly Launched" / "New Offers" / "Trending" are
  simple deterministic queries, not a recommendation engine
