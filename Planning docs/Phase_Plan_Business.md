# Baker Ally — Project Delivery Plan
> For: Business stakeholders & client
> Purpose: What you will see, when you will see it, and what it means for the business
> Last updated: July 2026

---

## The Big Picture

Baker Ally is being built in **7 milestones** over **14 weeks**. Each milestone delivers something real and testable — not just backend work that's invisible to you.

```
Week 1–2    Week 3–4    Week 5–6    Week 7–8    Week 9–10   Week 11–12  Week 13–14
   │            │            │            │            │            │            │
   ▼            ▼            ▼            ▼            ▼            ▼            ▼
Milestone 1  Milestone 2  Milestone 3  Milestone 4  Milestone 5  Milestone 6  Milestone 7
  Login &      Browse       Buy          Delivery     My           Admin        App Store
  Identity     Catalog      Products     Updates      Account      Panel        Launch
```

*Milestone 5.5 (Home tab) was added after the original 7-milestone plan as a small
addendum between Milestones 5 and 6 — see below.*

---

## What Gets Built and When

---

### Milestone 1 — Login & Identity
**Weeks 1–2**

**What you get:**
A working login experience. Customers and admins can sign in — no browsing or buying yet, but the identity system is fully set up.

```
┌─────────────────────────────────────┐
│                                     │
│           Baker Ally                │
│                                     │
│   Enter your phone number           │
│   ┌─────────────────────────────┐  │
│   │  +91  98765 43210           │  │
│   └─────────────────────────────┘  │
│                                     │
│   [ Send OTP ]                      │
│                                     │
│   ──────── or ────────              │
│                                     │
│   [ Continue with Google ]          │
│                                     │
└─────────────────────────────────────┘
```

**What this enables for the business:**
- Every user who signs up gets a profile — name, business name, GSTIN (optional)
- Admin accounts are separate from customer accounts — same login, different access
- The foundation for all user data, order history, and personalisation is in place

**What you can demo at this milestone:**
- Sign up with a phone number via OTP
- Sign in with Google
- View a basic profile screen
- Log out

---

### Milestone 2 — Browse the Catalog
**Weeks 3–4**

**What you get:**
Customers can browse the entire product catalog — all categories, subcategories, and products that have been seeded in the system. Search and voice search work.

```
Baker Ally App — Catalog View

  Ingredients
  ┌──────────┐ ┌──────────┐ ┌──────────┐
  │  [img]   │ │  [img]   │ │  [img]   │ →
  │ Creams   │ │ Cocoa &  │ │ Fruit    │
  │          │ │ Choc.    │ │ Fillings │
  └──────────┘ └──────────┘ └──────────┘

  Packaging
  ┌──────────┐ ┌──────────┐ ┌──────────┐
  │  [img]   │ │  [img]   │ │  [img]   │ →
  │ Cake Box │ │ Dessert  │ │ PVC &    │
  │          │ │ Boxes    │ │ Acrylic  │
  └──────────┘ └──────────┘ └──────────┘

  ...and all other categories
```

```
Product Detail View

  ┌────────────────────────────────────┐
  │   [Product photo gallery]          │
  │   ○ ● ○ ○  swipe for more         │
  │                                    │
  │   Fresh Cream 25%         ❤       │
  │   Ingredients · Creams            │
  │   ~~₹120~~  ₹95  🏷️ 21% off      │
  │                                    │
  │   [200ml] [500ml ●] [1L]           │
  │                                    │
  │   High quality fresh cream...      │
  │                                    │
  │   [+ Add to Cart · ₹95]            │
  └────────────────────────────────────┘
```

**What this enables for the business:**
- All 6 product categories live in the app
- Pricing, discounts, and stock status visible to customers
- "Out of Stock", "Low Stock", "Trending", "New" badges auto-displayed based on data
- Products can be added/removed/edited by seeding the database — no app update needed

**What you can demo at this milestone:**
- Browse all categories and subcategories
- Tap into a subcategory and see products in a grid
- Tap a product to see detail, images, and variants
- Search by text and voice
- Add to wishlist (heart icon)

---

### Milestone 3 — Buy Products
**Weeks 5–6**

**What you get:**
The complete purchase flow — add to cart, apply a discount code, choose a delivery address, pay via Razorpay (UPI, cards, netbanking), and get an order confirmation.

```
Checkout Page

  ITEMS IN YOUR CART
  ┌──────────────────────────────────────────┐
  │ [img]  Fresh Cream 25%     [−] 2 [+]    │
  │        500ml · ₹95                       │
  ├──────────────────────────────────────────┤
  │ [img]  Dark Chocolate      [−] 1 [+]    │
  │        1kg · ₹380                        │
  └──────────────────────────────────────────┘

  YOU MIGHT ALSO LIKE
  [ tile ] [ tile ] [ tile ] →

  BILL DETAILS
  Item total              ₹1,040
  Discount (BAKE10)     −  ₹104
  Delivery                   ₹49
  ─────────────────────────────
  To pay                  ₹985

  [Enter discount code]   [Apply]

  CANCELLATION POLICY
  Orders can be cancelled within 2 hours...

  ────────────────────────────────────────────
  📍 Home, 123 MG Road, Mumbai     [Change]
  💳 UPI  ∧                ₹985  [Proceed →]
```

**What this enables for the business:**
- Real transactions — money flows from customer to Baker Ally via Razorpay
- UPI payments cost Baker Ally nothing (0% fee)
- Discount codes can be created and applied — supports promotions
- Every order is recorded with customer details, items ordered, amount paid

**What you can demo at this milestone:**
- Add items to cart, adjust quantities
- Apply a discount code and see the bill update
- Change delivery address
- Complete a payment via Razorpay test mode (no real money)
- See order confirmation screen with order ID

---

### Milestone 4 — Order Updates & Delivery
**Weeks 7–8**

**What you get:**
Orders placed in Milestone 3 now automatically trigger delivery booking (Shiprocket) and customer communications (in-app notifications + push notifications). **Note (2026-07-12): no WhatsApp messaging is built by Baker Ally.** Shiprocket sends its own WhatsApp/SMS delivery updates directly to the customer under its own account — that's the carrier's communication, not something this app builds or pays for.

```
Order Journey — What the customer sees:

Order placed
    │
    ▼
🔔 In-app: "Your Baker Ally order #3392 is confirmed! Total: ₹985"
📱 Push notification: "Order confirmed"
    │
    ▼  (when warehouse ships)
🔔 In-app: "Your order is on the way! Track: [link]"
📱 Push notification: "Order shipped"
    │
    ▼  (day of delivery)
🔔 In-app: "Your order will be delivered today"
📱 Push notification: "Out for delivery"
    │
    ▼
🔔 In-app: "Order delivered! How was your experience?"
📱 Push notification: "Delivered ✅"
```

```
Order Status Screen (in app)

  ORD-3392 · 5 Jul 2026
  ─────────────────────────────────
  ✅ Order Confirmed      5 Jul 10:32am
  📦 Processing           5 Jul 11:00am
  🚚 Shipped              6 Jul 9:15am
     Carrier: Delhivery
     Tracking: 12345678
  ○ Out for delivery
  ○ Delivered
```

**What this enables for the business:**
- Fully automated post-order communication — no manual messages needed, no WhatsApp Business API cost
- Customer always knows where their order is without calling (in-app + push)
- Delivery is handled through Shiprocket (BlueDart, Delhivery, and 25+ carriers) — Shiprocket's own WhatsApp/SMS updates to the customer are separate and automatic on their end
- Staff only need to pick, pack, and hand over to courier

**What you can demo at this milestone:**
- Place a test order → see the in-app notification appear
- Place a test order → receive push notification on phone
- View live order tracking status in the app
- Notification bell in app shows order updates

---

### Milestone 5 — My Account & Smart Reordering
**Weeks 9–10**

**What you get:**
Full account management and two powerful repeat-purchase features: "Frequently Bought Together" (reorder a whole basket) and "Previously Bought" (reorder individual items quickly).

```
Order Again Tab

  FREQUENTLY BOUGHT TOGETHER

  ← [Fresh Cream   ] [Dark Choc.    ] →
    [+ Cake Box    ] [+ Butter      ]
    [+ Butter      ]
    4 items · ₹1,240   [Add All]     5 items · ₹1,890  [Add All]


  PREVIOUSLY BOUGHT

  ┌──────────────┐  ┌──────────────┐
  │  [img]       │  │  [img]       │
  │  Fresh Cream │  │  Dark Choc.  │
  │  ₹95         │  │  ₹380        │
  │  Last: 2 Jul │  │  Last: 2 Jul │
  │  [+ Add]     │  │  [+ Add]     │
  └──────────────┘  └──────────────┘
```

```
Profile Overlay

  [Avatar]  Priya Sharma
            Sunshine Cakes & Co.
            +91 98765 43210
            GSTIN 27ABCDE1234F1Z5   [Edit →]

  📦  Your Orders              ›
  🚚  Order Status             ›
  ❤️  Your Wishlist            ›
  🧾  Receipts & Invoices      ›
  📍  Delivery Addresses       ›
  🍰  Recipes                  ›
  📞  Contact Us               ›
  ❓  Help & Support           ›

  🚪  Log Out
```

Also new this milestone: **product reviews & ratings**, so customers can see what other bakers thought before buying.

```
Product Detail — Reviews Section

  4.6 ★★★★★                      410 reviews

  Quality  Value   Packaging  Accuracy
   4.8      4.7      4.5        4.9

  ┌──────────────────────────────────────┐
  │ [avatar] Priya S.            ⭐ 5.0  │
  │ 3 months ago                         │
  │ "Cream held up perfectly for the     │
  │  whole tiering job."                 │
  │ [Quality] [Packaging]                │
  └──────────────────────────────────────┘

  [ Add Review ]  ← only for customers who
                     actually received the order
```

**What this enables for the business:**
- Customers can reorder their usual basket in 2 taps — drives repeat purchases
- Invoice PDFs available for customers who need them for their business accounts
- Wishlist keeps customers engaged and coming back
- Saved addresses make repeat checkout faster
- Reviews build trust for new customers browsing a product for the first time — and only customers who actually received the item can post one, so ratings can't be gamed

**What you can demo at this milestone:**
- Tap "Add All" on a Frequently Bought Together group → all items added to cart
- Browse Previously Bought tab and add individual items
- View and download an invoice PDF
- Manage multiple saved addresses
- View wishlist and add saved items to cart
- Leave a review + star rating on a delivered order's product, see it appear on that product's page

---

### Milestone 5.5 — Home Tab

**What you get:**
The Home tab — currently a blank placeholder — becomes a real discovery page:
a search bar up top, and three horizontal rows of products (Newly Launched, New
Offers, Trending Now), each with a "See all" link to the full list.

```
Home

  🔍 Search ingredients, packaging...

  Newly Launched                    See all →
  ← [Fresh Cream] [Dark Choc.] [Cake Box] →

  New Offers                        See all →
  ← [Silicon Mould] [Parchment] [Colours] →

  Trending Now                      See all →
  ← [Butter] [Vanilla] [Sprinkles] →
```

**What this enables for the business:**
- Customers land on something useful immediately instead of a blank screen
- Discounted items ("New Offers") get visibility without customers having to hunt for them in Catalog
- Trending products get a second, prominent showcase beyond their category page

**What you can demo at this milestone:**
- Open the app → Home shows live product tiles instead of a placeholder
- Tap "Add to Cart" directly from a Home tile
- Tap "See all" on any section → full scrollable list of that section
- Search from Home the same way you would from Catalog

**Not included this round:** the notification bell shown in early mockups (needs its
own build later) and the voice-search microphone (blocked on an Android build tooling
issue, already deferred once before — see technical plan).

---

### Milestone 6 — Admin Panel
**Weeks 11–12**

**What you get:**
A full web-based admin panel at `admin.bakerally.in` (or similar). Everything the store needs to operate is manageable from a browser — laptop or phone.

```
Admin Web Panel — Product Management

  ┌──────────────────────────────────────────────────────────────┐
  │  Baker Ally Admin                  [👤 Admin]  [Settings]    │
  ├──────────────────────────────────────────────────────────────┤
  │  Products   Orders   Discounts   Users                       │
  ├──────────────────────────────────────────────────────────────┤
  │                                                              │
  │  Products                              [+ Add Product]       │
  │  ────────────────────────────────────────────────────        │
  │  Search...   [Category ▼]   [Status ▼]                       │
  │                                                              │
  │  Fresh Cream 25%    Ingredients › Creams    Active  [Edit]   │
  │  Dark Couverture    Cocoa & Choc             Active  [Edit]  │
  │  Cake Box 8 inch    Packaging › Cake Boxes   Active  [Edit]  │
  │  ...                                                         │
  └──────────────────────────────────────────────────────────────┘
```

```
Admin Web Panel — Order Management

  Orders                              [Export CSV]
  ──────────────────────────────────────────────
  [Status ▼]  [Date range]  Search by order/customer

  ORD-3392  Priya Sharma   5 Jul  ₹985   Shipped   [View]
  ORD-3391  Rohan Mehta    5 Jul  ₹1,240 Delivered [View]
  ORD-3390  Anita Patel    4 Jul  ₹620   Processing[View]
```

**What this enables for the business:**
- No dependency on developers for day-to-day operations
- Add new products, change prices, update stock — takes minutes
- Create and manage discount codes for promotions
- See and manage all orders from one screen
- Invite staff members and control what they can access (via privilege levels)

**What you can demo at this milestone:**
- Add a new product with images, variants, and pricing → visible in Flutter app immediately
- Create a discount code → test it in the app
- View all orders, update order status
- Invite a team member with limited access

---

### Milestone 7 — Launch Ready
**Weeks 13–14**

**What you get:**
The app submitted to App Store and Play Store. Real payment keys active. The full system running in production.

**Two things need your action before this milestone can start** (not engineering work — business/account setup):
1. **Apple Developer Account** ($99/year) and **Google Play Console** ($25 one-time) — neither is purchased yet. Store submission is blocked until these exist (see `Costing.md` §10–11).
2. **Product Reviews & Ratings decision.** This was originally scoped into Milestone 5 but wasn't built. Decide: add it as a small pre-launch addendum, or push it to a post-launch update.

```
Launch Checklist Status

  ✅ Flutter app on TestFlight (Apple beta testing)
  ✅ Flutter app on Play Internal Testing (Android beta)
  ✅ Real Razorpay payments tested (live ₹1 transaction)
  ✅ In-app + push notifications delivered on real orders
  ✅ App Store submission — under review
  ✅ Play Store submission — under review
  ✅ Admin panel live at admin.bakerally.in
  ✅ 1,000-user load test passed
  ✅ Error monitoring active (notified within minutes of any issue)
```

**What this enables for the business:**
- Real customers can download and buy from Day 1
- Every order automatically triggers delivery, in-app, and push notifications
- Any technical error alerts the team immediately — nothing goes unnoticed
- App is production-hardened and ready for the launch marketing push

**What you can demo at this milestone:**
- Download from App Store / Play Store (or TestFlight)
- Complete a real purchase end-to-end
- Receive real in-app + push delivery updates

---

## What is NOT in Launch Scope

These features are designed and ready to build — they are intentionally deferred to after launch so the core product ships faster.

| Feature | Why deferred | When |
|---|---|---|
| **Brownie Points loyalty program** | Rules (earn rate, redemption) not yet defined | Post-launch Phase 1 |
| **Porter hyperlocal delivery** | Integration details pending | Post-launch Phase 1 |
| **Free shipping threshold** | Depends on Porter integration | Post-launch Phase 1 |
| **AI product suggestions** | Scope not yet defined | Post-launch Phase 2 |
| **Makers-Business Tools category** | Entirely new feature set | Post-launch Phase 2 |

The app will show a "Brownie Points — Coming Soon" tab so customers know it is coming.

---

## Timeline Summary

```
WEEK    1    2    3    4    5    6    7    8    9   10   11   12   13   14
        ├────┤    ├────┤    ├────┤    ├────┤    ├────┤    ├────┤    ├────┤
M1 ████████
          M2 ████████
                    M3 ████████
                              M4 ████████
                                        M5 ████████
                                                  M6 ████████
                                                            M7 ████████
        └──────────────────────────────────────────────────────────────┘
                              14 Weeks to Launch
```

---

## How We'll Work Together

| Activity | Frequency | Purpose |
|---|---|---|
| Demo / review | End of each milestone (every 2 weeks) | You see and test what was built |
| Feedback window | 3 days after each demo | Raise changes before next milestone starts |
| Status update | Weekly (brief message) | Keep you informed without meetings |
| Decision needed | As required | Some questions only you can answer (e.g. pricing, policies) |

**Two decisions still needed from your side before building the affected features:**

| Decision | Needed by | Affects |
|---|---|---|
| Porter delivery — which cities? how does it work? | Before Milestone 4 (Week 7) | Delivery options at checkout, shipping cost |
| Brownie Points — earn rate, redemption, expiry? | Post-launch (not urgent) | Brownie Points tab |
