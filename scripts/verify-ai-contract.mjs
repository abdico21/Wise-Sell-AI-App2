import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const read = (path) => readFileSync(fileURLToPath(new URL(path, import.meta.url)), "utf8");
const mobile = read("../lib/features/agents/presentation/agent_hub_screen.dart");
const worker = read("../cloudflare/src/index.js");

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
assert.match(worker, /@cf\/meta\/llama-3\.1-8b-instruct/,
  "Free-mode Cloudflare Workers AI model must be configured.");
assert.doesNotMatch(worker, /OPENAI_API_KEY|api\.openai\.com/,
  "Free mode must not depend on an OpenAI API key.");

console.log("WiseSell AI mobile/backend contract verified (7 agents, Cloudflare Workers AI free mode).");
