-- Milestone 6 / Phase 6: seed the 'staff' role
-- Admin panel v1 uses a simple Admin/Staff split (see Milestone 6 plan
-- deviation #2 -- the full Privilege Level editor stays deferred). The
-- existing JWT hook (6_JWT_create_custom_jwt_claims_hook.sql) already stamps
-- app_metadata.role from users.role_id -> roles.name automatically, so this
-- row is all that's needed for requireRole("staff") to work.

INSERT INTO roles (name) VALUES ('staff')
ON CONFLICT (name) DO NOTHING;
