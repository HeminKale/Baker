-- Milestone 3 / Phase 3: discounts table
-- 00_common_architecture.md §4 (Discounts). code is NULL for auto-applied
-- discounts, UNIQUE otherwise. value semantics depend on type:
--   percent        -> value is a whole percent (10 = 10% off)
--   flat           -> value is paise off (5000 = ₹50 off)
--   free_shipping  -> value ignored; waives the shipping line
-- No pgEnum precedent in this codebase -- type is TEXT + CHECK, matching the
-- record_scope / status pattern used elsewhere.

CREATE TABLE IF NOT EXISTS discounts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code             TEXT UNIQUE,
  name             TEXT NOT NULL,
  type             TEXT NOT NULL CHECK (type IN ('percent', 'flat', 'free_shipping')),
  value            INTEGER NOT NULL DEFAULT 0,
  min_order_value  INTEGER NOT NULL DEFAULT 0,
  max_uses         INTEGER,
  uses_count       INTEGER NOT NULL DEFAULT 0,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  starts_at        TIMESTAMPTZ,
  expires_at       TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE discounts ENABLE ROW LEVEL SECURITY;
