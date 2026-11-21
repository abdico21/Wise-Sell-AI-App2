const AGENTS = [
  { id: "business-assistant", name: "AI Business Assistant", instruction: "Help with business planning, operations, cash-flow reasoning and decision support. Clearly label assumptions and never claim access to private business records unless provided." },
  { id: "sales-agent", name: "AI Sales Agent", instruction: "Help with sales strategy, lead qualification, customer conversations, objection handling and conversion. Never claim a sale or payment occurred." },
  { id: "digital-marketing", name: "Digital Marketing Agent", instruction: "Create practical digital campaign strategies, ad concepts, audience plans, channel recommendations and measurable KPIs. Never claim an ad was launched." },
  { id: "seo-content", name: "SEO & Content Marketing Agent", instruction: "Provide keyword research strategy, search intent analysis, technical and on-page SEO guidance, content briefs and editorial plans. Do not invent live ranking or traffic data." },
  { id: "social-media", name: "Social Media Agent", instruction: "Create platform-specific social posts, captions, hashtags and calendars. Never claim to publish, schedule or message on a social platform." },
  { id: "video-audio", name: "Video & Audio Marketing Agent", instruction: "Create video concepts, storyboards, scripts, voiceovers and audio ad scripts. Never claim to render or publish media." }
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

function offlineAgentAnswer(agentId, message) {
  const request = message.slice(0, 700).trim();
  if (agentId === "business-assistant" && /digital\s*marketing\s*agency|marketing\s*agency|digital\s*agency/i.test(request)) {
    const agencyPlan = [
      "30-DAY SALES GROWTH PLAN — DIGITAL MARKETING AGENCY (ETHIOPIA)",
      "",
      "Business focus: sell measurable marketing services to Ethiopian SMEs and growing organizations. Treat all targets below as planning goals, not guaranteed results.",
      "",
      "1. POSITIONING AND OFFER",
      "- Choose one or two priority customer groups to start: hotels and tourism businesses, real estate firms, clinics, private schools, retailers, restaurants, or professional services.",
      "- Lead with an outcome-focused offer: more qualified inquiries, stronger local search visibility, or consistent social content. Avoid promising guaranteed rankings or sales.",
      "- Package services clearly: (A) SEO and Google Business Profile improvement; (B) monthly Facebook/Instagram content and community management; (C) paid-ad campaign setup and optimization; (D) combined growth package with monthly reporting.",
      "- Quote in ETB after checking current delivery costs, staff time, taxes, payment fees and the client's budget. Separate your agency fee from the client's advertising spend.",
      "",
      "2. 30-DAY EXECUTION",
      "Days 1–7 — Build the sales foundation",
      "- Create a one-page portfolio with 2–3 real case studies. Label sample/demo work clearly; never invent client results.",
      "- Prepare a short service menu, discovery questions, proposal template and a simple monthly report.",
      "- Build a list of 30 qualified businesses in one or two sectors. Find public business contact channels and decision-makers; do not scrape private data.",
      "- Publish three useful posts showing a website/SEO audit tip, a social-content example and a measurable campaign lesson.",
      "Target by day 7: 30 qualified prospects listed, 10 personalized first contacts sent, 3 discovery conversations requested.",
      "",
      "Days 8–14 — Start conversations",
      "- Offer five short, no-obligation visibility or social-page audits using only publicly visible information.",
      "- For each prospect, identify one problem, show one example improvement and propose a 30-day pilot with clear deliverables.",
      "- Send tailored proposals within 24 hours of each qualified meeting and follow up once after 2–3 business days.",
      "- Use locally appropriate channels: phone, email, in-person business visits and WhatsApp only where the business publicly offers it and outreach is welcome.",
      "Target by day 14: 5 audits delivered, 3 proposals sent, and all leads recorded with a next follow-up date.",
      "",
      "Days 15–21 — Convert and deliver",
      "- Follow up on open proposals; ask about timing, decision process, budget range and the result the client values most.",
      "- Offer a small paid pilot rather than discounting a large package. Define scope, timeline, approvals and payment milestones in writing.",
      "- Onboarding checklist: business goal, audience, offer, brand assets, account access through secure role-based permissions, baseline metrics and approval contact.",
      "- Launch only after the client approves the plan and funds any advertising budget directly in the relevant platform account.",
      "Target by day 21: aim for 1–2 new paying clients; if none convert, review offer fit, proof, pricing and follow-up quality.",
      "",
      "Days 22–30 — Prove value and build referrals",
      "- Send each active client a concise weekly report: work completed, reach, clicks, inquiries, qualified leads, conversions, spend and next actions.",
      "- Compare results with the baseline; explain what can and cannot be attributed to the campaign.",
      "- Ask satisfied clients for a testimonial or one introduction, with permission.",
      "- Review which sector, service and outreach message produced the best qualified conversations; focus next month's prospecting there.",
      "Target by day 30: complete at least one client performance review, request two referrals where appropriate, and prepare a prioritized next-month pipeline.",
      "",
      "3. WEEKLY SALES SCORECARD",
      "- New qualified prospects; first contacts; replies; discovery meetings; audits; proposals; wins; lost deals and reasons.",
      "- Revenue invoiced and collected (ETB); recurring monthly revenue; delivery hours and costs; gross margin; overdue payments.",
      "- For campaigns: client-approved ad spend, impressions, clicks, inquiries, qualified leads, conversions and cost per lead. Do not treat reach or likes as sales.",
      "",
      "4. LOW-COST OPERATING RULES",
      "- Start with organic LinkedIn, Facebook and Instagram content, referrals, local business networks and direct, personalized outreach before spending on ads.",
      "- Use free spreadsheets and calendar reminders to manage prospects and reporting; keep client data access limited and obtain consent.",
      "- Keep client advertising budgets separate from agency operating cash. Do not pay ad spend from agency funds unless the contract explicitly covers it.",
      "- Do not promise specific revenue, ranking positions or lead volumes before validating the client's market, offer, website and budget.",
      "",
      "5. INFORMATION NEEDED TO PERSONALIZE THE FORECAST",
      "- Main city/region and target industry; core services; current number of clients; average monthly agency fee; monthly operating costs; available sales/marketing budget; team capacity.",
      "- Once these figures are supplied, calculate a realistic break-even client count, monthly revenue target and lead-to-client conversion goals. No business records are assumed to be connected.",
      "",
      "This response is generated by WiseSell AI's built-in zero-API template engine, not a live AI model. It does not contact prospects, launch campaigns or access social accounts."
    ];
    return agencyPlan.join("\n");
  }
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
  return [titles[agentId] || "Wise Sell AI action plan", "", "Your request: " + request, "", "Recommended steps:", ...actions.map((step, i) => (i + 1) + ". " + step), "", "Track these results:", "- Activity completed", "- Customer inquiries or leads", "- Sales and revenue", "- Costs and profit", "", "This is the built-in zero-API fallback. It uses templates rather than a live AI model. Add your product, target customer, budget, and goal for a more specific plan."].join("\n");
}

async function generateAgentAnswer(agent, user, message, env) {
  // Zero-cost mode is the default. OpenAI is called only after an explicit opt-in.
  if (env.AI_PROVIDER !== "openai") {
    return { answer: offlineAgentAnswer(agent.id, message), provider: "Built-in zero-cost fallback", mode: "fallback" };
  }
  if (!env.OPENAI_API_KEY) {
    return { answer: offlineAgentAnswer(agent.id, message), provider: "Built-in zero-cost fallback", mode: "fallback", reason: "OpenAI API key is not configured in the Worker." };
  }
  try {
    const model = env.OPENAI_MODEL || "gpt-4.1-mini";
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "authorization": "Bearer " + env.OPENAI_API_KEY
      },
      body: JSON.stringify({
        model,
        instructions: "You are " + agent.name + " in Wise Sell AI. " + agent.instruction + " The signed-in user's ID is " + user.uid + ". Do not claim access to external accounts, business records, payments or social platforms unless provided in this request. Answer helpfully and directly. Complete every requested section, use practical actions and measurable targets where useful, and finish with a complete sentence. Never request passwords, API keys, payment-card details, or unnecessary personal data.",
        input: message,
        max_output_tokens: 1800
      })
    });
    const data = await response.json().catch(() => ({}));
    const outputText = typeof data.output_text === "string" ? data.output_text :
      (Array.isArray(data.output) ? data.output.flatMap(item =>
        Array.isArray(item.content) ? item.content.filter(part => part.type === "output_text" && typeof part.text === "string").map(part => part.text) : []
      ).join("\n") : "");
    const answer = outputText.trim();
    if (!response.ok || !answer) {
      let reason;
      if (response.status === 400) reason = "OpenAI rejected the request configuration (HTTP 400). Check the configured model and request parameters.";
      else if (response.status === 401 || response.status === 403) reason = "OpenAI rejected the API key or its permissions (HTTP " + response.status + "). Check the OPENAI_API_KEY Worker secret.";
      else if (response.status === 429) reason = "OpenAI rate limit or project quota was reached (HTTP 429). Check the OpenAI project billing and usage limits.";
      else if (response.status >= 500) reason = "OpenAI is temporarily unavailable (HTTP " + response.status + ").";
      else if (response.ok) reason = "OpenAI returned no usable text. The response may have been incomplete or blocked.";
      else reason = "OpenAI request failed (HTTP " + response.status + ").";
      return { answer: offlineAgentAnswer(agent.id, message) + "\n\nOpenAI diagnostic: " + reason, provider: "Built-in zero-cost fallback", mode: "fallback", reason };
    }
    return { answer, provider: "OpenAI", mode: "openai" };
  } catch (e) {
    const reason = "The Worker could not reach OpenAI. Check network availability and retry; no API key is displayed.";
    return { answer: offlineAgentAnswer(agent.id, message) + "\n\nOpenAI diagnostic: " + reason, provider: "Built-in zero-cost fallback", mode: "fallback", reason };
  }
}

async function handlePaymentRoutes(request, env, url, origin) {
  if (url.pathname === "/api/payments/providers" && request.method === "GET") {
    return json({ ok: true, currency: "ETB", providers: [
      { id: "chapa", name: "Chapa", available: Boolean(env.CHAPA_PRIVATE_KEY && env.PAYMENT_DB), mode: env.CHAPA_PRIVATE_KEY && env.PAYMENT_DB ? "configured" : "needs_setup" },
      { id: "telebirr", name: "Telebirr", available: false, mode: "merchant_api_setup_required" },
      { id: "cbe_birr", name: "CBE Birr", available: false, mode: "merchant_api_setup_required" }
    ], note: "Only configured providers can initialize checkout. Provider listing does not mean a payment has been made." }, 200, origin);
  }
  if (url.pathname === "/api/payments/intents" && request.method === "POST") {
    let user;
    try {
      if (!env.FIREBASE_PROJECT_ID) throw new Error("Firebase project is not configured.");
      user = await firebaseUser(request, env.FIREBASE_PROJECT_ID);
    } catch (e) { return json({ ok: false, error: "Authentication failed", detail: e.message }, 401, origin); }
    if (!env.PAYMENT_DB) return json({ ok: false, error: "Payment database is not configured. Bind a Cloudflare D1 database as PAYMENT_DB before checkout." }, 503, origin);
    if (!env.CHAPA_PRIVATE_KEY) return json({ ok: false, error: "Chapa private key is not configured as a Cloudflare Worker secret." }, 503, origin);
    const body = await request.json().catch(() => null);
    if (!body || body.provider !== "chapa") return json({ ok: false, error: "Only the Chapa provider is currently implemented for checkout." }, 400, origin);
    const amount = Number(body.amountMinor);
    const currency = String(body.currency || "ETB").toUpperCase();
    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    const idempotencyKey = request.headers.get("Idempotency-Key") || "";
    if (!Number.isSafeInteger(amount) || amount < 100 || amount > 100000000000 || currency !== "ETB" ||
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
        !/^[A-Za-z0-9._:-]{8,100}$/.test(idempotencyKey)) {
      return json({ ok: false, error: "Provide amountMinor (integer >= 100), ETB currency, a valid email and an 8–100 character Idempotency-Key." }, 400, origin);
    }
    const reference = "WS" + Date.now().toString(36).toUpperCase() + crypto.randomUUID().replace(/-/g, "").slice(0, 8).toUpperCase();
    await env.PAYMENT_DB.prepare("INSERT INTO payment_intents (uid, provider, merchant_reference, idempotency_key, amount_minor, currency, customer_email, status, created_at, updated_at) VALUES (?, 'chapa', ?, ?, ?, ?, ?, 'initializing', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT(uid, idempotency_key) DO NOTHING")
      .bind(user.uid, reference, idempotencyKey, amount, currency, email).run();
    const row = await env.PAYMENT_DB.prepare("SELECT * FROM payment_intents WHERE uid = ? AND idempotency_key = ?").bind(user.uid, idempotencyKey).first();
    if (!row) return json({ ok: false, error: "Could not reserve payment request. Retry using the same idempotency key." }, 503, origin);
    if (row.merchant_reference !== reference || row.status !== "initializing") {
      return json({ ok: true, reused: true, payment: { reference: row.merchant_reference, status: row.status, checkoutUrl: row.checkout_url || null, amountMinor: row.amount_minor, currency: row.currency } }, 200, origin);
    }
    try {
      const response = await fetch("https://api.chapa.global/v2/payments/hosted", {
        method: "POST",
        headers: { "Authorization": "Bearer " + env.CHAPA_PRIVATE_KEY, "Content-Type": "application/json", "Idempotency-Key": idempotencyKey },
        body: JSON.stringify({ amount, currency, merchant_reference: reference, customer: { email }, meta: { app: "WiseSell AI", user_ref: user.uid.slice(0, 12) } })
      });
      const result = await response.json().catch(() => ({}));
      const checkoutUrl = result?.data?.checkout_url;
      if (!response.ok || result?.status !== "success" || typeof checkoutUrl !== "string" || !checkoutUrl.startsWith("https://")) {
        await env.PAYMENT_DB.prepare("UPDATE payment_intents SET status = 'failed', updated_at = CURRENT_TIMESTAMP WHERE merchant_reference = ? AND uid = ?").bind(reference, user.uid).run();
        return json({ ok: false, error: "Chapa could not initialize hosted checkout.", providerStatus: response.status, detail: result?.message || "No valid checkout URL returned." }, 502, origin);
      }
      await env.PAYMENT_DB.prepare("UPDATE payment_intents SET status = 'pending', checkout_url = ?, updated_at = CURRENT_TIMESTAMP WHERE merchant_reference = ? AND uid = ?").bind(checkoutUrl, reference, user.uid).run();
      return json({ ok: true, payment: { reference, status: "pending", checkoutUrl, amountMinor: amount, currency } }, 201, origin);
    } catch {
      await env.PAYMENT_DB.prepare("UPDATE payment_intents SET status = 'failed', updated_at = CURRENT_TIMESTAMP WHERE merchant_reference = ? AND uid = ?").bind(reference, user.uid).run();
      return json({ ok: false, error: "Unable to reach Chapa. No payment was confirmed." }, 502, origin);
    }
  }
  const match = url.pathname.match(/^\/api\/payments\/([^/]+)\/verify$/);
  if (match && request.method === "POST") {
    let user;
    try {
      if (!env.FIREBASE_PROJECT_ID) throw new Error("Firebase project is not configured.");
      user = await firebaseUser(request, env.FIREBASE_PROJECT_ID);
    } catch (e) { return json({ ok: false, error: "Authentication failed", detail: e.message }, 401, origin); }
    if (!env.PAYMENT_DB || !env.CHAPA_PRIVATE_KEY) return json({ ok: false, error: "Payment verification is not configured." }, 503, origin);
    const reference = decodeURIComponent(match[1]);
    if (!/^[A-Z0-9]{10,30}$/.test(reference)) return json({ ok: false, error: "Invalid payment reference." }, 400, origin);
    const row = await env.PAYMENT_DB.prepare("SELECT * FROM payment_intents WHERE merchant_reference = ? AND uid = ?").bind(reference, user.uid).first();
    if (!row) return json({ ok: false, error: "Payment reference not found for this account." }, 404, origin);
    if (row.status === "paid") return json({ ok: true, payment: { reference, status: "paid", amountMinor: row.amount_minor, currency: row.currency } }, 200, origin);
    const response = await fetch("https://api.chapa.global/v2/payments/" + encodeURIComponent(reference) + "/verify", { headers: { "Authorization": "Bearer " + env.CHAPA_PRIVATE_KEY } });
    const result = await response.json().catch(() => ({}));
    const data = result?.data || {};
    const providerStatus = String(data.status || "").toUpperCase();
    const paidAmount = Number(data.amount);
    const matches = response.ok && result?.status === "success" && providerStatus === "SUCCESS" &&
      Number.isSafeInteger(paidAmount) && paidAmount === Number(row.amount_minor) &&
      String(data.currency || "").toUpperCase() === row.currency && data.merchant_reference === reference;
    if (!matches) {
      const nextStatus = ["FAILED", "CANCELLED", "EXPIRED"].includes(providerStatus) ? "failed" : "pending";
      await env.PAYMENT_DB.prepare("UPDATE payment_intents SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE merchant_reference = ? AND uid = ?").bind(nextStatus, reference, user.uid).run();
      return json({ ok: true, payment: { reference, status: nextStatus }, note: "No matching successful provider verification. Do not fulfill the order." }, 200, origin);
    }
    await env.PAYMENT_DB.prepare("UPDATE payment_intents SET status = 'paid', provider_reference = ?, updated_at = CURRENT_TIMESTAMP WHERE merchant_reference = ? AND uid = ?")
      .bind(String(data.chapa_reference || data.processor_reference || reference), reference, user.uid).run();
    return json({ ok: true, payment: { reference, status: "paid", amountMinor: row.amount_minor, currency: row.currency }, verifiedBy: "Chapa server-to-server verification" }, 200, origin);
  }
  return null;
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
        integrations: { firebaseAuth: Boolean(env.FIREBASE_PROJECT_ID), openaiConfigured: env.AI_PROVIDER === "openai" && Boolean(env.OPENAI_API_KEY), zeroCostFallback: env.AI_PROVIDER !== "openai", provider: env.AI_PROVIDER === "openai" ? "OpenAI (paid API)" : "Built-in zero-cost fallback" } }, 200, origin);
    }
    if (url.pathname.startsWith("/api/payments/")) {\n      const paymentResponse = await handlePaymentRoutes(request, env, url, origin);\n      if (paymentResponse) return paymentResponse;\n    }\n\n    if (url.pathname === "/api/agents" && request.method === "GET")
      return json({ agents: AGENTS.map(({id,name}) => ({id,name})) }, 200, origin);

    if (url.pathname === "/api/agents/orchestrate" && request.method === "POST") {
      const projectId = env.FIREBASE_PROJECT_ID;
      if (!projectId) return json({ error: "Firebase project ID is not configured." }, 503, origin);
      let user;
      try { user = await firebaseUser(request, projectId); }
      catch (e) { return json({ error: "Authentication failed", detail: e.message }, 401, origin); }

      let body;
      try { body = await request.json(); } catch { return json({ error: "Request body must be valid JSON." }, 400, origin); }
      const message = typeof body.message === "string" ? body.message.trim() : "";
      if (!message || message.length > 8000) return json({ error: "Provide a message of 1–8000 characters." }, 400, origin);

      const specialistIds = ["sales-agent", "digital-marketing", "seo-content", "social-media", "video-audio"];
      const requested = Array.isArray(body.agents) ? body.agents : specialistIds;
      if (!requested.length || requested.length > specialistIds.length ||
          requested.some(id => !specialistIds.includes(id)) ||
          new Set(requested).size !== requested.length) {
        return json({ error: "agents must contain unique specialist agent IDs only." }, 400, origin);
      }

      const businessContext = body.businessContext == null ? "" :
        (typeof body.businessContext === "string" ? body.businessContext : JSON.stringify(body.businessContext)).slice(0, 3000);
      const sharedBrief = [
        "WISE SELL AI TEAM TASK",
        "User's business request: " + message,
        businessContext ? "Shared business context: " + businessContext : "",
        "Work only within your specialist role. Give actionable findings that the other agents and coordinator can use. State assumptions; do not invent business metrics or claim external actions."
      ].filter(Boolean).join("\n\n");

      try {
        const contributions = await Promise.all(requested.map(async id => {
          const specialist = AGENTS.find(agent => agent.id === id);
          const generated = await generateAgentAnswer(specialist, user, sharedBrief, env);
          return { agent: id, answer: generated.answer, provider: generated.provider, mode: generated.mode };
        }));

        const coordinator = AGENTS.find(agent => agent.id === "business-assistant");
        const synthesisInput = [
          "Coordinate the following specialist work into one coherent business action plan.",
          "Original user request: " + message,
          businessContext ? "Business context: " + businessContext : "",
          "Specialist contributions:",
          ...contributions.map(item => "\n[" + item.agent + "]\n" + item.answer),
          "Resolve conflicts, remove repetition, prioritize actions, identify dependencies, and give the user one clear next-step checklist. Do not claim that recommendations have been executed."
        ].filter(Boolean).join("\n\n");
        const final = await generateAgentAnswer(coordinator, user, synthesisInput, env);
        return json({
          ok: true,
          coordinator: "business-assistant",
          requestedAgents: requested,
          contributions,
          answer: final.answer,
          provider: final.provider,
          mode: final.mode,
          notice: "Agents generated recommendations only; no external posting, messaging, purchases, or account changes were performed."
        }, 200, origin);
      } catch (e) {
        return json({ error: "Agent orchestration failed.", detail: e.message }, 502, origin);
      }
    }

    if ((url.pathname.startsWith("/api/agents/") || ["/api/ai/business-growth", "/api/ai/marketing-advisor", "/api/ai/lead-qualify"].includes(url.pathname)) && request.method === "POST") {
      const projectId = env.FIREBASE_PROJECT_ID;
      if (!projectId) return json({ error: "Firebase project ID is not configured." }, 503, origin);
      let user;
      try { user = await firebaseUser(request, projectId); }
      catch (e) { return json({ error: "Authentication failed", detail: e.message }, 401, origin); }

      const legacyRoutes = {
        "/api/ai/business-growth": "business-assistant",
        "/api/ai/marketing-advisor": "digital-marketing",
        "/api/ai/lead-qualify": "sales-agent"
      };
      const routeId = url.pathname.slice("/api/agents/".length);
      const routeAliases = {
        business: "business-assistant",
        marketing: "digital-marketing",
        content: "seo-content",
        seo: "seo-content",
        social: "social-media",
        video: "video-audio",
        inventory: "business-assistant"
      };
      const id = legacyRoutes[url.pathname] || routeAliases[routeId] || routeId;
      const agent = AGENTS.find(a => a.id === id);
      if (!agent) return json({ error: "Unknown agent." }, 404, origin);
      let body;
      try { body = await request.json(); } catch { return json({ error: "Request body must be valid JSON." }, 400, origin); }
      const message = typeof body.message === "string" ? body.message.trim() : typeof body.prompt === "string" ? body.prompt.trim() : JSON.stringify(body);
      if (!message || message.length > 8000) return json({ error: "Provide a message of 1–8000 characters." }, 400, origin);
      try {
        const generated = await generateAgentAnswer(agent, user, message, env);
        const answer = generated.answer;
        if (legacyRoutes[url.pathname]) {
          const clean = answer.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
          let data;
          try { data = JSON.parse(clean); } catch { data = null; }
          if (url.pathname === "/api/ai/business-growth") {
            data = data && typeof data === "object" ? data : { executiveSummary: answer, financialHealthScore: null, strategicRecommendations: [], scenarioSimulation: "Use the action plan and enter current business figures to evaluate scenarios.", urgentRisk: "Validate assumptions against actual records." };
          } else if (url.pathname === "/api/ai/marketing-advisor") {
            data = data && typeof data === "object" ? data : { recommendation: answer, bottleneck: "Review campaign conversion data.", expectedCvrLift: "Not estimated", actionItems: [], adSpendAdjustment: "No paid advertising budget is used by this zero-cost plan." };
          } else {
            data = data && typeof data === "object" ? data : { score: null, tier: "Needs review", intent: answer, bantAnalysis: {} };
          }
          return json({ success: true, data, provider: generated.provider, mode: generated.mode }, 200, origin);
        }
        return json({ ok: true, agent: agent.id, answer, provider: generated.provider, mode: generated.mode, ...(generated.reason ? { notice: generated.reason } : {}) }, 200, origin);
      } catch (e) {
        return json({ error: "Agent request failed.", detail: e.message }, 502, origin);
      }
    }
    return json({ error: "Not found" }, 404, origin);
  }
};
