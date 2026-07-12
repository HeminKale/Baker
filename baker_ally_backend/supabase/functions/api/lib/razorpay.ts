import Razorpay from "npm:razorpay";
import { createHmac, timingSafeEqual } from "node:crypto";
import { Buffer } from "node:buffer";

// Razorpay wiring (backend_stack.md §8). Test-mode keys this milestone --
// live keys are a Phase 7 swap. Secrets (RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET
// / RAZORPAY_WEBHOOK_SECRET) are set via `supabase secrets set`, same as the
// existing Upstash / Sentry secrets.

let client: Razorpay | null = null;

/** The public key id, safe to hand to the Flutter Razorpay SDK. */
export function razorpayKeyId(): string {
  return Deno.env.get("RAZORPAY_KEY_ID") ?? "";
}

/** Lazily built client -- keeps `deno check` / non-payment routes from needing
 *  the secret set. Throws only when a checkout actually tries to create an order. */
function getClient(): Razorpay {
  if (!client) {
    const keyId = Deno.env.get("RAZORPAY_KEY_ID");
    const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET");
    if (!keyId || !keySecret) {
      throw new Error("Razorpay secrets not set (RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET)");
    }
    client = new Razorpay({ key_id: keyId, key_secret: keySecret });
  }
  return client;
}

/** Creates a Razorpay order for `amountPaise`. Called after our own pending
 *  `orders` row exists, so `receipt` ties the two together. */
export async function createRazorpayOrder(amountPaise: number, receipt: string) {
  return await getClient().orders.create({
    amount: amountPaise,
    currency: "INR",
    receipt,
  });
}

function safeEqualHex(a: string, b: string): boolean {
  const bufA = Buffer.from(a, "hex");
  const bufB = Buffer.from(b, "hex");
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

/** Verifies the payment signature Flutter returns after a successful payment:
 *  HMAC-SHA256(keySecret, `${orderId}|${paymentId}`) === signature. */
export function verifyPaymentSignature(
  razorpayOrderId: string,
  razorpayPaymentId: string,
  razorpaySignature: string,
): boolean {
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET");
  if (!keySecret) return false;
  const expected = createHmac("sha256", keySecret)
    .update(`${razorpayOrderId}|${razorpayPaymentId}`)
    .digest("hex");
  return safeEqualHex(expected, razorpaySignature);
}

/** Verifies an inbound webhook: HMAC-SHA256(webhookSecret, rawBody) === signature.
 *  Must be given the RAW request body, not a re-serialized JSON object. */
export function verifyWebhookSignature(rawBody: string, signature: string): boolean {
  const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET");
  if (!webhookSecret) return false;
  const expected = createHmac("sha256", webhookSecret).update(rawBody).digest("hex");
  return safeEqualHex(expected, signature);
}
