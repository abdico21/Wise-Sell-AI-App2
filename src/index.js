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
      !claims.sub || claims.sub.length > 128 || claims.exp <= now || claims.iat > now ||
      claims.auth_time > now) throw new Error("Firebase token claims are invalid or expired.");

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

// Extract SubjectPublicKeyInfo from the X.509 certificate using DER boundaries.
async function extractSpki(der) {
  const bytes = der;
  let p = 0;
  const readLen = () => {
    let n = bytes[p++];
    if (n < 128) return n;
    const count = n & 127; n = 0;
    for (let i = 0; i < count; i++) n = n * 256 + bytes[p++];
    return n;
  };
  if (bytes[p++] !== 0x30) throw new Error("Invalid certificate.");
  readLen();
  if (bytes[p++] !== 0x30) throw new Error("Invalid certificate.");
  readLen();
  if (bytes[p++] !== 0xA0) throw new Error("Invalid certificate.");
  const v = readLen(); p += v;
  if (bytes[p++] !== 0x02) throw new Error("Invalid certificate.");
  p += readLen();
  if (bytes[p++] !== 0x30) throw new Error("Invalid certificate.");
  p += readLen();
  if (bytes[p++] !== 0x30) throw new Error("Invalid certificate.");
  const tbsLength = readLen();
  const tbsStart = p;
  const tbsEnd = tbsStart + tbsLength;
  // Walk TBSCertificate fields to SubjectPublicKeyInfo (field 6 after optional version).
  let q = tbsStart;
  if (bytes[q] === 0xA0) { q++; let n=bytes[q++]; if(n&128){const c=n&127;n=0;for(let i=0;i<c;i++)n=n*256+bytes[q++];} q+=n; }
  for (let i=0;i<5;i++) { q++; let n=bytes[q++]; if(n&128){const c=n&127;n=0;for(let j=0;j<c;j++)n=n*256+bytes[q++];} q+=n; }
  const start = q;
  if (bytes[start] !== 0x30 || start >= tbsEnd) throw new Error("Certificate public key is malformed.");
  let n = bytes[start+1], head = 2;
  if (n & 128) { const c=n&127; n=0; for(let i=0;i<c;i++) n=n*256+bytes[start+head++]; }
  const end = start + head + n;
  return bytes.slice(start, end);
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

    if (url.pathname.startsWith("/api/agents/") && request.method === "POST") {
      const projectId = env.FIREBASE_PROJECT_ID;
      if (!projectId) return json({ error: "Firebase project ID is not configured." }, 503, origin);
      let user;
      try { user = await firebaseUser(request, projectId); }
      catch (e) { return json({ error: "Authentication failed", detail: e.message }, 401, origin); }
      if (!env.AI) return json({ error: "Cloudflare Workers AI binding is not configured.", uid: user.uid }, 503, origin);

      const id = url.pathname.slice("/api/agents/".length);
      const agent = AGENTS.find(a => a.id === id);
      if (!agent) return json({ error: "Unknown agent." }, 404, origin);
      let body;
      try { body = await request.json(); } catch { return json({ error: "Request body must be valid JSON." }, 400, origin); }
      const message = typeof body.message === "string" ? body.message.trim() : "";
      if (!message || message.length > 8000) return json({ error: "Provide a message of 1–8000 characters." }, 400, origin);
      try {
        const result = await env.AI.run("@cf/google/gemma-4-26b-a4b-it", {
          messages: [
            { role: "system", content: `You are ${agent.name} in Wise Sell AI. ${agent.instruction} The signed-in user's ID is ${user.uid}. Do not claim access to external accounts, business records, payments or social platforms unless provided in this request.` },
            { role: "user", content: message }
          ],
          max_tokens: 700
        });
        const answer = result.response || result.choices?.[0]?.message?.content || result.output_text || "";
        if (!answer) return json({ error: "The AI model returned an empty response." }, 502, origin);
        return json({ ok: true, agent: agent.id, answer, provider: "Cloudflare Workers AI" }, 200, origin);
      } catch (e) {
        return json({ error: "Cloudflare Workers AI request failed.", detail: e.message }, 502, origin);
      }
    }
    return json({ error: "Not found" }, 404, origin);
  }
};
