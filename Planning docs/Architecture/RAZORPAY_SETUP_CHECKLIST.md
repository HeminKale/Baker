# Razorpay Setup Checklist for Baker Ally

**What you need to do RIGHT NOW to enable Milestone 3 payments.**

---

## ✅ Step 1: Create Razorpay Account

### Action
Go to https://razorpay.com and sign up

### What They'll Ask
- Business name: **Baker Ally**
- Business email: **mordeomkar89@gmail.com** (your registered email)
- Phone number: Your phone
- Business type: **Bakery/Food Supply Marketplace** (or similar)
- Expected monthly volume: **~₹50,000–100,000** (Phase 1 estimate)

### After Signup
You'll land in the **Test Mode dashboard** (default).

---

## ✅ Step 2: Generate Test API Keys

### Action
1. Razorpay Dashboard → **Settings** (gear icon, top right)
2. Click **API Keys**
3. Click **Generate Test Key**
4. You'll see two values:

```
Key ID:      rzp_test_xxxxxxxxxxxx   (copy this)
Key Secret:  xxxxxxxxxxxxxxxxxxxxxxxx (save securely, shown once)
```

### Save These Immediately
Open a notes app (Google Keep, Notepad, password manager) and save:
```
Test Key ID:     rzp_test_xxxxxxxxxxxx
Test Key Secret: xxxxxxxxxxxxxxxxxxxxxxxx
Test Status:     ACTIVE ✓
```

**WARNING:** Key Secret is shown only once. If you lose it, delete it and generate a new one.

---

## ✅ Step 3: Generate Webhook Secret

### Action
1. Still in **Settings → API Keys** page
2. Scroll down to **Webhooks**
3. Click **Add New Webhook**
4. Fill in:

| Field | Value |
|---|---|
| **Webhook URL** | `https://<your-project-ref>.supabase.co/functions/v1/api/v1/webhooks/razorpay` |
| **Webhook Secret** | (You create this — any strong random string) |
| **Active Events** | Check: `payment.failed` and `payment.captured` |

### Generate a Webhook Secret
Use a password generator or this command:
```bash
# On Mac/Linux
openssl rand -base64 32

# On Windows (PowerShell)
[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([guid]::NewGuid().ToString())) | Out-String
```

**Example output:**
```
gPq7nK2jL9mZ3vF5bR8wX4yT6cD1eH2jK9sA0pQ3uV5xZ7bN2nM4tW8qL0sE3rF
```

Copy this and paste into Razorpay **Webhook Secret** field.

### Webhook URL Format
Replace `<your-project-ref>` with your Supabase project ID:

**Example:**
```
https://ajpqrstuabcd1234.supabase.co/functions/v1/api/v1/webhooks/razorpay
```

(You'll get your project ref from Supabase dashboard.)

---

## ✅ Step 4: Collect All Three Secrets

Now you have:

```
1. RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx
2. RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxxxxx
3. RAZORPAY_WEBHOOK_SECRET=gPq7nK2jL9mZ3vF5bR8wX4yT6cD1eH2jK9sA0pQ3uV5xZ7bN2nM4tW8qL0sE3rF
```

**Keep these safe.** You'll need them in 5 minutes.

---

## ✅ Step 5: Set Supabase Secrets

### Action
Open terminal and run:

```bash
cd "C:\Users\hemin\OneDrive\Desktop\Android Project"

supabase secrets set RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx
supabase secrets set RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxxxxx
supabase secrets set RAZORPAY_WEBHOOK_SECRET=gPq7nK2jL9mZ3vF5bR8wX4yT6cD1eH2jK9sA0pQ3uV5xZ7bN2nM4tW8qL0sE3rF
```

Replace the values with your actual keys from Step 2 & 3.

### Verify They're Set
```bash
supabase secrets list
```

Output should show:
```
RAZORPAY_KEY_ID              (value hidden)
RAZORPAY_KEY_SECRET          (value hidden)
RAZORPAY_WEBHOOK_SECRET      (value hidden)
```

---

## ✅ Step 6: Redeploy Backend

The backend code already has the Razorpay integration built in (Milestone 3). Now deploy it with the new secrets:

```bash
cd "C:\Users\hemin\OneDrive\Desktop\Android Project"
supabase functions deploy api
```

Wait for the deployment to complete (should say "✓ Deployed").

---

## ✅ Step 7: Test in Razorpay Dashboard

### Action
Go back to Razorpay Dashboard → **Test Mode** and look for:

```
✓ API Keys set
✓ Webhooks configured
✓ Test payments ready
```

Click the **Test Payment** button to verify your setup works.

---

## ✅ Test Payment Methods

Now you can test actual payments. Use these test credentials:

### UPI
```
Phone: 9999999999
UPI: success@razorpay
Result: Success (auto-captures)
```

### Credit/Debit Card
```
Card Number: 4111 1111 1111 1111
Expiry: Any future month/year (e.g., 12/30)
CVV: Any 3 digits (e.g., 123)
OTP: 111111 (if asked)
Result: Success (auto-captures)
```

### Netbanking
```
Bank: Select any (HDFC, ICICI, Axis, etc.)
Username: testuser
Password: Test@123
Result: Success (auto-captures)
```

**Test these in the Flutter app once deployed.**

---

## ✅ Live Keys (Phase 7 — NOT NOW)

When you're ready for production (Phase 7):

1. Complete KYC verification in Razorpay Dashboard
2. Switch from **Test Mode** to **Live Mode**
3. Generate **Live API Keys**
4. Run:
   ```bash
   supabase secrets set RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxx
   supabase secrets set RAZORPAY_KEY_SECRET=live_secret_xxxxxxxxxxxx
   ```
5. Redeploy: `supabase functions deploy api`

**Code changes: ZERO** — same verification logic works for both test and live.

---

## 📋 Checklist Summary

- [ ] Create Razorpay account at https://razorpay.com
- [ ] Generate Test API Keys (copy both Key ID + Key Secret)
- [ ] Create Webhook Secret (random string)
- [ ] Configure Webhook in Razorpay Dashboard with your Supabase URL
- [ ] Set 3 Supabase secrets via CLI
- [ ] Redeploy backend: `supabase functions deploy api`
- [ ] Verify in Razorpay Dashboard that keys + webhook are active
- [ ] Test with UPI/Card/Netbanking test methods
- [ ] Deploy Flutter app with Milestone 3 code
- [ ] Test end-to-end checkout flow locally

---

## 🚫 Do NOT Follow FlutterFlow Guide

The FlutterFlow guide (https://docs.flutterflow.io/integrations/payments/razorpay/) is for their no-code platform:
- It shows FlutterFlow's UI for Razorpay config
- We don't use FlutterFlow — we're pure Flutter + Supabase backend
- Our setup is already built into Milestone 3 code

**What we DO follow from their guide:**
- ✅ Create test API keys
- ✅ Test payments before production
- ✅ Swap to live mode for release
- ✅ Use amount in paise (smallest unit)

**What we DON'T need from their guide:**
- ❌ FlutterFlow Razorpay action/integration blocks
- ❌ FlutterFlow conditional logic (we use Flutter code)
- ❌ FlutterFlow's cloud backend (we use Supabase Edge Functions)

---

## 🎯 Timeline

1. **Now** (5 mins): Sign up for Razorpay, get test keys
2. **Next 5 mins**: Set Supabase secrets
3. **Next 10 mins**: Redeploy backend
4. **Next 15 mins**: Test checkout flow in Flutter app
5. **After testing**: Ready to move to Phase 4 (Shiprocket integration)

---

## Questions?

**If you get stuck:**
- Razorpay Support: https://razorpay.com/support
- Supabase Docs: https://supabase.com/docs
- Baker Ally Manual Steps: See `Milestone 3 manual steps.md` in this folder

---

## Quick Command Cheat Sheet

```bash
# Go to project
cd "C:\Users\hemin\OneDrive\Desktop\Android Project"

# Set secrets (one at a time or all at once)
supabase secrets set RAZORPAY_KEY_ID=rzp_test_xxxxx
supabase secrets set RAZORPAY_KEY_SECRET=xxxxx
supabase secrets set RAZORPAY_WEBHOOK_SECRET=xxxxx

# Verify secrets are set
supabase secrets list

# Redeploy backend with new secrets
supabase functions deploy api

# Check deployment succeeded
supabase functions list
```

**That's it! You're ready to test payments.**
