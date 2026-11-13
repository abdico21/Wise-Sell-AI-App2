# WiseSell AI Mobile

Enterprise AI-powered social-commerce mobile application for merchants and businesses.

## Flutter foundation

The `feature/flutter-mobile-foundation` branch includes the Material 3 mobile dashboard, multilingual localization foundation (English, Amharic, Afaan Oromo, Tigrinya and Somali), Firebase SDK dependencies, and GitHub Actions quality checks.

### Requirements

- Flutter stable
- Dart SDK 3.3 or later
- Android Studio and Android SDK for local Android packaging

### Run and verify

```bash
flutter pub get
flutter analyze
flutter test
```

### Firebase Android setup

- Firebase project ID: `lunar-option-jbvhw`
- Android application ID: `wise.sell.ai2`
- Android config: `android/app/google-services.json`
- Firebase initialization: `Firebase.initializeApp()` runs before `runApp`.

The CI workflow generates the Flutter Android platform scaffold, applies the Google Services Gradle plugin, validates the Firebase project/package pairing, runs analysis and tests, then builds a release APK. Firebase Authentication, Cloud Firestore, and Cloud Messaging SDKs are included. The app provides email/password registration, sign-in, password reset, sign-out, and an authenticated business-profile workspace. Business profiles are stored in `business_profiles/{uid}`. The `firestore.rules` file restricts each profile to its owner. Before using the workspace, create the Cloud Firestore database in the Firebase console and publish these rules (Firebase Console → Firestore Database → Rules, or deploy with the Firebase CLI). Enable Email/Password under Authentication → Sign-in method. Restrict the Firebase API key in Google Cloud Console. Never commit service-account credentials.

### Continuous integration and APK

Workflow: `.github/workflows/mobile-ci.yml`

A successful run publishes the release APK as the `wisesell-ai-android-release` workflow artifact. The artifact is only available after the run completes successfully.
