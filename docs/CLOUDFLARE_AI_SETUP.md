# WiseSell AI — Cloudflare Workers free-tier backend

The app's seven AI agents use one authenticated Worker endpoint backed by Cloudflare Workers AI.
The Worker verifies Firebase Authentication ID tokens against Google's published signing
certificates, so Firebase remains the sign-in provider while AI inference runs on Cloudflare.

## Included
- `GET /health` service check.
- `POST /v1/agent` authenticated agent endpoint.
- Seven agent modes: business coordinator, marketing, content, SEO, social, video/audio and inventory.
- Firebase ID token verification (project audience and issuer).
- Cloudflare Workers AI binding; no Gemini key or AI provider key is stored in the app.
- Input validation, response errors and basic CORS handling.

## Deploy from Android using Cloudflare dashboard
1. Sign in to Cloudflare and open **Workers & Pages**.
2. Create a Worker named `wisesell-ai-api`.
3. Open the Worker editor and replace the starter code with `cloudflare/src/index.js` from this repository.
4. In Worker settings, add a **Workers AI** binding named exactly `AI`.
5. Add a text variable named `FIREBASE_PROJECT_ID` with value `gen-lang-client-0645056984`.
6. Deploy the Worker. The dashboard displays the actual `workers.dev` URL.
7. Test the URL by adding `/health`; it should return a JSON status response.

The repository also includes `.github/workflows/deploy-cloudflare-worker.yml` for repeat deployments.
For that workflow, create a Cloudflare API token limited to this account and Worker edit/deploy
permissions, then add GitHub Actions secrets `CLOUDFLARE_API_TOKEN` and
`CLOUDFLARE_ACCOUNT_ID`. Never paste tokens into chat or commit them.

## Free-tier and usage notes
Cloudflare Workers and Workers AI have free-plan limits and model availability/quotas that
Cloudflare can change. Requests beyond included allocations may be throttled or require a
paid plan. Check the Cloudflare dashboard's Workers AI usage and current pricing before launch.
This design does not require Firebase Blaze for AI inference, but Firebase Authentication
remains enabled for sign-in. Firebase's own product limits still apply.

## Connect the Android app
The Flutter Agent Workspace calls the deployed URL configured in
`WISESELL_API_BASE_URL`. The default value in the app should be updated to the exact
`workers.dev` URL shown by Cloudflare before creating the APK.

## Production limitations
This first service provides AI advice and draft content only. It does not publish posts,
send WhatsApp/Telegram messages, execute payments, change stock, render actual video/audio,
or crawl websites. Those require separate official APIs, persistent data, permissions,
approvals, quotas, monitoring and testing. The first version does not yet provide a durable
per-user quota ledger; Cloudflare platform-level free-plan limits apply. Add durable
rate limiting and abuse monitoring before public release.
