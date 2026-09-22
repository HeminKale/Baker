-- Milestone 8: product_reviews table
-- Planning docs/Architecture/00_common_architecture.md §5a -- product-level,
-- verified-purchase-gated reviews. order_item_id is the specific delivered
-- purchase that proves eligibility; UNIQUE(user_id, product_id) enforces one
-- review per user per product no matter how many times they've re-bought it.

CREATE TABLE IF NOT EXISTS product_reviews (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id        UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  order_item_id     UUID NOT NULL REFERENCES order_items(id),
  overall_rating    SMALLINT NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),
  quality_rating    SMALLINT CHECK (quality_rating BETWEEN 1 AND 5),
  value_rating      SMALLINT CHECK (value_rating BETWEEN 1 AND 5),
  packaging_rating  SMALLINT CHECK (packaging_rating BETWEEN 1 AND 5),
  accuracy_rating   SMALLINT CHECK (accuracy_rating BETWEEN 1 AND 5),
  comment           TEXT,
  tags              TEXT[],
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, product_id)
);

-- product_id lookup drives both the review list and the live-aggregated
-- rating summary on product detail (§5a).
CREATE INDEX IF NOT EXISTS idx_product_reviews_product
  ON product_reviews(product_id);

ALTER TABLE product_reviews ENABLE ROW LEVEL SECURITY;
