# Baker Ally — Figma Screen Generator Plugin

Generates all 9 app screens from the Baker Ally architecture spec directly onto a Figma canvas in a 3×3 grid.

---

## Screens Generated

| Row | Col 0 | Col 1 | Col 2 |
|-----|-------|-------|-------|
| 0 | 01 · Login / OTP | 02 · Home | 03 · Catalog Level 1 |
| 1 | 04 · Catalog Level 2 | 05 · Product Detail | 06 · Order Again |
| 2 | 07 · Cart / Checkout | 08 · Order Confirmation | 09 · Profile Overlay |

Each frame is 390 × 844 px (iPhone 14 Pro), with an 80px gap between frames.

---

## How to Load and Run

1. Open **Figma Desktop** (the plugin API does not work in the browser for local plugins)
2. In any file, go to the menu: **Plugins → Development → Import plugin from manifest...**
3. Navigate to this folder and select **`manifest.json`**
4. Run it: **Plugins → Development → Baker Ally Screen Generator**

The plugin will take a few seconds to generate all 9 screens, then auto-zoom the viewport to show them all.

---

## What You Get

- **Global shell** — Top bar (address pill, bell, avatar), Bottom nav with active states and cart badge
- **Login** — Phone + OTP flow, Google sign-in option
- **Home** — Search bar, 3 horizontal product tile rows (Newly Launched, New Offers, Trending Now)
- **Catalog L1** — Category section headings + subcategory tile rows (horizontal scroll implied)
- **Catalog L2** — Thin left subcategory strip (5%) + product grid (95%) with section headers
- **Product Detail** — Large image, gallery dots, variant chips, pricing with strikethrough, fixed Add to Cart CTA
- **Order Again** — Frequently Bought Together cards + Previously Bought 2-column grid with "Last bought" dates
- **Cart / Checkout** — Cart items with qty steppers, You Might Also Like, Bill Details, Discount code input, fixed 2-row CTA bar
- **Order Confirmation** — Success screen, order details card, WhatsApp confirmation note, action buttons
- **Profile Overlay** — Bottom sheet with profile card, menu list, Log Out button

---

## Design Tokens Used

| Token | Value | Use |
|-------|-------|-----|
| Primary | #D4A853 golden amber | Buttons, active nav, accents |
| Primary BG | #FDF4E0 | Button fills, washes |
| Surface | #F6F3EF | Cards, inputs, subcategory tiles |
| Border | #E4DDD4 | Dividers, tile outlines |
| Text | #191919 | Headings, prices |
| Text Sub | #666666 | Labels, descriptions |
| Text Muted | #A0A0A0 | Placeholders, hints |
| Red | #E23939 | Cart badge, error states, Log Out |
| Green | #33B268 | Discount value, success |
| Amber | #F4A845 | Trending badge |

---

## Notes

- All text uses **Inter** (built into Figma by default — no install needed)
- Image areas are warm-grey placeholders — replace with real product images once catalog is loaded
- The plugin is headless (no UI panel) — it runs immediately on launch and closes when done
- Re-run at any time; it creates new frames (does not overwrite existing ones)
