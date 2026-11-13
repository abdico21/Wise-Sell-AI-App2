# WiseSell AI Android Production Release Checklist

This checklist distinguishes a successful CI build from a production-ready Android release.

## 1. Firebase project

Firebase project: `lunar-option-jbvhw`  
Android application ID: `wise.sell.ai2`

- [ ] In Firebase Console, open Authentication → Sign-in method and enable Email/Password.
- [ ] Create the Cloud Firestore database in the intended production region.
- [ ] Review and publish the repository's `firestore.rules` rules in Firestore → Rules.
- [ ] Create at least one test account and verify registration, sign-in, password reset and sign-out.
- [ ] Verify a signed-in account can create/read/update only its own business profile, products, customers and sales.
- [ ] Configure Firebase App Check before broad public release.
- [ ] Restrict the Firebase API key by the Android application ID and signing certificate fingerprints where applicable.
- [ ] Configure Android SHA-1 and SHA-256 fingerprints in Firebase when required by enabled Firebase services.

## 2. Android release signing

The current CI workflow runs `flutter build apk --release` but does not configure a production upload/release keystore. Do not publish the resulting APK to a public app store as a verified production-signed release.

- [ ] Create and securely back up an Android upload/release keystore.
- [ ] Record the keystore alias and passwords in a password manager.
- [ ] Never commit the keystore, `key.properties`, or passwords to Git.
- [ ] Configure GitHub Actions repository secrets for the keystore and signing credentials.
- [ ] Update the Android Gradle signing configuration to use those secrets.
- [ ] Verify the generated APK/AAB is signed with the expected certificate.
- [ ] Keep a protected backup of the signing key. Losing the key can block future updates, depending on the Play App Signing setup.

Suggested GitHub Actions secret names (the workflow must explicitly consume them before they have any effect):
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## 3. App and device testing

- [ ] Install the signed release APK on a physical Android device.
- [ ] Test on supported Android versions and different screen sizes.
- [ ] Test registration, login, logout, password reset and offline/network error states.
- [ ] Test business profile, product CRUD, customer CRM and sales recording.
- [ ] Confirm stock and revenue calculations with known test data.
- [ ] Test notification permission and delivery on a physical device if push notifications are enabled.
- [ ] Test app restart, session persistence, slow networks and empty/error states.
- [ ] Remove test accounts and test data from production before launch.

## 4. Store and operational readiness

- [ ] Set the final app version and build number.
- [ ] Build and test an Android App Bundle (AAB) for Google Play.
- [ ] Prepare app icon, screenshots, store listing, privacy policy and support contact.
- [ ] Complete Google Play Data safety and content declarations accurately.
- [ ] Review Firestore rules, API key restrictions, crash reporting and backup/retention policies.
- [ ] Run a final release build from the exact commit intended for release.

## Current verified state

The repository's CI workflow has passed Flutter formatting, analysis, tests, Firebase configuration checks and release APK generation. This confirms that the current code builds in CI; it does not confirm live Firebase console configuration, production signing, physical-device testing, push-notification delivery or Play Store approval.
