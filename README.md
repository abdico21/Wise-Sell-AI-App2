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

The configured Firebase project identifiers previously supplied for this app are:

- Project ID: `lunar-option-jbvhw`
- Android application ID: `wise.sell.ai2`

Firebase Core, Authentication, and Cloud Messaging packages are declared. Runtime initialization and Android push-notification registration are not yet enabled because this branch does not currently contain the Android Gradle project or the verified `google-services.json` / generated FlutterFire options.

To complete that integration, add the Firebase Android app configuration for package `wise.sell.ai2`, generate `lib/firebase_options.dart` with FlutterFire CLI, then initialize Firebase before `runApp`. Keep service-account keys and private credentials out of source control. Configure Authentication providers, API-key restrictions, and least-privilege security rules in Firebase Console.

### Continuous integration

Workflow: `.github/workflows/wisesell-flutter-mobile-ci.yml`

The workflow installs Flutter dependencies, checks Dart formatting, runs static analysis, and executes widget tests. APK packaging will be added after the Android platform scaffold and Firebase configuration are verified.
