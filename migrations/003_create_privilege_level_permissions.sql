-- Milestone 1 / Phase 1: privilege_level_permissions table
-- Per-object (table) read/edit/field/record-scope rules for a privilege level.
-- See 00_common_architecture.md §3 and §14 (Admin Web Panel) for how this is edited/consumed.

CREATE TABLE IF NOT EXISTS privilege_level_permissions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  privilege_level_id  UUID NOT NULL REFERENCES privilege_levels(id) ON DELETE CASCADE,
  object_name         TEXT NOT NULL,
  can_read            BOOLEAN NOT NULL DEFAULT false,
  can_edit            BOOLEAN NOT NULL DEFAULT false,
  field_overrides     JSONB,
  record_scope        TEXT NOT NULL DEFAULT 'own' CHECK (record_scope IN ('own', 'all')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_privilege_level_permissions_level
  ON privilege_level_permissions(privilege_level_id);

ALTER TABLE privilege_level_permissions ENABLE ROW LEVEL SECURITY;
