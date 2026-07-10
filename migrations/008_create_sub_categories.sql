-- Milestone 2 / Phase 2: sub_categories table
-- 00_common_architecture.md §4/§19 -- child of categories, parent of products.

CREATE TABLE IF NOT EXISTS sub_categories (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id  UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  image_url    TEXT,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subcategories_category
  ON sub_categories(category_id) WHERE is_active = true;

ALTER TABLE sub_categories ENABLE ROW LEVEL SECURITY;
