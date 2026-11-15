# Deploying the Wise Sell AI Worker

The Worker source is in `src/index.js`; its configuration is in `wrangler.toml`.

## GitHub Actions deployment

The `Deploy Wise Sell AI Worker` workflow deploys on pushes to `main` and can also be run manually from **Actions**.

The repository must have these GitHub Actions secrets configured:

- `CLOUDFLARE_API_TOKEN`: a Cloudflare API token with permission to edit Workers for the target account.
- `CLOUDFLARE_ACCOUNT_ID`: the Cloudflare account ID.

If either secret is missing or invalid, the workflow will fail without replacing the currently deployed Worker.

## Required Worker configuration

- `FIREBASE_PROJECT_ID` and `OPENAI_MODEL` are declared in `wrangler.toml`.
- Add a Worker secret named `OPENAI_API_KEY` in Cloudflare: **Workers & Pages → wise-sell-ai-app2 → Settings → Variables and Secrets → Add → Secret**. Save and deploy.
- The Worker calls the OpenAI Responses API server-side. Never put the OpenAI key in the Android app, GitHub source files, or chat.
- If `OPENAI_API_KEY` is not configured, the Worker uses the built-in zero-cost fallback. Firebase authentication remains required for agent endpoints.

## Verify after deployment

Open `https://wise-sell-ai-app2.abdico-veiws22.workers.dev/api/health`. A successful response should contain `ok: true`, `integrations.firebaseAuth: true`, and `integrations.openaiConfigured: true`.

Then sign in to Wise Sell AI and test all six routes:

- `POST /api/agents/business-assistant`
- `POST /api/agents/sales-agent`
- `POST /api/agents/digital-marketing`
- `POST /api/agents/seo-content`
- `POST /api/agents/social-media`
- `POST /api/agents/video-audio`

Each request requires a valid Firebase ID token in the `Authorization: Bearer` header and a JSON body such as `{"message":"Create a practical plan to increase sales for my shop."}`.

A successful health response alone does not prove that authenticated OpenAI requests work. Test with a signed-in Android session and never expose the API key in client code or logs.
