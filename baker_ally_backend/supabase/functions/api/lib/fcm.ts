import { createSign } from "node:crypto";

// Raw FCM HTTP v1 API with a hand-rolled OAuth2 JWT from a Firebase service
// account key, rather than npm:firebase-admin -- avoids Node/Deno compat risk,
// same posture as this codebase's hand-rolled-signature style in razorpay.ts.
//
// FIREBASE_SERVICE_ACCOUNT_KEY holds the *entire* JSON key file downloaded
// from Firebase Console -> Project Settings -> Service Accounts, pasted
// verbatim as the secret value. JSON.parse handles the \n-escaped
// private_key field correctly as long as it's set that way (not re-escaped).

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

let cachedAccount: ServiceAccount | null = null;
let cachedToken: { token: string; expiresAt: number } | null = null;

function getServiceAccount(): ServiceAccount {
  if (!cachedAccount) {
    const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
    if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY not set");
    cachedAccount = JSON.parse(raw);
  }
  return cachedAccount!;
}

function base64url(bytes: Uint8Array | string): string {
  const arr = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let binary = "";
  for (const byte of arr) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** Exchanges the service account's signed JWT for a short-lived OAuth2
 *  access token (Google's standard server-to-server flow), cached until
 *  ~1 minute before expiry. */
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) {
    return cachedToken.token;
  }

  const account = getServiceAccount();
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const signature = createSign("RSA-SHA256").update(unsigned).sign(account.private_key);
  const jwt = `${unsigned}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`Firebase OAuth token request failed: ${res.status} ${await res.text()}`);
  }
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cachedToken = { token: data.access_token, expiresAt: now + data.expires_in };
  return data.access_token;
}

export async function sendPushNotification(params: {
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<{ ok: boolean; error?: string }> {
  const account = getServiceAccount();
  const accessToken = await getAccessToken();

  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify({
      message: {
        token: params.fcmToken,
        notification: { title: params.title, body: params.body },
        ...(params.data ? { data: params.data } : {}),
      },
    }),
  });

  if (!res.ok) {
    return { ok: false, error: await res.text() };
  }
  return { ok: true };
}
