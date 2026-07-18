-- Milestone 6 / Phase 6: back-in-stock push notification trigger
--
-- Wishlisting an out-of-stock item is the "notify me" request (Milestone 6
-- plan deviation #3). When an admin restocks a variant (stock_qty goes from
-- 0/negative to positive, via PATCH /v1/admin/variants/:id/stock or the bulk
-- endpoint), this fires an async HTTP call to the internal notify-restock
-- route, which looks up wishlisters and sends pushes.
--
-- This replaces the architecture doc's heavier pgmq-queue-plus-cron-worker
-- design, which assumed reusing Milestone 4's cron worker -- that worker
-- doesn't exist since M4 (Shiprocket) is deferred. pg_net calling the Edge
-- Function directly is simpler and needs no unbuilt M4 infra.
-- Trade-off, accepted for v1: pg_net is fire-and-forget, no retry on failure.
--
-- MANUAL STEP REQUIRED AFTER RUNNING THIS MIGRATION (same precedent as
-- 6_JWT_create_custom_jwt_claims_hook.sql's "cannot be done via SQL alone"
-- note): store the shared secret in Supabase Vault so it never lands in this
-- file or git history -- a plain `ALTER DATABASE ... SET app.foo` custom GUC
-- was the original plan here, but Supabase's managed `postgres` role isn't a
-- real superuser and gets `permission denied to set parameter`, so this uses
-- Vault instead (already-enabled `supabase_vault` extension) --
--   SELECT vault.create_secret('<value>', 'internal_notify_secret');
-- and set the same value as the INTERNAL_NOTIFY_SECRET Edge Function secret
-- via `supabase secrets set INTERNAL_NOTIFY_SECRET=<value>`. Until the secret
-- exists in Vault, the trigger silently no-ops (see IF secret IS NULL below)
-- rather than failing every stock update.

CREATE EXTENSION IF NOT EXISTS pg_net;

-- SECURITY DEFINER so the function can read vault.decrypted_secrets (which
-- restricts direct access) regardless of which role's UPDATE fired the
-- trigger -- runs with the owning (migration-runner) role's privileges.
-- Every identifier is schema-qualified below, so search_path is locked down.
CREATE OR REPLACE FUNCTION public.notify_restock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  secret text;
BEGIN
  SELECT decrypted_secret INTO secret
  FROM vault.decrypted_secrets
  WHERE name = 'internal_notify_secret'
  LIMIT 1;

  IF secret IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := 'https://bpmtnsaebrnuoujwxfea.supabase.co/functions/v1/api/v1/internal/notify-restock',
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-internal-secret', secret),
    body := jsonb_build_object('variantId', NEW.id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_restock ON product_variants;

CREATE TRIGGER trg_notify_restock
  AFTER UPDATE OF stock_qty ON product_variants
  FOR EACH ROW
  WHEN (OLD.stock_qty <= 0 AND NEW.stock_qty > 0)
  EXECUTE FUNCTION public.notify_restock();
