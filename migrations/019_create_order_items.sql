-- Milestone 3 / Phase 3: order_items table
-- 00_common_architecture.md §4/§9 -- immutable snapshot of what was ordered.
-- product_name / variant_name / unit_price are copied at checkout time so the
-- order record stays correct even if the catalog is later edited or a variant
-- is deleted.

CREATE TABLE IF NOT EXISTS order_items (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  variant_id    UUID NOT NULL REFERENCES product_variants(id),
  product_name  TEXT NOT NULL,
  variant_name  TEXT NOT NULL,
  quantity      INTEGER NOT NULL,
  unit_price    INTEGER NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order
  ON order_items(order_id);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
