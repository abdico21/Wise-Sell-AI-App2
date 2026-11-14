# WiseSell AI — Cloudflare Workers AI backend

WiseSell AI uses Firebase Authentication for account sign-in and Cloudflare Workers AI for
AI responses. The Worker verifies Firebase ID tokens against Google's published signing
certificates, so the AI provider key is not stored in the Android app.

## Deploy from your Android phone with Cloudflare Git integration

1. Open the Cloudflare dashboard and go to **Workers & Pages**.
2. Tap **Create application**, then choose **GitHub** / **Import a repository**.
3. Authorize Cloudflare to access GitHub if prompted, then select
   `abdico21/Wise-Sell-AI-App2`.
4. Set the Worker name to **wisesell-ai-api**.
5. Set the production branch to **feature/flutter-mobile-foundation**.
6. Set the root directory to **cloudflare**.
7. Leave the build command blank. Set the deploy command to **npx wrangler deploy**.
8. Tap **Save and Deploy**. Cloudflare should install the Worker dependencies and deploy
   the Worker from `cloudflare/wrangler.toml`. The Wrangler config declares the Workers AI
   binding named `AI` and Firebase project ID `gen-lang-client-0645056984`.
9. Open the Worker details and copy the exact `workers.dev` URL. Visit that URL followed
   by `/health`; a successful deployment returns a JSON status response.

Cloudflare's Git integration can deploy new commits automatically. The Worker name in the
dashboard must match `name = "wisesell-ai-api"` in the Wrangler configuration.

## Alternative: GitHub Actions deployment

The repository also contains `.github/workflows/deploy-cloudflare-worker.yml`.
To use it instead of Cloudflare Git integration, add GitHub Actions secrets
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`, then run **Deploy WiseSell AI
Cloudflare Worker** from the Actions tab. Use a narrowly scoped Cloudflare API token with
permission to deploy Workers. Never paste tokens into chat or commit them.

## Included API

- `GET /health` service check.
- `POST /v1/agent` authenticated agent endpoint.
- Seven agent modes: Business Assistant, Marketing, Content, SEO, Social, Video/Audio,
  and Inventory.
- Firebase ID token verification (project audience and issuer).
- Cloudflare Workers AI model binding; no Gemini key is required.
- Input validation, response errors and basic CORS handling.

## Free-tier and usage notes

Cloudflare Workers and Workers AI have free-plan limits, model availability and quotas
that Cloudflare can change. Free use is not unlimited or guaranteed. Check your Cloudflare
dashboard's Workers AI usage and current pricing before launch. This approach avoids
Firebase Cloud Functions for AI inference, so it does not require enabling Firebase Blaze
for this AI endpoint. Firebase Authentication and its existing services remain in use.

## Connect the Android app

The Agent Workspace calls the Worker URL configured in
`WISESELL_API_BASE_URL`. The current build default is
`https://wisesell-ai-api.iamabdu3.workers.dev`. Confirm that this exact URL matches the
one Cloudflare shows. If it differs, update the build value in
`.github/workflows/mobile-ci.yml` before producing the APK.

## Production limitations

The first AI service provides advice and draft content only. It does not publish posts,
send WhatsApp/Telegram messages, execute payments, change stock, render actual video/audio,
or crawl websites. Those require official APIs, persistent data, permissions, approvals,
quotas, monitoring and testing. This first version does not yet provide a durable per-user
quota ledger; Cloudflare platform-level limits apply. Add durable rate limiting and abuse
monitoring before public release.
