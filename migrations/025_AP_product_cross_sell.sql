-- Milestone 6 / Phase 6: admin-curated cross-sell overrides
-- "You Might Also Like" is 100% algorithmic today everywhere (product-detail,
-- checkout recommendations, Order Again's Frequently Bought Together). This
-- adds the first admin-curatable grouping: positions 5-7 of the 10-slot
-- recommendation list prefer a curated pick for the source product if one
-- exists, falling back to algorithmic. Order Again's FBT is untouched (it's
-- purchase-history-based, not in scope here).

CREATE TABLE IF NOT EXISTS product_cross_sell (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_product_id       UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  recommended_product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  sort_order              INTEGER NOT NULL DEFAULT 0,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (source_product_id, recommended_product_id)
);

CREATE INDEX IF NOT EXISTS idx_product_cross_sell_source
  ON product_cross_sell(source_product_id, sort_order);

ALTER TABLE product_cross_sell ENABLE ROW LEVEL SECURITY;
