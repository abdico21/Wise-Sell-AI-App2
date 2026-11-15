# Deploying the Wise Sell AI Worker

The Worker source is in `src/index.js`; its configuration is in `wrangler.toml`.

## One-time GitHub setup

1. In Cloudflare, open **Workers & Pages** and select the account that owns `wise-sell-ai-app2`.
2. Create an API token with permission to edit Cloudflare Workers for that account. Do not put the token in source code, chat, or a normal GitHub file.
3. In GitHub, open this repository's **Settings → Secrets and variables → Actions**.
4. Add these repository secrets:
   - `CLOUDFLARE_API_TOKEN`: the token created in Cloudflare.
   - `CLOUDFLARE_ACCOUNT_ID`: the Cloudflare account ID.
5. Open **Actions → Deploy Wise Sell AI Worker → Run workflow** and run it from `main`.

## Required Worker configuration

- `FIREBASE_PROJECT_ID` and `OPENAI_MODEL` are declared in `wrangler.toml`.
- Add a Worker secret named `OPENAI_API_KEY` in Cloudflare: Workers & Pages → `wise-sell-ai-app2` → Settings → Variables and Secrets → Add → Secret. Paste the API key created in the OpenAI Platform dashboard and save/deploy.
- The Worker calls the OpenAI Responses API server-side. Never put the OpenAI key in the Android app, GitHub source files, or chat.

## Verify after deployment

Open `https://wise-sell-ai-app2.abdico-veiws22.workers.dev/api/health`. A successful response should contain `ok: true` and report the OpenAI integration as configured. Then sign in to Wise Sell AI and test each agent. A successful health response alone does not prove that authenticated OpenAI requests work.

The deployment workflow is manual so it does not fail on every commit before the Cloudflare secrets have been configured.
