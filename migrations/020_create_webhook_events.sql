-- Milestone 3 / Phase 3: webhook_events table
-- 00_common_architecture.md §4 -- idempotency ledger for inbound webhooks.
-- UNIQUE(source, event_id) makes a replayed Razorpay (later Shiprocket, Phase 4)
-- event a no-op: the handler inserts here first and bails if the row already
-- exists. §18 risk register "Webhook dedup prevents double-processing".

CREATE TABLE IF NOT EXISTS webhook_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source        TEXT NOT NULL,
  event_id      TEXT NOT NULL,
  payload       JSONB,
  processed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (source, event_id)
);

ALTER TABLE webhook_events ENABLE ROW LEVEL SECURITY;
