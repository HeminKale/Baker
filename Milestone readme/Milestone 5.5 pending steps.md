# Milestone 5.5 — Pending Steps

**Status:** Backend already deployed (`supabase functions deploy api` ran successfully during the build, project `bpmtnsaebrnuoujwxfea`). Flutter has **not** been rebuilt on a device with this code yet. No new Storage buckets, no new DB migrations — this is a much smaller deploy than Milestone 5's.

**Prerequisites:** Milestone 5 already deployed (Home reuses its top bar, avatar, and address-selector infrastructure directly).

---

## What's Actually Pending

### 1. Rebuild Flutter and test on a device

Backend is live; the app on your phone is still running whatever build it had before this session. Needs a full rebuild because the Drift schema bumped (v4 → v5):

```bash
cd "c:\Users\hemin\OneDrive\Desktop\Android Project\baker_ally_flutter"
flutter clean
flutter pub get
flutter run
```

`flutter clean` isn't strictly required for a Drift version bump (the `onUpgrade` migration handles it), but the app's local sqlite file on a device that already ran a pre-5.5 build will go through the `from < 5` migration path on first launch after the update — worth confirming that path runs cleanly rather than assuming it does, since it's only been exercised by `deno check`/`flutter analyze`, not a live device.

### 2. No live end-to-end verification yet

Same caveat as every other milestone here — this was built and verified with `deno check`, `flutter analyze`, `flutter test`, and `dart run build_runner build`, not a live session against real seeded data. Specifically unverified:

- [ ] Home actually shows real tiles (not empty sections) — depends on the seeded catalog having recent products, discounted variants, and at least one `isTrending = true` product. If Milestone 2's seed data is sparse, some/all sections may legitimately render empty (by design — see Milestone 5.5.md §2, empty sections hide rather than show a blank state).
- [ ] "New Offers" tiles show the actual discounted price — this is the one spot with real query logic (not just wiring), worth a specific look rather than assuming the fix in Milestone 5.5.md §5 works as designed.
- [ ] "See all" pagination — "Load More" on a section with 20+ products.
- [ ] Search bar on Home returns the same results Catalog's search does for the same query (they now share `SearchResultsGrid`, but worth confirming visually).
- [ ] Offline fallback — force airplane mode after Home has loaded once, confirm it still renders from the new `CachedHomeSections` table instead of erroring.
- [ ] Address label tap in the top bar (now live on every tab, not just Home) opens the picker and the label updates after a selection.

### 3. Decide whether to seed more catalog data

If Home ships empty (or nearly empty) because there isn't a good spread of recent/discounted/trending products in the seed data, that's a content problem, not a code problem — either seed a few more products/variants with `isTrending = true` and some `currentPrice < originalPrice` variants, or accept that Home will fill in naturally once the admin panel (Milestone 6) exists and real products get added.

---

## Explicitly Not Pending (already decided, don't re-litigate)

- Notification bell — deferred, needs its own `notifications` table + polling infra (Milestone 5.5.md §2)
- Voice search mic button — was deferred (Kotlin 2.0 `speech_to_text` incompatibility, Milestone 5.5.md §2); **since implemented 2026-07-18**, see `Voice Search.md`
- Workmanager background refresh — deferred, same Kotlin 2.0 issue
- New Storage buckets — none needed, Home only reads existing `products`/`productVariants`/`productImages`
- New DB migrations — none, zero Postgres schema changes this milestone
