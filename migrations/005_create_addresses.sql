-- Milestone 1 / Phase 1: addresses table (saved delivery addresses)

CREATE TABLE IF NOT EXISTS addresses (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label        TEXT,
  line1        TEXT NOT NULL,
  line2        TEXT,
  city         TEXT NOT NULL,
  state        TEXT NOT NULL,
  pincode      TEXT NOT NULL,
  is_default   BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON addresses(user_id);

ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
