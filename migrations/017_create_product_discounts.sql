-- Milestone 3 / Phase 3: product_discounts table
-- 00_common_architecture.md §4 -- links a discount to a specific product or
-- variant (both NULL = applies to all). Table + schema built now so the
-- Phase 6 admin panel can scope discounts; Milestone 3's checkout only uses
-- code-based discounts (discounts.code), not product-scoped auto-discounts yet.

CREATE TABLE IF NOT EXISTS product_discounts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id   UUID REFERENCES products(id) ON DELETE CASCADE,
  variant_id   UUID REFERENCES product_variants(id) ON DELETE CASCADE,
  discount_id  UUID NOT NULL REFERENCES discounts(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_product_discounts_discount
  ON product_discounts(discount_id);

ALTER TABLE product_discounts ENABLE ROW LEVEL SECURITY;
