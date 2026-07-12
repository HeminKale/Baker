-- Milestone 3 / Phase 3: orders table
-- 00_common_architecture.md §4/§9 (order lifecycle state machine).
-- Row created at checkout with status='pending' + razorpay_order_id; flipped
-- to 'confirmed' after payment verification. razorpay_payment_id is UNIQUE --
-- the idempotency guard that prevents a replayed confirmation from creating a
-- duplicate order (§18 risk register "Duplicate orders on payment retry").
-- All money columns are paise (INTEGER), matching product_variants.

CREATE TABLE IF NOT EXISTS orders (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  address_id           UUID NOT NULL REFERENCES addresses(id),
  status               TEXT NOT NULL DEFAULT 'pending'
                         CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  subtotal             INTEGER NOT NULL,
  discount_id          UUID REFERENCES discounts(id),
  discount_value       INTEGER NOT NULL DEFAULT 0,
  shipping_cost        INTEGER NOT NULL DEFAULT 0,
  total                INTEGER NOT NULL,
  razorpay_order_id    TEXT,
  razorpay_payment_id  TEXT UNIQUE,
  notes                TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_user_created
  ON orders(user_id, created_at DESC);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
