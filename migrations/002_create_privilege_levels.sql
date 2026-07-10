-- Milestone 1 / Phase 1: privilege_levels table
-- A named configuration of object/field/record access. Not consumed by any
-- feature yet (Admin Web Panel in Phase 6 is the first to read/write these) —
-- the table + FK wiring exists now so roles.privilege_level_id and
-- users.privilege_level_id (004) have somewhere to point.

CREATE TABLE IF NOT EXISTS privilege_levels (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  description  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE privilege_levels ENABLE ROW LEVEL SECURITY;

ALTER TABLE roles
  ADD CONSTRAINT roles_privilege_level_id_fkey
  FOREIGN KEY (privilege_level_id) REFERENCES privilege_levels(id);
