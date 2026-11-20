import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const read = (path) => readFileSync(fileURLToPath(new URL(path, import.meta.url)), "utf8");
const mobile = read("../lib/features/agents/presentation/agent_hub_screen.dart");
const worker = read("../cloudflare/src/index.js");
const rules = read("../firestore.rules");

assert.match(mobile, /Uri\.parse\('\$_apiBaseUrl\/v1\/agent'\)/,
  "Flutter must call the Cloudflare POST /v1/agent endpoint.");
for (const field of ["agent", "prompt", "language"]) {
  assert.match(mobile, new RegExp("'" + field + "'\\s*:"), `Flutter request must send ${field}.`);
  assert.match(worker, new RegExp("body\\." + field + "\\b"), `Worker must read ${field}.`);
}
assert.match(worker, /url\.pathname !== "\/v1\/agent"/,
  "Worker route must remain POST /v1/agent.");
for (const agent of ["business", "marketing", "content", "seo", "social", "video", "inventory"]) {
  assert.match(worker, new RegExp("\\b" + agent + "\\s*:"), `Worker is missing the ${agent} agent.`);
}
assert.match(worker, /@cf\/google\/gemma-4-26b-a4b-it/,
  "Free-mode Cloudflare Workers AI model must be configured.");
assert.doesNotMatch(worker, /OPENAI_API_KEY|api\.openai\.com/,
  "Free mode must not depend on an OpenAI API key.");


assert.match(rules, /match \/marketplace_listings\//,
  "Firestore rules must include marketplace listings.");
assert.match(rules, /match \/marketplace_orders\//,
  "Firestore rules must include marketplace orders.");
assert.match(rules, /request\.resource\.data\.keys\(\)\.hasOnly\(/,
  "Marketplace orders must reject unexpected fields.");
assert.match(rules, /request\.resource\.data\.buyerUid == request\.auth\.uid/,
  "Only the authenticated buyer may create an order.");
assert.match(rules, /request\.resource\.data\.quantity <= get\(/,
  "Order quantity must be capped by listing stock.");
assert.match(rules, /request\.resource\.data\.total == request\.resource\.data\.quantity \* request\.resource\.data\.unitPrice/,
  "Order total must match quantity times unit price.");
assert.match(rules, /resource\.data\.status == 'requested'[\s\S]*request\.resource\.data\.status in \['accepted', 'rejected'\]/,
  "Requested orders may only be accepted or rejected.");
assert.match(rules, /resource\.data\.status == 'accepted'[\s\S]*request\.resource\.data\.status == 'completed'/,
  "Only accepted orders may be completed.");

console.log("WiseSell AI mobile/backend and marketplace security contracts verified.");
