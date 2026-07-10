-- Milestone 2 / Phase 2: categories table
-- 00_common_architecture.md §4 -- top of the catalog hierarchy
-- (Category -> SubCategory -> Product -> Variant).

CREATE TABLE IF NOT EXISTS categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  image_url   TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
