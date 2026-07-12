# Baker Ally — Infrastructure & Service Costing

> All prices in USD and INR (₹). Exchange rate used: 1 USD = ₹84.
> Last updated: July 2026
> Based on: 10,000 concurrent users, India region.

---

## Assumptions

| Parameter | Value |
|---|---|
| Monthly active users (MAU) | 10,000 |
| Daily orders | ~500 |
| Monthly orders | ~15,000 |
| Avg order value | ₹600 |
| Monthly GMV | ₹90,00,000 (~₹90 lakhs) |
| Product images in storage | ~2,000 images, ~4 GB |
| Emails/month | ~20,000 |
| Push notifications/month | ~60,000 |

---

## 1. Supabase (Database + Auth + Storage)

**Plan: Pro — $25/month (₹2,100/month)**

| Feature | Included in Pro |
|---|---|
| Postgres database | 8 GB included |
| Storage | 100 GB included |
| Auth (MAU) | 100,000 MAU included |
| Bandwidth | 250 GB included |
| Backups | Daily backups included |
| No pausing | Yes — free tier pauses, Pro does not |

**Verdict:** Pro plan covers Baker Ally comfortably at this scale. No overages expected.

**Monthly cost: $25 (₹2,100)**

---

## 2. Supabase Edge Functions (Backend Hosting)

**Cost: Included in Supabase Pro — ₹0 extra**

| Feature | Included in Pro |
|---|---|
| Edge Function invocations | 2,000,000/month included |
| Edge Function execution time | 400,000 GB-seconds/month |
| Global distribution | Yes — runs close to users |
| npm + Node.js compatibility | Yes — all packages work |

At 15,000 orders/month, each triggering ~5 function calls = 75,000 invocations/month. Well within the 2M free limit.

**Monthly cost: ₹0 (included in Supabase Pro)**

> This replaces Railway and saves ₹4,200–6,720/month compared to the previous plan.

---

## 3. Vercel (Admin Web Panel — Next.js)

**Plan: Hobby (free) → Pro if needed**

| Plan | Cost | Bandwidth | Builds |
|---|---|---|---|
| Hobby | Free | 100 GB | 6,000 min/month |
| Pro | $20/month | 1 TB | Unlimited |

Admin web is low traffic (only admin users). Free Hobby plan is sufficient unless you need team members or preview deployments.

**Monthly cost: $0 (free tier) → $20 (₹1,680) if Pro needed**

---

## 4. Payment Gateway

**No monthly fee on any gateway. Transaction-based only.**

### Gateway Comparison

| Gateway | UPI | Cards | Netbanking | International | Node SDK | Flutter SDK |
|---|---|---|---|---|---|---|
| **Razorpay** | 0% | 2% | 1.5–2% | 3% | Official | Official |
| **Cashfree** | 0% | 1.75% | 1.75% | 3% | Official | Official |
| **PhonePe PG** | 0% | Custom | Custom | N/A | None (raw HTTP) | None |
| **Stripe** | No UPI | 2% | N/A | 3–4.3% | Official | Official |

**Recommended: Razorpay** (best SDK, widest support). **Cashfree** saves 0.25% on cards at high volume.

### Cost Estimate at 15,000 orders/month, avg ₹600

| Scenario | Razorpay | Cashfree |
|---|---|---|
| 80% UPI (12,000 orders) | ₹0 | ₹0 |
| 20% card (3,000 × ₹600 × fee) | ₹36,000 (2%) | ₹31,500 (1.75%) |
| **Total/month** | **₹36,000** | **₹31,500** |

Switching to Cashfree at full scale saves ~₹4,500/month on card transactions.

Note: These are costs of doing business — they scale with revenue, not against it.

**Monthly cost: ~₹31,500–36,000 (varies with gateway and payment mix)**

---

## 5. Shiprocket (Shipping)

**No platform fee. You pay per shipment.**

Shiprocket charges per shipment based on weight and distance. Rates are negotiated at volume.

| Weight | Zone A (local) | Zone B (metro) | Zone C (rest of India) |
|---|---|---|---|
| 0–500g | ₹45–60 | ₹60–80 | ₹80–100 |
| 500g–1kg | ₹55–75 | ₹75–95 | ₹95–120 |

**Estimate at 15,000 orders/month, avg ₹70/shipment:**

| Item | Calculation | Monthly cost |
|---|---|---|
| Shipping fees | 15,000 × ₹70 | ₹10,50,000 |

This is passed on to the customer as delivery charges or absorbed in product margin. This is NOT a platform cost — Shiprocket is just the aggregator.

**Platform cost to Baker Ally: ₹0 (charges passed to end customer or seller)**

---

## 6. ~~Interakt (WhatsApp Business API)~~ — Removed (2026-07-12)

**Decision: no WhatsApp Business API integration.** Order-status communication is in-app notifications (§ Notification Architecture) + Firebase push (§7) only. Shiprocket sends its own WhatsApp/SMS delivery updates directly to the customer under its own account — that's the carrier's cost and integration, not Baker Ally's.

**Monthly cost: ₹0** (was budgeted ~₹8,000–10,000/month at full scale — fully avoided)

---

## 7. Firebase (FCM Push + Crashlytics)

**Cost: Free**

| Service | Plan | Cost |
|---|---|---|
| Firebase Cloud Messaging (FCM) | Free, no limits | ₹0 |
| Firebase Crashlytics | Free | ₹0 |

FCM has no cost regardless of volume. Sending 60,000 push notifications/month costs nothing.

**Monthly cost: ₹0**

---

## 8. Resend (Auth Email via Supabase SMTP)

**Plan: Free — always**

Resend is configured as Supabase Auth's SMTP provider — no custom email code. Only sends OTPs, magic links, and password resets. All order updates go via in-app + push, not email.

| Plan | Cost | Emails/month |
|---|---|---|
| Free | $0 | 3,000/month |

Monthly volume: ~2,000–2,500 emails (OTPs + resets). Free tier never exceeded.

**Monthly cost: ₹0**

---

## 9. Codemagic (Flutter CI/CD)

**Plan: Pay-as-you-go**

| Machine | Cost per minute |
|---|---|
| Mac mini M1 | $0.095/min |
| Mac Pro | $0.19/min |

A typical Flutter build (iOS + Android) takes ~15–20 minutes.

| Builds/month | Cost per build | Monthly cost |
|---|---|---|
| 30 builds (1/day) | ~$2 | ~$60 (₹5,040) |
| 60 builds (2/day) | ~$2 | ~$120 (₹10,080) |

Codemagic also has a free tier: 500 build minutes/month (covers ~25 builds).

**Monthly cost: $0 free tier → $60–120 (₹5,040–10,080) in active dev**

---

## 10. Apple Developer Account

**One-time annual cost: $99/year (₹8,316/year = ₹693/month)**

Required to:
- Publish to App Store
- Sign iOS builds on Codemagic

**Monthly amortised cost: ~₹700/month**

---

## 11. Google Play Console

**One-time fee: $25 (₹2,100) — lifetime, never recurring**

Required to publish to Play Store.

**Monthly cost: ₹0 (one-time only)**

---

## 12. Upstash Redis (Rate Limiting)

**Plan: Free**

| Plan | Cost | Requests/day |
|---|---|---|
| Free | $0 | 10,000/day |

Used only for rate limiting metadata — not caching. 10,000/day is sufficient for Baker Ally's traffic.

**Monthly cost: ₹0**

---

## 13. Sentry (Observability)

**Plan: Free**

| Plan | Cost | Errors/month |
|---|---|---|
| Free | $0 | 5,000 errors |

A payments app with no error tracking is blind. Sentry captures all unhandled Edge Function errors, payment failures, and slow transactions.

**Monthly cost: ₹0**

---

## 14. PostHog (Analytics)

**Plan: Free**

| Plan | Cost | Events/month |
|---|---|---|
| Free | $0 | 1,000,000 events |

Baker Ally at 10k MAU will generate well under 1M events/month.

**Monthly cost: ₹0**

---

## Complete Monthly Cost Summary

### MVP Stage (< 1,000 users, < 500 orders/month)

| Service | Cost |
|---|---|
| Supabase Pro (DB + Auth + Storage + Edge Functions) | ₹2,100 |
| Railway (replaced by Edge Functions) | ₹0 |
| Vercel | ₹0 |
| Razorpay | ~₹1,200 (est.) |
| Firebase | ₹0 |
| Resend (Free — Supabase SMTP) | ₹0 |
| Upstash Redis (rate limiting) | ₹0 |
| Sentry (error tracking) | ₹0 |
| Codemagic (Free tier) | ₹0 |
| Apple Developer | ₹700 |
| PostHog | ₹0 |
| **Total** | **~₹4,000/month** |

---

### Growth Stage (1,000–5,000 users, ~5,000 orders/month)

| Service | Cost |
|---|---|
| Supabase Pro (DB + Auth + Storage + Edge Functions) | ₹2,100 |
| Railway (replaced by Edge Functions) | ₹0 |
| Vercel | ₹0 |
| Razorpay | ~₹12,000 |
| Firebase | ₹0 |
| Resend (Free — Supabase SMTP) | ₹0 |
| Upstash Redis (rate limiting) | ₹0 |
| Sentry (error tracking) | ₹0 |
| Codemagic | ₹5,040 (Can be reduced to ₹1500)|
| Apple Developer | ₹700 |
| PostHog | ₹0 |
| **Total** | **~between ₹11,000/month and ₹19,840/month** |

---

### Full Scale (10,000 concurrent users, ~15,000 orders/month)

| Service | Cost |
|---|---|
| Supabase Pro (DB + Auth + Storage + Edge Functions) | ₹2,100 |
| Railway (replaced by Edge Functions)| ₹0  |
| Vercel | ₹1,680 |
| Razorpay | ~₹36,000 |
| Firebase | ₹0 |
| Resend (Free — Supabase SMTP) | ₹0 |
| Upstash Redis (rate limiting) | ₹0 |
| Sentry (error tracking) | ₹0 |
| Codemagic | ₹5,040 (can be reduced to ₹1500)|
| Apple Developer | ₹700 |
| PostHog | ₹0 |
| **Total** | **~ between ₹31,000/month and ₹45,520/month** |

> Note: Razorpay fees (₹36,000) are the dominant cost at scale and are a % of GMV — not a fixed infrastructure cost. They scale with revenue, not against it.

---



## One-Time Setup Costs

| Item | Cost |
|---|---|
| Apple Developer Account | $99 (₹8,316) |
| Google Play Console | $25 (₹2,100) |
| Domain name (bakerally.in) | ~₹1,000/year |
| **Total one-time** | **~₹11,416** |

---
## Cost as % of GMV

| Stage | Monthly GMV | Infra cost | Razorpay | Total cost | % of GMV |
|---|---|---|---|---|---|
| MVP | ₹3,00,000 | ₹2,800 | ₹1,200 | ₹4,000 | 1.33% |
| Growth | ₹30,00,000 | ₹7,840 | ₹12,000 | ₹19,840 | 0.66% |
| Full scale | ₹90,00,000 | ₹9,520 | ₹36,000 | ₹45,520 | 0.51% |

Infrastructure costs become a smaller % of GMV as you scale — a healthy sign.

---
### *GMV = Gross Merchandise Value

It is the total value of all orders placed through the platform in a month — before any fees, costs, or deductions.

How the number is calculated here:


15,000 orders/month  ×  ₹600 avg order value  =  ₹90,00,000/month
What GMV is NOT:

Term	Meaning
GMV ₹90 lakhs	Total value of goods ordered — what customers paid
Revenue	What Baker Ally actually keeps — if Baker Ally charges a commission or markup
Profit	Revenue minus all costs
Why it matters for costing:

Razorpay's fees are a % of GMV, not a fixed cost. At ₹90 lakhs GMV with 20% card payments:


₹90L × 20% card share × 2% fee = ₹36,000/month in payment gateway fees
