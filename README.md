# WiseSell AI Mobile

Enterprise AI-powered social-commerce mobile application for merchants and businesses.

## Flutter foundation

The `feature/flutter-mobile-foundation` branch includes the Material 3 mobile dashboard, multilingual localization foundation (English, Amharic, Afaan Oromo, Tigrinya and Somali), Firebase Authentication/Firestore/Cloud Messaging SDKs, and GitHub Actions quality checks.

## Secure AI agent service

The Agent Workspace now calls a Firebase callable function named `runWiseSellAgent` in `europe-west1`. It supports seven specialist modes: Business Assistant (coordinator), Digital Marketing, Content Marketing, SEO, Social Media, Video & Audio, and Inventory. The function requires Firebase Authentication, keeps the Gemini API key in Firebase Secret Manager, and applies a starter limit of 20 requests per user per UTC day. It stores minimal usage metadata only.

**The AI service will not answer until the backend function is deployed and the `GEMINI_API_KEY` secret is configured.** Follow [docs/AI_BACKEND_SETUP.md](docs/AI_BACKEND_SETUP.md). Cloud Functions deployment may require the Firebase Blaze plan and provider usage can incur charges. Configure budget alerts before enabling production traffic.

Agent output is advice and draft content only. It does not publish to social channels, send customer messages, charge payments, create media files or change inventory. Official channel OAuth/API integrations and those action workflows remain to be implemented and reviewed.

## Firebase Android setup

- Firebase project ID: `gen-lang-client-0645056984`
- Android application ID: `com.aistudio.wisesell.kpzqvm`
- Android config: `android/app/google-services.json`
- Firebase initialization: `Firebase.initializeApp()` runs before `runApp`.

Enable Email/Password under Authentication → Sign-in method. Create the Cloud Firestore database and publish `firestore.rules`. Never commit service-account credentials, Gemini API keys or signing keys.

## Continuous integration and APK

Workflow: `.github/workflows/mobile-ci.yml`

A successful run verifies the Node.js Functions source, runs Flutter analysis and tests, builds the Android release APK, and uploads it as `wisesell-ai-android-release`. This CI APK is not proof of Play Store production signing.
