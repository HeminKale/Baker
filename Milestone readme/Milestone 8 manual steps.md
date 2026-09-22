# Milestone 8 — Manual Setup & Deployment Steps

**Status:** Code is complete and statically verified (see `Milestone 8.md` §5), but Reviews & Ratings isn't live yet — same Supabase CLI privilege gap as Milestone 7 (`403` on `bpmtnsaebrnuoujwxfea`). The tile redesign and Notify Me button are pure Flutter changes and don't need any of this — Phase C alone is enough for those two.

**Time Required:** ~10 minutes. **Two migrations are pending, not one** — Milestone 7's `027_AP_create_projects.sql` never got applied either, so run both in order.

---

## Phase A: Apply Both Pending Migrations

```bash
cd "C:\Users\hemin\Desktop\Android Project\baker_ally_backend"
supabase db query -f "../migrations/027_AP_create_projects.sql" --linked
supabase db query -f "../migrations/028_AP_create_product_reviews.sql" --linked
```

Both are `IF NOT EXISTS`/safe to re-run. A `Timeout while shutting down PostHog` line after a successful query is CLI telemetry noise, not a failure.

**Verify:**
```sql
SELECT status FROM projects LIMIT 0;           -- Milestone 7 -- column exists, no error
SELECT overall_rating FROM product_reviews LIMIT 0;  -- Milestone 8 -- column exists, no error
```

## Phase B: Deploy the Backend

```bash
cd "C:\Users\hemin\Desktop\Android Project\baker_ally_backend"
supabase functions deploy api
```

One deploy picks up both `routes/projects.ts` (Milestone 7, also still pending) and `routes/reviews.ts` (this milestone).

**Verify:**
```bash
curl "https://bpmtnsaebrnuoujwxfea.supabase.co/functions/v1/api/v1/health"
# → {"data":{"status":"ok"}}
```

## Phase C: Flutter — Rebuild

**What:** Picks up the redesigned `ProductTile`, the Notify Me button, and the new Reviews & Ratings UI. No Drift schema change this milestone — no `flutter pub run build_runner build` needed.

```bash
cd "C:\Users\hemin\Desktop\Android Project\baker_ally_flutter"
flutter pub get
flutter run
```

## Phase D: End-to-End Test

**Tile redesign (no backend dependency — test even before Phase A/B):**
1. Open the Catalog grid → confirm tiles no longer have a boxed card background behind the text; the name/variant/price sit directly on the screen.
2. Confirm a small circular "+" sits in the image's bottom-right corner, overlapping the image edge. Tap it → confirm it expands to a "− N +" pill in the same spot, and the cart badge updates.
3. Add up to a variant's stock limit → confirm "Max stock reached" still shows (unchanged logic, just relocated).
4. Find an out-of-stock product → confirm the corner is empty and the "Out of Stock" badge (top-left) is the only signal.
5. Confirm the wishlist heart and Add-to-Project icon (top-right, stacked) are unaffected.

**Notify Me (no backend dependency for the toggle itself — FCM delivery needs a configured Firebase project, separately):**
6. Open an out-of-stock product's detail page → confirm the bottom CTA now reads "Notify Me When Available" instead of a disabled "Out of Stock" button.
7. Tap it while logged out → confirm the login-required sheet appears instead of doing anything.
8. Log in, tap it again → confirm it flips to "We'll notify you when it's back" (outlined style). Confirm the wishlist heart elsewhere on this same product also now shows filled — same underlying toggle.
9. Tap the "We'll notify you" button again → confirm it reverts (removes the wishlist entry / cancels the request).

**Reviews & Ratings (needs Phase A + B live):**
10. Find a product you've received in a `delivered` order → open its detail page → scroll to "Reviews & Ratings" → confirm an "Add Review" button appears.
11. On a product you have **not** purchased (or purchased but not yet delivered) → confirm no "Add Review" button appears, and no error is shown either — it just doesn't render.
12. Tap "Add Review" → set an overall star rating (try submitting without one first — confirm it's blocked with an inline message), optionally fill in the 4 category ratings, a comment, and a couple of tag chips → Submit → confirm the sheet closes and the review list/rings/count refresh without needing to leave the page.
13. Try submitting a second review for the same product → confirm the "Add Review" button is now gone (already reviewed) — the eligibility check re-runs after a submit.
14. Confirm the 4 rating rings show live averages (or "–" for a category nobody's rated yet), and the overall star + count line matches.
15. Confirm review cards show a reasonable author label (e.g. "Priya S." from a full name, or "Customer" if the reviewer has none set), a relative timestamp, the comment, and any tag chips.

## Phase E: Verification Checklist

- [ ] Both migrations applied (`projects` and `product_reviews` both queryable with no error)
- [ ] `supabase functions deploy api` succeeded, `/v1/health` reachable
- [ ] Tile redesign: no card background, floating "+" → stepper works, out-of-stock corner empty
- [ ] Notify Me: button replaces the old disabled state, toggles the wishlist correctly, login-gated
- [ ] Reviews: eligibility correctly gates the Add Review button (purchased+delivered+not-already-reviewed only)
- [ ] Add Review form validates overall rating, submits successfully, list/rings refresh live
- [ ] Review cards render author/date/comment/tags correctly

---

## Troubleshooting

**"Reviews & Ratings section never loads / spins forever."**
The Edge Function hasn't picked up `routes/reviews.ts` yet — re-run Phase B.

**"Add Review button never appears even on a product I received."**
Confirm the order's `status` is exactly `delivered`, not `confirmed`/`shipped` — eligibility is intentionally strict about that (a fair "Packaging Condition" review needs the item to have actually arrived).

**"Migration query says relation already exists."**
Harmless — every statement in both pending migration files is `IF NOT EXISTS`, safe to re-run.

---

## Next Steps After Verification

```bash
git add -A
git commit -m "Milestone 8: catalog tile redesign, Notify Me, Reviews & Ratings"
git push
```
Once verified, `02_catalog_tab.md` and `00_common_architecture.md` already carry the "✅ Built in Milestone 8" callouts as of this write-up — no further doc update needed unless this manual-steps pass surfaces a real behavior change from what's documented in `Milestone 8.md`.
