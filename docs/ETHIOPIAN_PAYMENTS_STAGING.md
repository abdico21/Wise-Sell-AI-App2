# WiseSell AI — Ethiopian payment integration (staging)

## Implemented in this staging branch

- Authenticated Firebase-user payment initiation.
- Chapa v2 hosted checkout adapter, locked to test mode (`CHAPA_MODE=test` and a `CHAPA_TEST_` private key).
- This first pass uses one platform-level test merchant only; it is not yet a seller-by-seller merchant credential vault and is not linked to marketplace order fulfillment.
- ETB-only amount validation in integer minor units (minimum 100).
- D1-backed payment intent records, unique merchant references and per-user idempotency.
- Server-to-server Chapa verification before a payment can become `paid`.
- User ownership check on payment verification.
- Provider capability endpoint: `GET /api/payments/providers`.
- Checkout endpoint: `POST /api/payments/intents`.
- Verification endpoint: `POST /api/payments/{merchant_reference}/verify`.

A payment is not considered complete because a browser redirects, a client says success, or a provider initialization request succeeds. Only a successful verification response with matching amount and currency can set the intent to `paid`. This module does not yet fulfill marketplace orders, issue refunds, reconcile settlements, or process signed webhooks.

## Required Cloudflare staging setup

1. Create a Cloudflare D1 database named `wisesell-ai-payments-staging`.
2. Bind it to the staging Worker as `PAYMENT_DB` (D1 database binding).
3. Apply `migrations/0001_payment_intents.sql` to that D1 database.
4. Set Worker variable `CHAPA_MODE` to `test`.
5. Add the Chapa **test-mode private key** as Worker secret `CHAPA_PRIVATE_KEY` (the key must start with `CHAPA_TEST_`). Never put it in GitHub source, Android config, or chat.
6. Keep the existing `FIREBASE_PROJECT_ID` unchanged.
7. Deploy only the staging branch/workflow after confirming the GitHub Actions workflow targets this branch and the staging Worker service. The current worker workflow is configured for main pushes; do not merge this branch to main to deploy it.

The Worker deliberately returns HTTP 503 for checkout if the D1 binding or Chapa key is absent. This is fail-closed behavior, not a simulated payment.

## Client contract

`GET /api/payments/providers` returns available providers and setup state.

`POST /api/payments/intents` requires a Firebase ID token, JSON:
```json
{
  "provider": "chapa",
  "amountMinor": 12500,
  "currency": "ETB",
  "email": "buyer@example.com"
}
```
Also send a unique stable `Idempotency-Key` header (8–100 letters, digits, dot, underscore, colon or hyphen). Amount is in minor units; for example 12500 represents ETB 125.00. Reuse the same key for retries of the same checkout attempt.

A successful initialization returns a hosted `checkoutUrl` and `status: pending`. Open the returned HTTPS URL in the browser. After the customer returns, call:
```
POST /api/payments/{reference}/verify
Authorization: Bearer <Firebase ID token>
```
Fulfill an order only after this endpoint returns `payment.status: paid`. Keep the order's own status in the order service; this endpoint only verifies and records a payment intent.

## Important merchant scope

The Chapa credential is currently a single platform test merchant. Do not use this flow to collect seller proceeds, marketplace buyer payments, or customer orders. A production multi-merchant rollout needs per-business merchant onboarding, encrypted per-tenant credential storage, seller authorization, order linkage, webhook verification, settlement reconciliation and payout handling.

## Additional provider adapters

- **Telebirr direct merchant API:** not enabled. Requires an approved merchant account, current merchant integration credentials, callback/signature requirements and sandbox/live endpoint details from the official Ethio telecom developer portal.
- **CBE Birr direct merchant API:** not enabled. Requires the merchant integration agreement, API specification, credentials and test environment from CBE.
- Chapa may offer Telebirr as a payment method through its own checkout/charge products; that is still a Chapa transaction and does not mean the direct Telebirr merchant adapter is connected.

Do not mark Telebirr or CBE Birr as available until their own provider adapter, authentication, callback verification, duplicate-event handling and end-to-end sandbox tests have been implemented.

## Before production

- Use provider live credentials only after merchant onboarding and approval.
- Add signed webhook handling and event idempotency.
- Link verified payment intents to order IDs in a trusted backend transaction.
- Add refunds, reversals, expiry, settlement reconciliation and audit history.
- Confirm tax, fee, currency-minor-unit and receipt requirements with each provider.
- Test success, decline, cancellation, timeout, duplicate requests, duplicate callbacks, amount mismatch and cross-user access.
- Obtain explicit approval before any production deployment.
