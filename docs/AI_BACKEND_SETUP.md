# WiseSell AI secure AI backend

This repository includes a Firebase callable function named `runWiseSellAgent`.
It authenticates every call with Firebase Auth, applies a per-user daily request limit,
keeps the Gemini API key in Firebase Secret Manager, and records minimal activity metadata.
The Business Assistant is the coordinator; specialist agents cover marketing, content,
SEO, social, video/audio and inventory. Agents draft and advise only: they do not publish,
message customers, charge money or modify inventory.

## Activate the AI service from an Android phone

Before deployment, check the Firebase project's billing plan. Cloud Functions deployment
may require Firebase Blaze. Cloud Functions, Google Cloud infrastructure and AI provider
usage can incur charges. Configure a small budget alert and review provider quotas before
turning on the service. Do not proceed if you cannot accept possible usage charges.

1. Create a Gemini API key in Google AI Studio. Never paste it into this chat, source code,
   the APK, or a public GitHub file.
2. In GitHub, open this repository → Settings → Secrets and variables → Actions.
   Add a repository secret named `GEMINI_API_KEY` containing the Gemini key.
3. In Google Cloud Console for project `gen-lang-client-0645056984`, create a dedicated
   deployment service account with the permissions required to deploy Firebase/2nd-gen
   Cloud Functions, use Cloud Build/Artifact Registry, act as the Functions runtime service
   account, and create/update Secret Manager versions. Create a JSON key only if your
   organization permits service-account keys.
4. In GitHub Actions secrets, add `FIREBASE_SERVICE_ACCOUNT_WISESELL_AI` containing the
   full service-account JSON. Keep both secrets private and do not share them in chat.
5. In the repository's Actions tab, select **Deploy WiseSell AI backend**, tap **Run workflow**,
   and run it on `feature/flutter-mobile-foundation`. The workflow stores the Gemini key in
   Secret Manager and deploys the callable function.
6. Confirm Email/Password Authentication is enabled and Cloud Firestore is created. Publish
   this repository's `firestore.rules`.
7. Sign in to the Android app, open AI Studio, and test with a simple business question.
   The callable function rejects unsigned users and enforces a starter limit of 20 requests
   per user per UTC day.

The mobile app calls the callable function in `europe-west1`. Review billing, quotas and logs
before inviting other users.

## Current limits

This is the first live AI service slice, not the complete platform. Social network OAuth/API
connections, marketplace payments/orders, media rendering, automated SEO crawls, inventory
automation, push workflows, full multilingual quality review, App Check, production monitoring,
and Play Store signing/release remain separate work. No channel is marked connected until its
official authorization and API flow is implemented and tested.
