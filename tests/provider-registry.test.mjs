import test from "node:test";
import assert from "node:assert/strict";
import { listPaymentProviders } from "../src/payments/provider-registry.js";

const telebirrSandboxEnv = {
  TELEBIRR_FABRIC_APP_KEY: "test-app-key",
  TELEBIRR_APP_SECRET: "test-app-secret",
  TELEBIRR_MERCHANT_APP_ID: "test-merchant-app-id",
  TELEBIRR_MERCHANT_CODE: "123456",
  TELEBIRR_SIGNING_KEY: "test-private-key-placeholder",
  TELEBIRR_VERIFYING_CERT: "test-certificate-placeholder",
};

test("all payment providers remain disabled with no configuration", () => {
  const providers = listPaymentProviders({});
  assert.equal(providers.length, 2);
  assert.ok(providers.every((provider) => provider.enabled === false));
  assert.equal(providers.find((provider) => provider.id === "telebirr").readiness, "not-configured");
  assert.equal(providers.find((provider) => provider.id === "cbe-birr").readiness, "official-merchant-api-spec-required");
});

test("Telebirr reports configuration present only when every required value exists", () => {
  const incomplete = listPaymentProviders({ TELEBIRR_FABRIC_APP_KEY: "present" });
  assert.equal(incomplete.find((provider) => provider.id === "telebirr").readiness, "not-configured");

  const complete = listPaymentProviders(telebirrSandboxEnv);
  assert.equal(complete.find((provider) => provider.id === "telebirr").readiness, "credentials-present-adapter-review-required");
  assert.equal(complete.find((provider) => provider.id === "telebirr").enabled, false);
});

test("CBE Birr stays blocked even when arbitrary environment values are supplied", () => {
  const providers = listPaymentProviders({ CBE_BIRR_API_KEY: "must-not-enable" });
  const cbe = providers.find((provider) => provider.id === "cbe-birr");
  assert.equal(cbe.readiness, "official-merchant-api-spec-required");
  assert.equal(cbe.enabled, false);
});
