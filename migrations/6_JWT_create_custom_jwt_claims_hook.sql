-- Milestone 1 / Phase 1: Custom Access Token (JWT) Claims hook
--
-- Writes the user's role name into app_metadata.role on every issued JWT, so
-- Hono's authMiddleware/adminMiddleware can read the role straight off the
-- token without a DB round trip (see baker_ally_backend/.../middleware/auth.ts).
--
-- MANUAL STEP REQUIRED AFTER RUNNING THIS MIGRATION:
-- Supabase Dashboard -> Authentication -> Hooks -> "Customize Access Token
-- (JWT) Claims" -> select this function (public.custom_access_token_hook).
-- This cannot be enabled via SQL alone.
--
-- Uses Supabase's actual Auth Hook contract: input/output is the full `event`
-- object with a `claims` key (not the simplified shape shown in
-- 00_common_architecture.md's example). jsonb_set on {app_metadata,role}
-- relies on Supabase always populating `app_metadata` by default on the
-- claims object -- true for every provider, including Google OAuth.

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  claims jsonb;
  role_name text;
BEGIN
  SELECT r.name INTO role_name
  FROM public.users u
  JOIN public.roles r ON r.id = u.role_id
  WHERE u.id = (event->>'user_id')::uuid;

  claims := event->'claims';

  IF role_name IS NOT NULL THEN
    claims := jsonb_set(claims, '{app_metadata,role}', to_jsonb(role_name), true);
  END IF;

  event := jsonb_set(event, '{claims}', claims);
  RETURN event;
END;
$$;

GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM authenticated, anon, public;
