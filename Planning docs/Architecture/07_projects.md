# Baker Ally — Projects Architecture

> ✅ Built in Milestone 7 (2026-09-22). See `Milestone readme/Milestone 7.md` for what
> shipped and `Milestone readme/Milestone 7 manual steps.md` for the migration/deploy
> steps still pending (blocked on Supabase CLI account permissions — not yet applied
> live). This doc stays as the design reference; treat it as historical intent where
> it differs from the actual code (e.g. the two extra endpoints in §8 added during
> build: `item-membership` and the variant-keyed item delete).

---

## 1. Concept

A **Project** is a named, per-user shopping list scoped to one real-world job the chef
is fulfilling — e.g. "Hero's Birthday", "Superhero's Engagement". Unlike the Cart
(one active checkout) or the Wishlist (one flat, binary want-list), a chef can hold
**many Projects at once**, each accumulating the equipment/ingredients needed for
that specific order, with **quantities** (not just an in/out flag like Wishlist).

Architecturally this is the same shape as Wishlist — a per-user join table onto
`product_variants`, added to from a product-level icon, synced server-side so it's
consistent across devices — with two differences that drive the schema:

1. **Grouping.** Wishlist is one flat list per user; Projects is many named lists per
   user. That's the `projects` parent table Wishlist doesn't need.
2. **Quantity.** Wishlist doesn't track how many — you either want it or you don't.
   A Project needs "I need 5 of these piping bags," so `project_items` carries a
   `quantity`, matching `cart_items`'s shape more than `wishlists`'s.

Entry points, both new:
- **A "Projects" icon beside the top-bar avatar** (`app_shell.dart`'s `_TopBar`) —
  opens the full Projects list (browse/manage all projects).
- **A "Add to Project" icon on every product** (tile + detail, same two placements
  `WishlistHeart` already uses) — opens a quick-add dialog scoped to *this* product.

---

## 2. Entry Point — Top Bar Icon

`_TopBar` in `app_shell.dart` currently renders `[address label] [avatar]`. Add the
Projects icon between them: `[address label] [projects icon] [avatar]`.

```
┌─────────────────────────────────────────────────┐
│  📍 Home – Mumbai 400001        🗂️   [ 👤 ]      │
└─────────────────────────────────────────────────┘
```

Same login-gating as the avatar/heart: tapping while logged out shows
`showLoginRequiredSheet` (existing shared widget), same as `WishlistHeart`.

Badge (optional, cheap to add since the count is already in the flattened provider
described in §6): a small count badge showing number of **active** projects, same
visual treatment as `_CartIcon`'s red count badge.

---

## 3. Entry Point — "Add to Project" Icon on Products

Placed exactly where `WishlistHeart` is today: top-right corner of the tile image
(`product_tile.dart`) and top-right corner of the image gallery (`product_detail_screen.dart`,
post-M6.5 heart relocation). Stack the two icons vertically in that corner (heart above,
project-add below) rather than crowding them side by side on a small tile.

Unlike the heart, this icon isn't a binary toggle — a product can belong to zero, one,
or several projects — but it still gives instant visual feedback: **filled/highlighted
if the variant belongs to at least one project**, outline if it belongs to none. Backed
by the same kind of flattened-set provider Wishlist uses for its O(1) heart lookup
(§6 — `projectItemVariantIdsProvider`).

Tapping it opens the **Add to Project** dialog, scoped to that one variant.

---

## 4. "Add to Project" Dialog

Modal bottom sheet (same pattern as `AddressSelectorSheet`), ordered top → bottom
exactly as requested: search bar first, existing projects list in the middle,
"+ New Project" pinned last.

```
┌─────────────────────────────────────────────────┐
│              ─────  (drag handle)                │
│  Add "Chocolate Ganache Drip – 500g" to a project │
│                                                  │
│  🔍  Search your projects...                     │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │ ☑  Hero's Birthday            12 items   │   │  ← already contains this item
│  │ ☐  Superhero's Engagement      4 items   │   │
│  │ ☐  Diwali Hampers Batch 2      0 items   │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  ➕  New Project...                       │   │  ← always last
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

- Tapping a row **toggles** that variant's membership in that project (checked → add,
  unchecked → remove) — lets a chef add the same equipment to multiple live projects
  in one visit, which is the actual real-world case (a piping tip needed for two events
  this week).
- Search filters the project list client-side by name (list is small — a chef's own
  projects, not a global search).
- "+ New Project" expands an inline text field (name only) → on submit, creates the
  project **and** adds the current variant to it in one action, then keeps the sheet
  open showing the new project now checked (so the chef can keep multi-selecting).
- Completed projects are excluded from this list — you don't add new equipment to a
  job that's already done. (Open question in §10 if that's ever wrong.)

---

## 5. Projects List Screen — `/projects`

Reached from the top-bar icon.

```
┌─────────────────────────────────────────────────┐
│ ← Back            Your Projects        [+ New]  │
│                                                  │
│  🔍  Search projects...                          │
│                                                  │
│  [ Active ]  [ Completed ]                       │
│  ─────────────────────────────────────────────  │
│  ┌──────────────────────────────────────────┐   │
│  │ [img] Hero's Birthday               🗑️   │   │
│  │       12 items · ₹8,450 est. · 📅 12 Oct │   │
│  ├──────────────────────────────────────────┤   │
│  │ [img] Superhero's Engagement         🗑️  │   │
│  │       4 items · ₹2,120 estimated         │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  (empty state: "No projects yet — tap + New to   │
│   start one, or add a product from the catalog") │
└─────────────────────────────────────────────────┘
```

- **Tabs**: Active / Completed, per requirement #6. Filters the same list by
  `projects.status`.
- **Search bar**: filters by project name within the selected tab.
- **[+ New]**: same inline-name creation as the dialog's "New Project", but with
  nothing to attach yet — creates an empty Active project and opens its detail screen.
- Card thumbnail = first item's product image (best-effort, `null` if project is empty).
- Tapping a card opens Project Detail.

---

## 6. Project Detail Screen — `/projects/:id`

```
┌─────────────────────────────────────────────────┐
│ ← Back      Hero's Birthday        🗑️   ✓ Mark   │
│             📅 12 Oct · Priya · 98765 43210 [Edit]│
│                                       Complete    │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │ [img] Piping Bags – Pack of 50            │   │
│  │       ₹̶3̶5̶0̶  ₹299        [–] 2 [+]   🗑️    │   │
│  ├──────────────────────────────────────────┤   │
│  │ [img] Fondant – White 1kg                 │   │
│  │       ₹450                [–] 1 [+]   🗑️  │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  (empty state: "No items yet — add products      │
│   from the catalog using the project icon")      │
│                                                  │
│  ──────────────────────────────────────────────  │
│  Original total          ₹̶1̶,̶2̶0̶0̶                 │   ← only shown if > estimated
│  Estimated total          ₹1,049                 │
│  ┌──────────────────────────────────────────┐   │
│  │       Add All to Cart                    │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

- Each row: image, product+variant name, per-unit price (struck-through original +
  current, same `_PriceRow` treatment as `product_tile.dart` §the existing app-wide
  convention — not a new pattern), quantity stepper (same `[-] N [+]` control already
  used in `product_tile.dart`'s `_AddToCartControl` and `cart_item_row.dart`), and a
  per-row 🗑️ remove action (item-level, distinct from the AppBar 🗑️ which deletes the
  whole project — §6a).
- **Totals (requirement #5)**: reuses the same `originalPrice` vs `currentPrice`
  fields every variant already carries — no new discount mechanism needed for this
  part (confirmed — see §10, decision 3: quantity discounts are explicitly **not**
  folded in for v1).
  - `estimatedTotal = Σ(currentPrice × quantity)` across all items — always shown, bold.
  - `originalTotal = Σ(originalPrice × quantity)` — shown struck-through **only when
    it's greater than `estimatedTotal`** (i.e. only when at least one item is
    currently on sale), directly above the estimated total. Matches the same
    show-strikethrough-only-when-relevant rule `_PriceRow` already follows per-item.
- **Mark Complete / Reopen** (requirement #6, confirmed): AppBar action, moves
  `status` between `active` and `completed`. Once completed, quantity steppers/
  remove/add-more are disabled (read-only record of what the job needed) — the same
  AppBar slot swaps to a **Reopen** action, since a chef re-doing a repeat client job
  (a second "Hero's Birthday" cake next year) can revive rather than rebuild the list
  from scratch (confirmed — §10 decision 1).
- **Delete project** (confirmed — §10 decision 2): a plain 🗑️ icon in the AppBar,
  both here and on each row of the Projects List (§5) — a direct tap, not a swipe
  gesture. Always behind a confirmation dialog first ("Delete 'Hero's Birthday'? This
  removes all N items in it. This can't be undone."), same destructive-action pattern
  as Log Out in `06_profile_and_account.md`.
- **Event date / client details** (confirmed — §10 decision 6): shown as a subtitle
  line under the project name, `[Edit]` opens the same field set as project creation
  (§6b). All fields on this line are optional — the line itself is omitted entirely
  if none are set.
- **Add All to Cart** (confirmed — §10 decision 4, was previously out of scope):
  fixed footer button below the totals block, available regardless of status (a
  Completed project can still be re-ordered from, same rationale as allowing Reopen).
  Sends **every** item in the project, at its current project quantity, to the real
  cart in one action, then navigates to `/cart` (the Checkout screen) — literally
  "send this whole list to checkout," not a partial-select flow. See §6a for how.

---

## 6a. Add All to Cart — Reuses the Existing Batch-Add, No New Endpoint

Order Again's "Frequently Bought Together" flow already solved this exact
problem — `group_detail_sheet.dart`'s `_addSelected()` maps a list of
`{variantId, quantity}` pairs to `cartProvider.notifier.addBatch(items)`,
which calls the already-built `POST /v1/cart/items/batch`. Project Detail's
"Add All to Cart" does the same thing with one difference: no selection step
(the group sheet lets you uncheck individual items first; Projects sends the
whole list unconditionally, per the literal request), so it's simpler, not a
new variant of that UI:

```dart
Future<void> _addAllToCart() async {
  final items = project.items
      .map((i) => (variantId: i.variantId, quantity: i.quantity))
      .toList();
  await ref.read(cartProvider.notifier).addBatch(items);
  if (mounted) context.push('/cart');
}
```

- Stock capping, partial-failure handling, and the resulting cart-badge update
  are all already handled inside `addBatch` — nothing Projects-specific to
  build there.
- Cart items **merge** with whatever's already in the cart (same as every
  other add-to-cart path in the app) — sending a Project to cart doesn't
  clear or replace existing cart contents.
- Sending to cart does **not** auto-mark the project Complete — they're
  independent actions. A chef might send the list to cart, then still add a
  few more items to the same Project before the order actually ships, so
  tying them together would be a real behavior regression, not a convenience.

---

## 6b. Event Date / Client Details

Confirmed (§10 decision 6) — added as nullable fields, not required at
creation:

```
┌─────────────────────────────────────────────────┐
│ ← Cancel        New Project             [Save]  │
│                                                  │
│  Project Name *  ___________________________     │
│  Event Date       ___________________ (picker)   │
│  Client Name      ___________________________    │
│  Client Phone     ___________________________    │
│  Notes            ___________________________    │
│                   ___________________________    │
└─────────────────────────────────────────────────┘
```

- Reached from the Projects List's **[+ New]** (§5) — the *full* form, same
  `flutter_form_builder` pattern as the Address form in
  `06_profile_and_account.md`.
- The **quick-create inside the Add-to-Project dialog (§4)** deliberately
  stays name-only — that flow's whole point is speed while browsing products,
  and forcing an event date/client phone in that moment would defeat it. The
  same `[Edit]` action from Project Detail (§6) is how those fields get filled
  in later for a project that was quick-created.
- None of these fields are ever required — a project with just a name is a
  complete, valid project.

---

## 7. Data Model

New tables, same shape/conventions as `wishlists`/`cart_items` in
`baker_ally_backend/supabase/functions/api/db/schema.ts`:

```ts
export const projects = pgTable("projects", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  status: text("status").notNull().default("active"), // 'active' | 'completed' (CHECK in SQL)
  eventDate: timestamp("event_date", { withTimezone: true }), // nullable -- §6b
  clientName: text("client_name"), // nullable -- §6b
  clientPhone: text("client_phone"), // nullable -- §6b
  notes: text("notes"), // nullable -- §6b
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  completedAt: timestamp("completed_at", { withTimezone: true }),
});

export const projectItems = pgTable(
  "project_items",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    projectId: uuid("project_id")
      .notNull()
      .references(() => projects.id, { onDelete: "cascade" }),
    variantId: uuid("variant_id")
      .notNull()
      .references(() => productVariants.id, { onDelete: "cascade" }),
    quantity: integer("quantity").notNull().default(1),
    addedAt: timestamp("added_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    projectVariantUnique: unique().on(table.projectId, table.variantId),
  }),
);
```

Prices are **not** snapshotted onto `project_items` — same live-join philosophy as
Wishlist (`routes/wishlist.ts` joins out to `product_variants` on every read). A
Project is a running plan, not a receipt; if a price changes, the estimate should
reflect the current price. (This is the opposite tradeoff from `order_items`, which
*does* snapshot — because an order is a historical record of what was actually
charged. Worth restating explicitly since it's an easy place to copy the wrong
precedent.)

---

## 8. API

Mirrors `routes/wishlist.ts`'s shape, expanded for the parent/child structure:

| Action | Endpoint | Method |
|---|---|---|
| List projects (+ item count, best-effort cover image) | `/v1/projects?status=active\|completed` | GET |
| Create project | `/v1/projects` | POST `{ name, eventDate?, clientName?, clientPhone?, notes? }` |
| Rename / edit details / mark complete / reopen | `/v1/projects/:id` | PATCH `{ name?, status?, eventDate?, clientName?, clientPhone?, notes? }` |
| Delete project | `/v1/projects/:id` | DELETE |
| Get one project with items + live prices + totals | `/v1/projects/:id` | GET |
| Add/increment an item | `/v1/projects/:id/items` | POST `{ variantId, quantity? }` |
| Update an item's quantity | `/v1/projects/:id/items/:itemId` | PATCH `{ quantity }` |
| Remove an item | `/v1/projects/:id/items/:itemId` | DELETE |
| Flattened set of variantIds across all *active* projects (icon fill state) | `/v1/projects/item-variant-ids` | GET |
| Which active projects already contain this variant (dialog checkbox state, §4) | `/v1/projects/item-membership/:variantId` | GET |
| Toggle-off from the dialog by variantId (no item id known client-side) | `/v1/projects/:id/items/by-variant/:variantId` | DELETE |
| Send all items to cart | *(no new endpoint)* | reuses existing `POST /v1/cart/items/batch` — see §6a |

`GET /v1/projects/:id` computes `estimatedTotal`/`originalTotal` server-side (same
"server is the source of truth for money" rule `discountEngine.ts` already follows
for cart/checkout) rather than trusting a client sum — the client mirrors it live for
responsiveness while the stepper is being used, same client-mirrors-server technique
already proven for cart bills and M6.5's quantity-discount banner.

---

## 9. Flutter — Providers & Widgets

New `features/projects/` module, following the existing feature-folder convention
(`data/`, `data/models/`, `presentation/providers/`, `presentation/screens/`,
`presentation/widgets/`):

```dart
// Full list for the /projects screen, tab-filtered client-side from one fetch
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  return ref.read(projectRepositoryProvider).getAll();
});

// One project's items + totals, for /projects/:id
final projectDetailProvider =
    FutureProvider.family<ProjectDetail, String>((ref, projectId) async {
  return ref.read(projectRepositoryProvider).getDetail(projectId);
});

// Flattened variantId set across active projects -- same purpose as
// wishlistIdsProvider, backs the on-tile/detail icon's filled/outline state.
final projectItemVariantIdsProvider =
    StateNotifierProvider<ProjectItemIdsNotifier, Set<String>>((ref) {
  return ProjectItemIdsNotifier(ref.read(projectRepositoryProvider));
});
```

New widgets, each mirroring an existing counterpart:

| New widget | Mirrors |
|---|---|
| `AddToProjectIcon` | `WishlistHeart` — placement, login-gating |
| `AddToProjectDialog` | `AddressSelectorSheet` — bottom sheet, list + create-new |
| `ProjectsListScreen` | `WishlistScreen` grid/list + `Development vs Production Checklist`-style tabs |
| `ProjectDetailScreen` | `cart_item_row.dart` for each line, `checkout_screen.dart`'s bill-summary footer for the totals block |
| `ProjectsTopBarIcon` | `_AvatarButton` in `app_shell.dart` |

**Offline caching scope decision**: full Drift-backed offline support (like Wishlist's
`CachedWishlistItems` table) is **not** proposed for the list/detail screens — those
are browse/manage surfaces, not a hot path rendered on every tile like the heart icon,
so a plain network-first fetch (loading/error states, no offline fallback) is enough.
The one piece that *is* worth a lightweight local cache is
`projectItemVariantIdsProvider` — the flattened id set the on-product icon reads on
every tile render, exactly the same reasoning `cachedWishlistItems` exists for.

---

## 10. Confirmed Decisions

The six open questions this doc originally flagged were confirmed on 2026-09-22 —
recorded here for the milestone build, same role `Milestone 6.5.md`'s "Scope
Decisions" section played before that milestone started:

1. **Reopen a Completed project — confirmed yes.** Built as described in §6:
   the AppBar action swaps between Mark Complete / Reopen based on current status.
2. **Delete a project — confirmed yes, via a direct icon tap** (not swipe-to-dismiss).
   Available both on the Projects List (§5, per-row 🗑️) and Project Detail (§6,
   AppBar 🗑️), always behind a confirmation dialog first.
3. **M6.5 quantity-discount promo inside a Project's total — confirmed: do as
   originally proposed.** Only the plain original-vs-current strike-through applies
   (§6); `product_discounts` (type='quantity') is **not** read for Project totals in
   v1. Revisit only if a later milestone explicitly asks for it — it needs
   `getQuantityDiscountsForVariants` reused against project quantities instead of
   cart quantities, a real (if small) design question, not a trivial reuse.
4. **Converting a Project into a Cart/checkout — confirmed yes.** No longer out of
   scope. Built as "Add All to Cart" (§6a), reusing the existing batch-add endpoint
   Order Again already uses — no new backend work for this part.
5. **Project icon glyph — confirmed: non-blocking, use one of the proposed options**
   (e.g. `Icons.folder_special_outlined`) at build time. Not an architectural
   decision; any reasonable Material icon works.
6. **Notes/date fields — confirmed yes, add them.** `eventDate`, `clientName`,
   `clientPhone`, `notes` added to the schema (§7) and creation/edit flow (§6b), all
   nullable/optional.

---

## 11. Explicitly Out of Scope (this plan)

- Sharing a Project with the client or another staff member (multi-user projects).
- Exporting a Project as a quote/PDF.
- Any change to Wishlist — Projects is additive, doesn't replace or merge with it.
