const AGENTS = [
  { id: "business-manager", name: "AI Business Manager", status: "scaffolded" },
  { id: "sales-marketing", name: "AI Sales & Marketing", status: "scaffolded" },
  { id: "marketplace", name: "Marketplace Agent", status: "scaffolded" },
  { id: "payments-orders", name: "Payments & Orders Agent", status: "scaffolded" },
  { id: "business-intelligence", name: "Business Intelligence Agent", status: "scaffolded" },
  { id: "enterprise-services", name: "Enterprise Services Agent", status: "scaffolded" }
];

function json(data, status = 200, origin = "*") {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": origin,
      "access-control-allow-methods": "GET,POST,OPTIONS",
      "access-control-allow-headers": "Content-Type, Authorization"
    }
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin") || "*";

    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "access-control-allow-origin": origin,
          "access-control-allow-methods": "GET,POST,OPTIONS",
          "access-control-allow-headers": "Content-Type, Authorization",
          "access-control-max-age": "86400"
        }
      });
    }

    if (url.pathname === "/" || url.pathname === "/api/health") {
      return json({
        ok: true,
        app: env.APP_NAME || "Wise Sell AI",
        service: "Cloudflare Worker API",
        message: "Worker is running. AI, Firebase, and social integrations still require configuration."
      }, 200, origin);
    }

    if (url.pathname === "/api/agents" && request.method === "GET") {
      return json({ agents: AGENTS }, 200, origin);
    }

    if (url.pathname.startsWith("/api/agents/") && request.method === "POST") {
      return json({
        ok: false,
        error: "Agent execution is not configured yet.",
        next: "Connect authenticated Firebase identity and a server-side AI provider secret before enabling agent requests."
      }, 501, origin);
    }

    return json({ ok: false, error: "Not found" }, 404, origin);
  }
};
