import { Hono } from "npm:hono";
import * as Sentry from "npm:@sentry/deno";

import { healthRoute } from "./routes/health.ts";
import { authRoute } from "./routes/auth.ts";
import { usersRoute } from "./routes/users.ts";
import { catalogRoute } from "./routes/catalog.ts";
import { wishlistRoute } from "./routes/wishlist.ts";

const sentryDsn = Deno.env.get("SENTRY_DSN");
if (sentryDsn) {
  Sentry.init({ dsn: sentryDsn, tracesSampleRate: 0.2 });
}

// Deployed as one Edge Function (`supabase functions deploy api`), reachable
// at https://<ref>.supabase.co/functions/v1/api/v1/... -- Flutter's
// API_BASE_URL points at the `.../api` part.
const app = new Hono().basePath("/api");

app.route("/v1", healthRoute);
app.route("/v1", authRoute);
app.route("/v1", usersRoute);
app.route("/v1", catalogRoute);
app.route("/v1", wishlistRoute);

app.onError((err, c) => {
  if (sentryDsn) Sentry.captureException(err);
  console.error(err);
  return c.json({ error: { code: "INTERNAL_ERROR", message: "Internal server error" } }, 500);
});

Deno.serve(app.fetch);
