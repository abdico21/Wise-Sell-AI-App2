# WiseSell AI — Provider-Neutral Payments Architecture (Staging)

## Scope and safety

This document defines the staging-only foundation for direct Ethiopian payment-provider integrations. Chapa is not supported. Production branches and production deployments must remain unchanged.

Initial providers:
- **Telebirr** — direct Ethio Telecom merchant integration, starting with H5 C2B hosted checkout.
- **CBE Birr** — direct Commercial Bank of Ethiopia merchant integration, pending the merchant-specific API specification and sandbox credentials from CBE.

No payment is enabled by this design until merchant onboarding, sandbox credentials, callback verification material, persistence, and end-to-end sandbox tests are complete. Do not collect card PINs, wallet PINs, OTPs, or passwords in WiseSell AI.

## Common provider contract

Every provider adapter must implement the same conceptual operations:

- `createCheckout({ merchantReference, amountMinor, currency, description, callbackUrl, returnUrl })`
- `verifyCallback({ headers, rawBody })`
- `queryTransaction({ merchantReference, providerReference })`
- `normalizeStatus(providerPayload)`

Amounts are integer minor units (ETB cents); never use floating-point arithmetic for money. Provider credentials and private signing keys live only in Worker secrets. A provider adapter must fail closed when required configuration is missing.

## Canonical payment lifecycle

`CREATED → PENDING → SUCCEEDED | FAILED | EXPIRED | CANCELLED`

- A browser redirect is not proof of payment.
- Only a cryptographically verified provider callback or an authenticated server-to-server status query may move a payment to a terminal state.
- Compare provider amount, currency, merchant reference, merchant account, and provider transaction ID against the stored intent before accepting success.
- Make callbacks idempotent; duplicate callbacks must not create duplicate orders or ledger entries.
- Keep an append-only event/audit trail. Never overwrite a successful payment with a later pending/failed callback.
- Do not mark an order paid based on a client-supplied status.

## Proposed authenticated API

- `GET /api/payments/providers` — show provider name, currency, and readiness (never expose credentials).
- `POST /api/payments/intents` — create an authenticated user's payment intent for an existing order; server derives amount and ownership from the order record.
- `GET /api/payments/intents/:reference` — return only the authenticated owner's intent.
- `POST /api/payments/webhooks/telebirr` — public provider callback; validate signature and reconcile against stored intent.
- `POST /api/payments/webhooks/cbe-birr` — public provider callback; validate according to CBE's official callback-signature specification.

The webhook endpoints are intentionally not implemented until the official callback verification contract and durable storage are available. Do not create a public endpoint that trusts an unsigned callback.

## Telebirr — confirmed integration path

Ethio Telecom's official developer portal documents a C2B hosted checkout flow: the merchant backend obtains a Fabric token, creates a prepaid/unified order, receives a `prepay_id`, and redirects the customer to Telebirr checkout. Telebirr then notifies the merchant system of the result. Official developer documentation also provides other integration options and test-bed tools.

Required merchant onboarding/configuration (names are logical labels, not values):
- Fabric application key and app secret
- Merchant application ID and merchant code
- Merchant RSA signing key and the official Telebirr verification public key/certificate
- Sandbox and production base URLs supplied by Telebirr
- Public HTTPS callback URL and return URL
- Merchant settlement account and approved business profile

Implementation must follow the current official Telebirr signing, token, preorder, callback-verification, and query-order specifications exactly. Never infer cryptographic details from unofficial SDKs or copy test credentials from examples.

## CBE Birr — onboarding gate

CBE's official Merchant App listing describes merchant-initiated payment collection requests to CBE Birr customers. That is a documented merchant collection workflow, but it does not establish a public server-to-server API or webhook contract for WiseSell AI. The official app listing provides CBE support contacts (+251 965 183 828 and birukzegeju@cbe.com.et); CBE's official channel also describes merchant registration through a nearby branch and issuance of a Till Number.

Until CBE supplies a technical API contract, the code registry deliberately reports CBE Birr as `official-merchant-api-spec-required` and does not invent base URLs, API-key names, signatures, or callback schemas.

Before coding its adapter, obtain directly from CBE:
- Merchant integration guide and API version
- Sandbox base URL and merchant credentials
- Checkout/initiation and transaction-query request/response schemas
- Callback/webhook authentication and signature-verification rules
- Retry, timeout, idempotency, refund, and reconciliation behavior
- Settlement and merchant-account requirements

Do not guess endpoint URLs, authentication headers, signature algorithms, or callback fields. Until CBE supplies these materials, CBE Birr remains `not_configured`.

## Merchant onboarding checklist

**Telebirr**
- Register the business on the [Ethio Telecom Developer Portal](https://developer.ethiotelecom.et/user/product).
- Complete merchant/payment-product approval and obtain the assigned merchant credentials through the portal.
- Use the official H5 C2B guide and portal test-bed; confirm the exact callback verification and query-order requirements from the current API reference before coding.
- Keep sandbox and production credentials separate. WiseSell staging must receive sandbox credentials only.

**CBE Birr**
- Install the official [CBE Birr Merchant App](https://play.google.com/store/apps/details?id=prod.cbebirr.merchantapp) and complete CBE's merchant registration process if you need to collect payments manually while the API route is pending.
- Contact CBE through the support details published on the official app listing and request the merchant/API integration pack, sandbox access, webhook specification, and test merchant account.
- The merchant app is a manual merchant collection channel; it is not treated as an API integration in this codebase.

## Persistence requirements before enabling any payment

Use a dedicated staging D1 database (separate from production) with:
- `payment_intents`: unique merchant reference, owner UID, order ID, provider, amount_minor, currency, status, provider reference, timestamps
- `payment_events`: immutable event ID, intent reference, source, verification result, redacted payload digest, received timestamp
- Unique constraints on merchant reference and provider transaction ID
- Atomic conditional state transitions and indexes for owner/order/status lookups

Store no wallet PIN, OTP, full credential, or unnecessary personal data. Store only redacted provider metadata and payload digests for diagnostics.

## Release gates

1. Merchant onboarding and official specs obtained for each provider.
2. Separate staging secrets and staging D1 binding configured; no production secrets reused.
3. Unit tests for signing, callback verification, amount/currency matching, duplicate events, and invalid signatures.
4. Provider sandbox end-to-end test with a provider-issued test account.
5. Reconciliation test for a missed callback.
6. Security review and successful staging CI.
7. Explicit approval before any production work. This task does not authorize production changes or deployment.
