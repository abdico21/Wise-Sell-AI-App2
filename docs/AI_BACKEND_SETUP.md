# WiseSell AI secure AI backend

This repository includes a Firebase callable function named `runWiseSellAgent`.
It authenticates every call with Firebase Auth, applies a per-user daily request limit,
keeps the Gemini API key in Firebase Secret Manager, and records minimal activity metadata.
The Business Assistant is the coordinator; specialist agents cover marketing, content,
SEO, social, video/audio and inventory. Agents draft and advise only: they do not publish,
message customers, charge money or modify inventory.

## One-time server setup

1. Upgrade the Firebase project to the Blaze plan if required for Cloud Functions deployment.
   Cloud Functions and AI provider usage can incur charges; set budget alerts and quotas first.
2. Create a Gemini API key in Google AI Studio.
3. From an authenticated Firebase CLI session, set the secret:
   `firebase functions:secrets:set GEMINI_API_KEY`
   Paste the key into the secure prompt. Never commit it or put it in the Flutter app.
4. Deploy with `firebase deploy --only functions:runWiseSellAgent`.
5. Enable Email/Password Authentication and create the Firestore database; deploy the
   repository's Firestore rules.
6. Verify a signed-in test account can call the function and that an unsigned request is rejected.

The mobile app calls the callable function in `europe-west1`. The initial server allowance
is 20 requests per user per UTC day. Review usage and provider quotas before public launch.

## Current limits

This is the first live AI service slice, not the complete platform. Social network OAuth/API
connections, marketplace payments/orders, media rendering, automated SEO crawls, inventory
automation, push workflows, multilingual quality review, App Check, production monitoring,
and Play Store signing/release remain separate work. No channel is marked connected until its
official authorization and API flow is implemented and tested.
