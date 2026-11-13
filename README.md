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

The CI workflow generates the Flutter Android platform scaffold, applies the Google Services Gradle plugin, validates the Firebase project/package pairing, runs analysis and tests, then builds a release APK. Firebase Authentication and Cloud Messaging SDKs are included; sign-in flows, notification permission/token registration, and production Firebase security rules still need implementation and verification. Restrict the Firebase API key in Google Cloud Console. Never commit service-account credentials.

### Continuous integration and APK

Workflow: `.github/workflows/mobile-ci.yml`

A successful run publishes the release APK as the `wisesell-ai-android-release` workflow artifact. The artifact is only available after the run completes successfully.
