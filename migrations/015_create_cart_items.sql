-- Milestone 3 / Phase 3: cart_items table
-- 00_common_architecture.md §4/§8 -- lines in a user's cart.
-- UNIQUE(cart_id, variant_id) lets "add to cart" be a single upsert
-- (ON CONFLICT DO UPDATE SET quantity = quantity + excluded.quantity)
-- rather than a read-then-write race. Not in the doc's schema listing but
-- required for the add-to-cart interaction to be safe under concurrency.

CREATE TABLE IF NOT EXISTS cart_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id     UUID NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
  variant_id  UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity    INTEGER NOT NULL DEFAULT 1,
  added_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (cart_id, variant_id)
);

CREATE INDEX IF NOT EXISTS idx_cart_items_cart
  ON cart_items(cart_id);

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
