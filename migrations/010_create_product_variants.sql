-- Milestone 2 / Phase 2: product_variants table
-- 00_common_architecture.md §4/§6 -- size/weight options, two-price model
-- (original_price shown struck-through, current_price is the selling price).
-- Prices are stored in paise (INTEGER), matching orders/order_items later.

CREATE TABLE IF NOT EXISTS product_variants (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  sku             TEXT NOT NULL UNIQUE,
  original_price  INTEGER NOT NULL,
  current_price   INTEGER NOT NULL,
  stock_qty       INTEGER NOT NULL DEFAULT 0,
  is_active       BOOLEAN NOT NULL DEFAULT true,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_variants_product
  ON product_variants(product_id) WHERE is_active = true;

ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
