# WiseSell AI Mobile

Enterprise AI-powered social-commerce mobile application for merchants and businesses.

## Flutter foundation

The `feature/flutter-mobile-foundation` branch includes the Material 3 mobile dashboard, multilingual localization foundation (English, Amharic, Afaan Oromo, Tigrinya and Somali), Firebase SDK dependencies, and GitHub Actions quality checks.

### Requirements

- Flutter stable
- Dart SDK 3.3 or later
- Android Studio and Android SDK for Android packaging

### Run and verify

```bash
flutter pub get
flutter analyze
flutter test
```

### Firebase project

The Android Firebase configuration is committed at `android/app/google-services.json`, and `lib/main.dart` now calls `Firebase.initializeApp()` before launching the app.

- Firebase project ID: `lunar-option-jbvhw`
- Android application ID expected by Firebase: `wise.sell.ai2`

**Remaining Android integration:** this branch did not yet contain an Android Gradle platform scaffold when the Firebase configuration was added. The Google Services Gradle plugin and matching Android application ID must be configured in that scaffold before an Android APK can be built and Firebase's native configuration can be verified. Push-notification permission handling and token registration also remain to be implemented. Do not commit service-account credentials. Restrict the Firebase API key in Google Cloud Console and configure Firebase Authentication providers and security rules before production use.

### Continuous integration

Workflow: `.github/workflows/wisesell-flutter-mobile-ci.yml`

The workflow installs Flutter dependencies, runs static analysis, and executes widget tests. APK packaging will be enabled after the Android platform scaffold is added and verified.
