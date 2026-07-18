-- Milestone 6 / Phase 6: back-in-stock notification support on wishlists
-- Wishlisting an out-of-stock item doubles as the "notify me" request (see
-- Milestone 6 plan deviation #3). last_notified_at dedupes repeat pushes for
-- the same restock event; the variant_id index lets the restock trigger
-- (025_AP_restock_notify_trigger.sql) look up wishlist rows by variant --
-- only idx_wishlists_user exists today.

ALTER TABLE wishlists
  ADD COLUMN IF NOT EXISTS last_notified_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_wishlists_variant
  ON wishlists(variant_id);
