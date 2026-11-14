const AGENTS = [
  { id: "business-manager", name: "AI Business Manager", instruction: "Help with business operations, task planning and authorized business records." },
  { id: "sales-marketing", name: "AI Sales & Marketing", instruction: "Create marketing plans, product descriptions and social content. Never publish or send without user approval." },
  { id: "marketplace", name: "Marketplace Agent", instruction: "Help prepare and compare listings. Never invent prices, stock or sellers." },
  { id: "payments-orders", name: "Payments & Orders Agent", instruction: "Help draft and summarize orders and invoices. Never claim payment success without verified provider data." },
  { id: "business-intelligence", name: "Business Intelligence Agent", instruction: "Analyze only data supplied by authorized connected sources. Label estimates clearly." },
  { id: "enterprise-services", name: "Enterprise Services Agent", instruction: "Help prepare support, partnership and supplier requests; route decisions to authorized staff." }
];

const json = (data, status = 200, origin = "*") => new Response(JSON.stringify(data), {
  status,
  headers: {
    "content-type": "application/json; charset=utf-8",
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "GET,POST,OPTIONS",
    "access-control-allow-headers": "Content-Type, Authorization",
    "vary": "Origin"
  }
});

const decode = (s) => Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(s.length / 4) * 4, "=")), c => c.charCodeAt(0));
let certCache;
let certExpiry = 0;

async function firebaseUser(request, projectId) {
  const auth = request.headers.get("Authorization") || "";
  if (!auth.startsWith("Bearer ")) throw new Error("A Firebase ID token is required.");
  const parts = auth.slice(7).split(".");
  if (parts.length !== 3) throw new Error("Invalid Firebase ID token.");
  const header = JSON.parse(new TextDecoder().decode(decode(parts[0])));
  const claims = JSON.parse(new TextDecoder().decode(decode(parts[1])));
  if (header.alg !== "RS256" || !header.kid) throw new Error("Unsupported token signature.");
  const now = Math.floor(Date.now() / 1000);
  if (claims.aud !== projectId || claims.iss !== `https://securetoken.google.com/${projectId}` ||
      typeof claims.sub !== "string" || !claims.sub || claims.sub.length > 128 ||
      !Number.isFinite(claims.exp) || !Number.isFinite(claims.iat) || !Number.isFinite(claims.auth_time) ||
      claims.exp <= now || claims.iat > now || claims.auth_time > now) throw new Error("Firebase token claims are invalid or expired.");

  if (!certCache || Date.now() > certExpiry) {
    const response = await fetch("https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com");
    if (!response.ok) throw new Error("Could not retrieve Firebase signing certificates.");
    certCache = await response.json();
    const maxAge = Number((response.headers.get("cache-control") || "").match(/max-age=(\d+)/)?.[1] || 300);
    certExpiry = Date.now() + maxAge * 1000;
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

// Extract SubjectPublicKeyInfo from the X.509 certificate using bounded DER parsing.
function readDerElement(bytes, offset) {
  if (offset < 0 || offset + 2 > bytes.length) throw new Error("Invalid certificate DER.");
  const tag = bytes[offset++];
  let length = bytes[offset++];
  if (length & 0x80) {
    const count = length & 0x7f;
    if (count === 0 || count > 4 || offset + count > bytes.length) throw new Error("Invalid certificate DER length.");
    length = 0;
    for (let i = 0; i < count; i++) length = length * 256 + bytes[offset++];
  }
  const start = offset;
  const elementEnd = start + length;
  if (elementEnd > bytes.length) throw new Error("Certificate element exceeds its bounds.");
  return { tag, start, end: elementEnd, next: elementEnd };
}

function extractSpki(der) {
  const certificate = readDerElement(der, 0);
  if (certificate.tag !== 0x30 || certificate.next !== der.length) throw new Error("Invalid X.509 certificate.");
  const tbs = readDerElement(der, certificate.start);
  if (tbs.tag !== 0x30 || tbs.next > certificate.end) throw new Error("Invalid TBSCertificate.");

  let offset = tbs.start;
  let field = readDerElement(der, offset);
  if (field.tag === 0xA0) {
    offset = field.next;
    field = readDerElement(der, offset);
  }

  const expectedTags = [0x02, 0x30, 0x30, 0x30, 0x30];
  for (const tag of expectedTags) {
    if (field.tag !== tag) throw new Error("Unexpected X.509 certificate field.");
    offset = field.next;
    field = readDerElement(der, offset);
  }
  if (field.tag !== 0x30 || field.next > tbs.end) throw new Error("Certificate public key is malformed.");
  return der.slice(offset, field.next);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin") || "*";
    if (request.method === "OPTIONS") return new Response(null, { headers: {
      "access-control-allow-origin": origin,
      "access-control-allow-methods": "GET,POST,OPTIONS",
      "access-control-allow-headers": "Content-Type, Authorization",
      "access-control-max-age": "86400"
    }});

    if (url.pathname === "/" || url.pathname === "/api/health") {
      return json({ ok: true, app: env.APP_NAME || "Wise Sell AI", service: "Cloudflare Worker API",
        integrations: { firebaseAuth: Boolean(env.FIREBASE_PROJECT_ID), cloudflareWorkersAI: Boolean(env.AI) } }, 200, origin);
    }
    if (url.pathname === "/api/agents" && request.method === "GET")
      return json({ agents: AGENTS.map(({id,name}) => ({id,name})) }, 200, origin);

    if ((url.pathname.startsWith("/api/agents/") || ["/api/ai/business-growth", "/api/ai/marketing-advisor", "/api/ai/lead-qualify"].includes(url.pathname)) && request.method === "POST") {
      const projectId = env.FIREBASE_PROJECT_ID;
      if (!projectId) return json({ error: "Firebase project ID is not configured." }, 503, origin);
      let user;
      try { user = await firebaseUser(request, projectId); }
      catch (e) { return json({ error: "Authentication failed", detail: e.message }, 401, origin); }
      if (!env.AI) return json({ error: "Cloudflare Workers AI binding is not configured.", uid: user.uid }, 503, origin);

      const legacyRoutes = {
        "/api/ai/business-growth": "business-manager",
        "/api/ai/marketing-advisor": "sales-marketing",
        "/api/ai/lead-qualify": "business-intelligence"
      };
      const id = legacyRoutes[url.pathname] || url.pathname.slice("/api/agents/".length);
      const agent = AGENTS.find(a => a.id === id);
      if (!agent) return json({ error: "Unknown agent." }, 404, origin);
      let body;
      try { body = await request.json(); } catch { return json({ error: "Request body must be valid JSON." }, 400, origin); }
      const message = (typeof body.message === "string" ? body.message.trim() : JSON.stringify(body)).slice(0, 8000);
      if (!message || message.length > 8000) return json({ error: "Provide a message of 1–8000 characters." }, 400, origin);
      try {
        const extractText = (value) => {
          if (typeof value === "string") return value.trim();
          if (!value || typeof value !== "object") return "";
          const direct = value.response ?? value.output_text ?? value.generated_text;
          if (typeof direct === "string" && direct.trim()) return direct.trim();
          const content = value.choices?.[0]?.message?.content ?? value.result?.choices?.[0]?.message?.content;
          if (typeof content === "string" && content.trim()) return content.trim();
          if (Array.isArray(content)) return content.map(part => typeof part === "string" ? part : part?.text || "").join("\\n").trim();
          if (Array.isArray(value.output)) return value.output.map(part => part?.text || part?.content || "").join("\\n").trim();
          if (typeof value.result === "string") return value.result.trim();
          if (value.result && value.result !== value) return extractText(value.result);
          return "";
        };
        const prompt = [
          { role: "system", content: `You are ${agent.name} in Wise Sell AI. ${agent.instruction} The signed-in user's ID is ${user.uid}. Do not claim access to external accounts, business records, payments or social platforms unless provided in this request. Answer helpfully and directly.` },
          { role: "user", content: message }
        ];
        let answer = "";
        let lastModelError = "";
        for (const model of ["@cf/google/gemma-4-26b-a4b-it", "@cf/meta/llama-3.1-8b-instruct"]) {
          try {
            const result = await env.AI.run(model, { messages: prompt, max_tokens: 700, temperature: 0.4 });
            answer = extractText(result);
            if (answer) break;
            lastModelError = `${model} returned no text`;
          } catch (modelError) {
            lastModelError = modelError?.message || String(modelError);
          }
        }
        if (!answer) return json({ error: "The AI service did not return text from either configured model. Please retry shortly.", detail: lastModelError || "Empty model response." }, 502, origin);
        if (legacyRoutes[url.pathname]) {
          const clean = answer.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
          let data;
          try { data = JSON.parse(clean); } catch { data = null; }
          if (url.pathname === "/api/ai/business-growth") {
            data = data && typeof data === "object" ? data : { executiveSummary: answer, financialHealthScore: 75, strategicRecommendations: [], scenarioSimulation: "Review the recommendations with your current business data.", urgentRisk: "Validate assumptions before making financial decisions." };
          } else if (url.pathname === "/api/ai/marketing-advisor") {
            data = data && typeof data === "object" ? data : { recommendation: answer, bottleneck: "Review campaign conversion data.", expectedCvrLift: "Not estimated", actionItems: [], adSpendAdjustment: "Do not change budgets until performance data is verified." };
          } else {
            data = data && typeof data === "object" ? data : { score: 0, tier: "Needs review", intent: answer, bantAnalysis: {} };
          }
          return json({ success: true, data, provider: "Cloudflare Workers AI" }, 200, origin);
        }
        return json({ ok: true, agent: agent.id, answer, provider: "Cloudflare Workers AI" }, 200, origin);
      } catch (e) {
        return json({ error: "Cloudflare Workers AI request failed.", detail: e.message }, 502, origin);
      }
    }
    return json({ error: "Not found" }, 404, origin);
  }
};
