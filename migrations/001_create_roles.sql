-- Milestone 1 / Phase 1: roles table
-- Defines the set of roles a user can have. Role-level privilege_level_id is a
-- default that a user's own privilege_level_id (see 004_create_users.sql) can override.

CREATE TABLE IF NOT EXISTS roles (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL UNIQUE,
  privilege_level_id  UUID NULL, -- FK to privilege_levels.id, added in 002 after that table exists
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

INSERT INTO roles (name) VALUES
  ('customer_individual'),
  ('admin')
ON CONFLICT (name) DO NOTHING;
