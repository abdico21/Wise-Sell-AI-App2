var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// src/index.js
var AGENTS = [
  { id: "business-assistant", name: "AI Business Assistant", instruction: "Help with business planning, operations, cash-flow reasoning and decision support. Clearly label assumptions and never claim access to private business records unless provided." },
  { id: "sales-agent", name: "AI Sales Agent", instruction: "Help with sales strategy, lead qualification, customer conversations, objection handling and conversion. Never claim a sale or payment occurred." },
  { id: "digital-marketing", name: "Digital Marketing Agent", instruction: "Create practical digital campaign strategies, ad concepts, audience plans, channel recommendations and measurable KPIs. Never claim an ad was launched." },
  { id: "seo-content", name: "SEO & Content Marketing Agent", instruction: "Provide keyword research strategy, search intent analysis, technical and on-page SEO guidance, content briefs and editorial plans. Do not invent live ranking or traffic data." },
  { id: "social-media", name: "Social Media Agent", instruction: "Create platform-specific social posts, captions, hashtags and calendars. Never claim to publish, schedule or message on a social platform." },
  { id: "video-audio", name: "Video & Audio Marketing Agent", instruction: "Create video concepts, storyboards, scripts, voiceovers and audio ad scripts. Never claim to render or publish media." }
];
var json = /* @__PURE__ */ __name((data, status = 200, origin = "*") => new Response(JSON.stringify(data), {
  status,
  headers: {
    "content-type": "application/json; charset=utf-8",
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "GET,POST,OPTIONS",
    "access-control-allow-headers": "Content-Type, Authorization",
    "vary": "Origin"
  }
}), "json");
var decode = /* @__PURE__ */ __name((s) => Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(s.length / 4) * 4, "=")), (c) => c.charCodeAt(0)), "decode");
var certCache;
var certExpiry = 0;
async function firebaseUser(request, projectId) {
  const auth = request.headers.get("Authorization") || "";
  if (!auth.startsWith("Bearer ")) throw new Error("A Firebase ID token is required.");
  const parts = auth.slice(7).split(".");
  if (parts.length !== 3) throw new Error("Invalid Firebase ID token.");
  const header = JSON.parse(new TextDecoder().decode(decode(parts[0])));
  const claims = JSON.parse(new TextDecoder().decode(decode(parts[1])));
  if (header.alg !== "RS256" || !header.kid) throw new Error("Unsupported token signature.");
  const now = Math.floor(Date.now() / 1e3);
  if (claims.aud !== projectId || claims.iss !== `https://securetoken.google.com/${projectId}` || typeof claims.sub !== "string" || !claims.sub || claims.sub.length > 128 || !Number.isFinite(claims.exp) || !Number.isFinite(claims.iat) || !Number.isFinite(claims.auth_time) || claims.exp <= now || claims.iat > now || claims.auth_time > now) throw new Error("Firebase token claims are invalid or expired.");
  if (!certCache || Date.now() > certExpiry) {
    const response = await fetch("https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com");
    if (!response.ok) throw new Error("Could not retrieve Firebase signing certificates.");
    certCache = await response.json();
    const maxAge = Number((response.headers.get("cache-control") || "").match(/max-age=(\d+)/)?.[1] || 300);
    certExpiry = Date.now() + maxAge * 1e3;
  }
  const pem = certCache[header.kid];
  if (!pem) throw new Error("Firebase signing key was not found.");
  const b64 = pem.replace(/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s/g, "");
  const der = decode(b64);
  const cert = await crypto.subtle.importKey("spki", await extractSpki(der), { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"]);
  const valid = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", cert, decode(parts[2]), new TextEncoder().encode(parts[0] + "." + parts[1]));
  if (!valid) throw new Error("Firebase token signature is invalid.");
  return { uid: claims.sub, email: claims.email || null };
}
__name(firebaseUser, "firebaseUser");
function readDerElement(bytes, offset) {
  if (offset < 0 || offset + 2 > bytes.length) throw new Error("Invalid certificate DER.");
  const tag = bytes[offset++];
  let length = bytes[offset++];
  if (length & 128) {
    const count = length & 127;
    if (count === 0 || count > 4 || offset + count > bytes.length) throw new Error("Invalid certificate DER length.");
    length = 0;
    for (let i = 0; i < count; i++) length = length * 256 + bytes[offset++];
  }
  const start = offset;
  const elementEnd = start + length;
  if (elementEnd > bytes.length) throw new Error("Certificate element exceeds its bounds.");
  return { tag, start, end: elementEnd, next: elementEnd };
}
__name(readDerElement, "readDerElement");
function extractSpki(der) {
  const certificate = readDerElement(der, 0);
  if (certificate.tag !== 48 || certificate.next !== der.length) throw new Error("Invalid X.509 certificate.");
  const tbs = readDerElement(der, certificate.start);
  if (tbs.tag !== 48 || tbs.next > certificate.end) throw new Error("Invalid TBSCertificate.");
  let offset = tbs.start;
  let field = readDerElement(der, offset);
  if (field.tag === 160) {
    offset = field.next;
    field = readDerElement(der, offset);
  }
  const expectedTags = [2, 48, 48, 48, 48];
  for (const tag of expectedTags) {
    if (field.tag !== tag) throw new Error("Unexpected X.509 certificate field.");
    offset = field.next;
    field = readDerElement(der, offset);
  }
  if (field.tag !== 48 || field.next > tbs.end) throw new Error("Certificate public key is malformed.");
  return der.slice(offset, field.next);
}
__name(extractSpki, "extractSpki");
function offlineAgentAnswer(agentId, message) {
  const request = message.slice(0, 700).trim();
  const plans = {
    "business-assistant": ["Clarify the goal: improve profit, cash flow, stock control, or reduce costs.", "Record daily sales, expenses, cash balance, and stock quantities.", "Prioritize three actions with the highest expected business impact.", "Review actual results weekly against a measurable target."],
    "sales-agent": ["Identify the ideal buyer and the problem your product solves.", "Prepare one clear offer with price, benefit, availability, and delivery terms.", "Contact qualified prospects, ask what they need, and record objections.", "Follow up respectfully and track leads, conversion rate, and revenue."],
    "digital-marketing": ["Choose one objective: awareness, inquiries, store visits, or sales.", "Define the audience, offer, message, channel, and call to action.", "Prepare two creative variations and test them organically before spending money.", "Track reach, engagement, inquiries, conversion rate, and revenue."],
    "seo-content": ["Choose one page or product and define the search intent it should satisfy.", "Write a descriptive title, useful headings, clear product details, and a concise meta description.", "Add relevant internal links, descriptive image alt text, and a clear next step.", "Review indexing, impressions, clicks, and conversions in Search Console when connected."],
    "social-media": ["Choose the platform and audience most relevant to the product.", "Lead with a customer benefit, add a specific offer, and finish with one clear call to action.", "Prepare a short caption, a visual brief, and a small set of relevant hashtags.", "Publish only after the social account and permissions are connected; track inquiries and sales."],
    "video-audio": ["Open with a clear customer problem or benefit in the first few seconds.", "Show the product, explain its main benefit, and provide a practical example.", "Close with one call to action and contact or ordering instructions.", "Prepare captions, a shot list, and a voiceover script before recording."]
  };
  const titles = { "business-assistant": "Business action plan", "sales-agent": "Sales action plan", "digital-marketing": "Digital marketing plan", "seo-content": "SEO and content checklist", "social-media": "Social media content plan", "video-audio": "Video and audio production plan" };
  const actions = plans[agentId] || plans["business-assistant"];
  return [titles[agentId] || "Wise Sell AI action plan", "", "Your request: " + request, "", "Recommended steps:", ...actions.map((step, i) => i + 1 + ". " + step), "", "Track these results:", "- Activity completed", "- Customer inquiries or leads", "- Sales and revenue", "- Costs and profit", "", "This is the built-in zero-API fallback. It uses templates rather than a live AI model. Add your product, target customer, budget, and goal for a more specific plan."].join("\n");
}
__name(offlineAgentAnswer, "offlineAgentAnswer");
async function generateAgentAnswer(agent, user, message, env) {
  if (env.AI && typeof env.AI.run === "function") {
    try {
      const result = await env.AI.run(env.AI_MODEL || "@cf/google/gemma-4-26b-a4b-it", {
        messages: [
          {
            role: "system",
            content: "You are " + agent.name + " in WiseSell AI. " + agent.instruction + " The signed-in user's ID is " + user.uid + ". Give specific, practical, complete answers. For plans, include measurable actions and realistic targets. Do not claim access to connected accounts, business records, payments, or social platforms unless the request supplies that information. Never request passwords, API keys, payment-card details, or unnecessary personal data."
          },
          { role: "user", content: message }
        ],
        max_tokens: 1800,
        temperature: 0.4,
        chat_template_kwargs: { enable_thinking: false }
      });
      const answer = typeof result === "string" ? result :
        typeof result?.response === "string" ? result.response :
        typeof result?.choices?.[0]?.message?.content === "string" ? result.choices[0].message.content :
        typeof result?.output_text === "string" ? result.output_text : "";
      if (answer.trim()) {
        return { answer: answer.trim(), provider: "Cloudflare Workers AI (Gemma 4)", mode: "workers-ai" };
      }
      throw new Error("Workers AI returned an empty response.");
    } catch (e) {
      const reason = "Workers AI could not complete this request. The built-in template is being used instead.";
      return { answer: offlineAgentAnswer(agent.id, message) + "\\n\\nAI service notice: " + reason, provider: "Built-in zero-cost fallback", mode: "fallback", reason };
    }
  }
  return { answer: offlineAgentAnswer(agent.id, message), provider: "Built-in zero-cost fallback", mode: "fallback", reason: "The Cloudflare AI binding is not available in this deployment." };
}
__name(generateAgentAnswer, "generateAgentAnswer");
var index_default = {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin") || "*";
    if (request.method === "OPTIONS") return new Response(null, { headers: {
      "access-control-allow-origin": origin,
      "access-control-allow-methods": "GET,POST,OPTIONS",
      "access-control-allow-headers": "Content-Type, Authorization",
      "access-control-max-age": "86400"
    } });
    if (url.pathname === "/" || url.pathname === "/api/health") {
      return json({
        ok: true,
        app: env.APP_NAME || "Wise Sell AI",
        service: "Cloudflare Worker API",
        integrations: { firebaseAuth: Boolean(env.FIREBASE_PROJECT_ID), workersAI: Boolean(env.AI), zeroCostFallback: !env.AI, provider: env.AI ? "Cloudflare Workers AI (Gemma 4; free daily allocation subject to limits)" : "Built-in zero-cost fallback" }
      }, 200, origin);
    }
    if (url.pathname === "/api/agents" && request.method === "GET")
      return json({ agents: AGENTS.map(({ id, name }) => ({ id, name })) }, 200, origin);
    if ((url.pathname.startsWith("/api/agents/") || ["/api/ai/business-growth", "/api/ai/marketing-advisor", "/api/ai/lead-qualify"].includes(url.pathname)) && request.method === "POST") {
      const projectId = env.FIREBASE_PROJECT_ID;
      if (!projectId) return json({ error: "Firebase project ID is not configured." }, 503, origin);
      let user;
      try {
        user = await firebaseUser(request, projectId);
      } catch (e) {
        return json({ error: "Authentication failed", detail: e.message }, 401, origin);
      }
      const legacyRoutes = {
        "/api/ai/business-growth": "business-assistant",
        "/api/ai/marketing-advisor": "digital-marketing",
        "/api/ai/lead-qualify": "sales-agent"
      };
      const id = legacyRoutes[url.pathname] || url.pathname.slice("/api/agents/".length);
      const agent = AGENTS.find((a) => a.id === id);
      if (!agent) return json({ error: "Unknown agent." }, 404, origin);
      let body;
      try {
        body = await request.json();
      } catch {
        return json({ error: "Request body must be valid JSON." }, 400, origin);
      }
      const message = typeof body.message === "string" ? body.message.trim() : JSON.stringify(body);
      if (!message || message.length > 8e3) return json({ error: "Provide a message of 1\u20138000 characters." }, 400, origin);
      try {
        const generated = await generateAgentAnswer(agent, user, message, env);
        const answer = generated.answer;
        if (legacyRoutes[url.pathname]) {
          const clean = answer.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
          let data;
          try {
            data = JSON.parse(clean);
          } catch {
            data = null;
          }
          if (url.pathname === "/api/ai/business-growth") {
            data = data && typeof data === "object" ? data : { executiveSummary: answer, financialHealthScore: null, strategicRecommendations: [], scenarioSimulation: "Use the action plan and enter current business figures to evaluate scenarios.", urgentRisk: "Validate assumptions against actual records." };
          } else if (url.pathname === "/api/ai/marketing-advisor") {
            data = data && typeof data === "object" ? data : { recommendation: answer, bottleneck: "Review campaign conversion data.", expectedCvrLift: "Not estimated", actionItems: [], adSpendAdjustment: "No paid advertising budget is used by this zero-cost plan." };
          } else {
            data = data && typeof data === "object" ? data : { score: null, tier: "Needs review", intent: answer, bantAnalysis: {} };
          }
          return json({ success: true, data, provider: generated.provider, mode: generated.mode }, 200, origin);
        }
        return json({ ok: true, agent: agent.id, answer, provider: generated.provider, mode: generated.mode, ...generated.reason ? { notice: generated.reason } : {} }, 200, origin);
      } catch (e) {
        return json({ error: "Agent request failed.", detail: e.message }, 502, origin);
      }
    }
    return json({ error: "Not found" }, 404, origin);
  }
};
export {
  index_default as default
};
//# sourceMappingURL=index.js.map
