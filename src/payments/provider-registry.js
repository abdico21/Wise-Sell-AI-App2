// Provider registry for WiseSell AI. This module is deliberately fail-closed.
// Provider-specific network calls belong in separately reviewed adapters.
// Never put merchant secrets or private keys in this file or in client code.

const PROVIDERS = Object.freeze({
  telebirr: Object.freeze({
    id: "telebirr",
    name: "Telebirr",
    currency: "ETB",
    integration: "h5-c2b-hosted-checkout",
    readinessEnv: ["TELEBIRR_FABRIC_APP_KEY", "TELEBIRR_APP_SECRET", "TELEBIRR_MERCHANT_APP_ID", "TELEBIRR_MERCHANT_CODE", "TELEBIRR_SIGNING_KEY", "TELEBIRR_VERIFYING_CERT"],
  }),
  "cbe-birr": Object.freeze({
    id: "cbe-birr",
    name: "CBE Birr",
    currency: "ETB",
    integration: "direct-merchant-api",
    readinessEnv: ["CBE_BIRR_API_BASE_URL", "CBE_BIRR_MERCHANT_ID", "CBE_BIRR_API_KEY", "CBE_BIRR_WEBHOOK_SECRET"],
  }),
});

function isConfigured(provider, env) {
  return provider.readinessEnv.every((key) =>
    typeof env[key] === "string" && env[key].trim().length > 0
  );
}

export function listPaymentProviders(env = {}) {
  return Object.values(PROVIDERS).map((provider) => ({
    id: provider.id,
    name: provider.name,
    currency: provider.currency,
    enabled: false,
    readiness: isConfigured(provider, env) ? "credentials-present-adapter-review-required" : "not-configured",
  }));
}

export function getPaymentProvider(providerId) {
  return Object.prototype.hasOwnProperty.call(PROVIDERS, providerId)
    ? PROVIDERS[providerId]
    : null;
}
