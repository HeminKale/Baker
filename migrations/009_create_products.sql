-- Milestone 2 / Phase 2: products table
-- 00_common_architecture.md §4 (schema) + §21 (search_vector, verbatim).

CREATE TABLE IF NOT EXISTS products (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sub_category_id  UUID NOT NULL REFERENCES sub_categories(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  description      TEXT,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  is_trending      BOOLEAN NOT NULL DEFAULT false,
  sort_order       INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  search_vector    TSVECTOR GENERATED ALWAYS AS (
                     to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, ''))
                   ) STORED
);

CREATE INDEX IF NOT EXISTS idx_products_subcategory
  ON products(sub_category_id) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_products_search
  ON products USING GIN(search_vector);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
