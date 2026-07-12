-- Milestone 3 / Phase 3: seed one demo discount code
-- Lets the "apply discount code" checkout flow be demoed end-to-end before the
-- Phase 6 admin panel exists to create real codes. BAKE10 = 10% off, no
-- minimum, no expiry, unlimited uses. Matches the BAKE10 code shown in the
-- Phase_Plan_Business.md checkout mockup.
-- Safe to run once; ON CONFLICT keeps a re-run from erroring on the UNIQUE code.

INSERT INTO discounts (code, name, type, value, min_order_value, is_active)
VALUES ('BAKE10', 'Baker Ally 10% Off', 'percent', 10, 0, true)
ON CONFLICT (code) DO NOTHING;
