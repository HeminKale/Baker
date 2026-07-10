import { createMiddleware } from "npm:hono/factory";
import { Ratelimit } from "npm:@upstash/ratelimit";
import { Redis } from "npm:@upstash/redis";

let ratelimit: Ratelimit | null = null;

function getRatelimit(): Ratelimit | null {
  const url = Deno.env.get("UPSTASH_REDIS_REST_URL");
  const token = Deno.env.get("UPSTASH_REDIS_REST_TOKEN");
  if (!url || !token) return null; // secrets not set yet -- no-op rather than fail closed

  if (!ratelimit) {
    ratelimit = new Ratelimit({
      redis: new Redis({ url, token }),
      limiter: Ratelimit.slidingWindow(20, "1m"),
    });
  }
  return ratelimit;
}

// Applied to /v1/auth/* -- OTP/login spam is the concrete risk called out in
// backend_stack.md §14. Other routes get their own limiter when they exist.
export const rateLimitMiddleware = createMiddleware(async (c, next) => {
  const limiter = getRatelimit();
  if (!limiter) {
    await next();
    return;
  }

  const ip = c.req.header("x-forwarded-for") ?? "anonymous";
  const { success } = await limiter.limit(ip);
  if (!success) {
    return c.json({ error: { code: "RATE_LIMITED", message: "Too many requests" } }, 429);
  }
  await next();
});
