# Milestone 7 — Manual Setup & Deployment Steps

**Status:** Code is complete and statically verified (see `Milestone 7.md` §4), but nothing is live yet. Applying the migration and redeploying the Edge Function both require Supabase project privileges the CLI session used to build this didn't have (`403` — "Your account does not have the necessary privileges to access this endpoint"). Run Phase A and B yourself with an account that has access to `bpmtnsaebrnuoujwxfea`.

**Time Required:** ~10 minutes, same shape as every prior milestone's manual steps — one migration, one redeploy, one Flutter rebuild.

---

## Phase A: Apply the Migration

```bash
cd "C:\Users\hemin\Desktop\Android Project\baker_ally_backend"
supabase db query -f "../migrations/027_AP_create_projects.sql" --linked
```

Creates `projects` and `project_items` (both `IF NOT EXISTS`, safe to re-run). A `Timeout while shutting down PostHog` line after a successful query is CLI telemetry noise, not a failure — check the result above it.

**Verify:**
```sql
SELECT status FROM projects LIMIT 0;        -- column exists, no error
SELECT quantity FROM project_items LIMIT 0; -- column exists, no error
```

## Phase B: Deploy the Backend

```bash
cd "C:\Users\hemin\Desktop\Android Project\baker_ally_backend"
supabase functions deploy api
```

This is the same single Edge Function that serves the Flutter app and the admin panel (`CLAUDE.md`) — redeploying picks up `routes/projects.ts` for everyone. `/v1/admin/*` CORS scoping is unaffected; no admin-panel changes were made this milestone.

**Verify:**
```bash
curl "https://bpmtnsaebrnuoujwxfea.supabase.co/functions/v1/api/v1/health"
# → {"data":{"status":"ok"}}
```
(A full `/v1/projects` check needs a real bearer token — easiest done from the app itself in Phase D.)

## Phase C: Flutter — Rebuild

**What:** Picks up the Drift v5→v6 migration (new `CachedProjectItemVariantIds` table, additive) and the new Projects screens/widgets.

```bash
cd "C:\Users\hemin\Desktop\Android Project\baker_ally_flutter"
flutter pub get
flutter run
```

**Upgrading from a pre-Milestone-7 install:** Drift runs its v5→v6 `onUpgrade` automatically on first launch (creates the one new table) — no uninstall needed.

## Phase D: End-to-End Test

1. **Top bar icon:** Log in → confirm a folder icon now sits between the address label and the avatar. Tap it while logged out first to confirm it shows the "Log in required" sheet instead of navigating.
2. **Add to Project from a tile:** On the Catalog grid, confirm a second icon (folder, outline) now sits below the wishlist heart on a product tile. Tap it → the "Add to Project" sheet opens with a search bar, an empty project list, and "New Project..." pinned at the bottom.
3. **Create + add in one action:** Tap "New Project...", type a name (e.g. "Hero's Birthday"), confirm → the sheet should show that project now checked, and the icon on the tile should go from outline to filled.
4. **Multi-select:** Create a second project from the same sheet, check a couple more products into both projects from different tiles — confirm the icon fill state stays correct across tiles/screens (it's backed by one shared provider).
5. **Projects list:** Tap the top-bar icon → confirm both projects appear under the **Active** tab with correct item counts and estimated totals; the **Completed** tab is empty.
6. **Project detail:** Open a project → confirm each item shows the right product/variant name, price (struck-through original + green current if the variant is on sale), and a `[-] N [+]` stepper. Adjust a quantity, confirm the estimated total updates. Remove an item via its row's delete icon.
7. **Event/client details:** Tap `[Edit]` under the project name → set an event date, client name, phone, notes → Save → confirm the subtitle line now shows them (and the Projects List row shows the 📅 date).
8. **Mark Complete / Reopen:** Tap the AppBar's check-circle icon → confirm the project moves to the **Completed** tab and its stepper/remove controls still work (the plan explicitly keeps editing available on a Completed project, since "Add All to Cart" needs to work there too). Tap the AppBar icon again (now a replay icon) → confirms it reopens back to Active.
9. **Add All to Cart:** From a project's detail screen, tap **Add All to Cart** → confirm you land on the Cart tab with every project item added (merged with, not replacing, whatever was already in the cart).
10. **Delete:** Delete a project from its detail AppBar (confirm the dialog wording shows the right item count) and delete another directly from its row on the Projects List → confirm both disappear and the icon fill state on any tile that had items in the deleted project clears correctly.
11. **Guest/offline (optional):** Force-close and reopen the app while offline → confirm previously-filled Add-to-Project icons still show as filled (served from the Drift cache) even though the network call to refresh would fail silently.

## Phase E: Verification Checklist

- [ ] Migration applied (`projects`/`project_items` exist, `SELECT`s above return no error)
- [ ] `supabase functions deploy api` succeeded, `/v1/health` reachable
- [ ] Top-bar icon opens `/projects`, gated behind login
- [ ] Add-to-Project icon appears on both the catalog tile and product detail, next to the wishlist heart
- [ ] Dialog create-and-add, multi-select toggle, and search all work
- [ ] Projects List Active/Completed tabs, search, and `[+ New]` all work
- [ ] Project Detail's stepper, per-item delete, totals (with strikethrough when applicable), event/client edit sheet, Mark Complete/Reopen, and project delete all work
- [ ] Add All to Cart lands on `/cart` with every item present, merged with existing cart contents
- [ ] Icon fill state stays correct across tiles/screens after add/remove/delete
- [ ] Offline: cached icon fill state survives a cold start without network

---

## Troubleshooting

**"`/v1/projects` returns 404."**
The Edge Function hasn't picked up the new route yet — re-run Phase B (`supabase functions deploy api`).

**"Add-to-Project icon never fills in even after adding an item."**
Check `projectItemVariantIdsProvider` is actually being refreshed — every mutation in `ProjectRepository` (`addItem`, `setMembership`, etc.) calls `refreshItemVariantIds()` internally, but a failed network call swallows the error silently (by design, same as Wishlist). If the Edge Function isn't deployed (see above), this is the expected symptom.

**"Migration query says relation already exists."**
Harmless — every statement in `027_AP_create_projects.sql` is `IF NOT EXISTS`, safe to re-run.

---

## Next Steps After Verification

```bash
git add -A
git commit -m "Milestone 7: Projects (per-job equipment lists)"
git push
```
Once verified, go back to `Planning docs/Architecture/07_projects.md`'s top banner and confirm it still says "✅ Built in Milestone 7" (it already does as of this write-up) — no further doc update needed unless this manual-steps pass surfaces a real behavior change from what's documented above.
