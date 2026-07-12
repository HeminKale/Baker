-- Milestone 3 / Phase 3: carts table
-- 00_common_architecture.md §4/§8 -- one active cart per user (UNIQUE user_id).
-- Server cart is the source of truth; Drift is the local instant-UI layer.

CREATE TABLE IF NOT EXISTS carts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE carts ENABLE ROW LEVEL SECURITY;
