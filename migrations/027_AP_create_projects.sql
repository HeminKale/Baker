-- Milestone 7: projects + project_items tables
-- Planning docs/Architecture/07_projects.md §7 -- per-user, multi-list
-- equivalent of Wishlist (a chef's per-job equipment/ingredient lists, e.g.
-- "Hero's Birthday"). Two differences from wishlists drive the shape:
--   1. Grouping -- many named lists per user, so there's a projects parent
--      table wishlists doesn't need.
--   2. Quantity -- project_items carries a quantity (like cart_items), not a
--      binary in/out flag (like wishlists).
-- Prices are NOT snapshotted onto project_items -- same live-join philosophy
-- as wishlists (joins out to product_variants on every read). A project is a
-- running plan, not a receipt (contrast order_items, which does snapshot).

CREATE TABLE IF NOT EXISTS projects (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed')),
  event_date    TIMESTAMPTZ,
  client_name   TEXT,
  client_phone  TEXT,
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_projects_user_status
  ON projects(user_id, status);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS project_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  variant_id  UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity    INTEGER NOT NULL DEFAULT 1,
  added_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (project_id, variant_id)
);

CREATE INDEX IF NOT EXISTS idx_project_items_project
  ON project_items(project_id);

ALTER TABLE project_items ENABLE ROW LEVEL SECURITY;
