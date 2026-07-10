-- Milestone 1 / Phase 1: users table
-- id intentionally has no default — it must be set explicitly to the matching
-- Supabase Auth (auth.users) id on insert (see 00_common_architecture.md §3).
-- fcm_token is an addition beyond the architecture doc: Phase 1.5 requires
-- POST /v1/users/fcm-token to persist a device token and there is no other
-- table for it to live in.

CREATE TABLE IF NOT EXISTS users (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email               TEXT,
  phone               TEXT,
  full_name           TEXT,
  business_name       TEXT,
  gstin               TEXT,
  avatar_url          TEXT,
  fcm_token           TEXT,
  role_id             UUID NOT NULL REFERENCES roles(id),
  privilege_level_id  UUID REFERENCES privilege_levels(id), -- NULL = inherit from role
  is_active           BOOLEAN NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_privilege_level_id ON users(privilege_level_id);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
