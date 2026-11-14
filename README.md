# WiseSell AI mobile and backend

WiseSell AI uses Firebase Authentication for account sign-in and Cloudflare Workers AI
for AI responses. The seven agent modes are Business Assistant, Digital Marketing,
Content Marketing, SEO, Social Media Marketing, Video & Audio Marketing, and Inventory.

## Cloudflare AI backend

See [Cloudflare AI setup](docs/CLOUDFLARE_AI_SETUP.md). The Worker verifies Firebase ID
tokens and calls the Workers AI binding. No Gemini key or other model API key is stored
in the Android app. The app's default endpoint is
`https://wisesell-ai-api.iamabdu3.workers.dev`; if Cloudflare displays a different
workers.dev address for your account, update the `WISESELL_API_BASE_URL` build value
in `.github/workflows/mobile-ci.yml` before producing the APK.

Cloudflare Workers and Workers AI have free-plan limits, model quotas and availability
conditions. Free use is not unlimited or guaranteed. Review current dashboard usage.
The first AI features provide advice and drafts; they do not publish posts, send messages,
charge payments, alter stock or render video/audio files.

## Firebase mobile services

Firebase project ID: `gen-lang-client-0645056984`
Android application ID: `com.aistudio.wisesell.kpzqvm`

Firebase remains responsible for authentication and existing app data. AI inference does
not require Firebase Cloud Functions. Never put service-account keys, Worker tokens or
private credentials in the Flutter source or APK.

## Build

GitHub Actions workflow `.github/workflows/mobile-ci.yml` verifies the Worker source,
runs Flutter analysis/tests, builds the Android APK and uploads
`wisesell-ai-android-release`. A CI APK is not proof of Play Store production signing.
