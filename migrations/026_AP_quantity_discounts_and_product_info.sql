-- Milestone 6.5: quantity-based ("buy N of a variant, get ₹X off") progress
-- promos on the product detail page, plus per-product admin-authored info
-- bullets shown from a new (i) icon (replacing the wishlist heart's old spot
-- -- the heart itself moves onto the product image, mirroring catalog tiles).
--
-- Quantity discounts reuse `discounts` + `product_discounts`. `product_discounts`
-- was built in Milestone 3 (017_create_product_discounts.sql) "so the Phase 6
-- admin panel can scope discounts" but has been completely unreferenced ever
-- since -- this is what finally wires it up. `threshold_qty` / `message_template`
-- are only meaningful when discounts.type = 'quantity'; the existing `value`
-- column (paise) is reused for the flat amount awarded once the threshold is
-- met. `code`, `min_order_value`, `max_uses`, `uses_count` stay unused
-- (defaults) for quantity-type rows -- those are code-redemption concepts
-- that don't apply here. `starts_at`/`expires_at` are honored on the read
-- side but not exposed in the v1 admin UI.
--
-- Single-tier only: one threshold/amount per variant, confirmed in planning.
-- The partial unique index enforces that -- `product_discounts` has zero rows
-- in production today (confirmed unreferenced), so this is safe to add.

ALTER TABLE discounts DROP CONSTRAINT IF EXISTS discounts_type_check;
ALTER TABLE discounts ADD CONSTRAINT discounts_type_check
  CHECK (type IN ('percent', 'flat', 'free_shipping', 'quantity'));

ALTER TABLE discounts ADD COLUMN IF NOT EXISTS threshold_qty INTEGER;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS message_template TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_discounts_variant_unique
  ON product_discounts(variant_id) WHERE variant_id IS NOT NULL;

-- Product-level (not variant-level) admin-authored bullet info, shown via a
-- bottom sheet from the new (i) icon on product detail. Newline-separated,
-- split client-side -- same free-text convention as `description`.
ALTER TABLE products ADD COLUMN IF NOT EXISTS info_message TEXT;
