-- Milestone 2 / Phase 2: wishlists table
-- 00_common_architecture.md §4 -- per-login wishlist (decision #9 in §17),
-- synced across devices. UI (heart toggle) lands in Phase 2 per the plan;
-- the full wishlist grid screen is Phase 5.

CREATE TABLE IF NOT EXISTS wishlists (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  variant_id  UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, variant_id)
);

CREATE INDEX IF NOT EXISTS idx_wishlists_user
  ON wishlists(user_id);

ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;
