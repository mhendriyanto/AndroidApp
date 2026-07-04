# Firebase Setup

SnapClean now includes the Firebase bootstrap, Auth dependency, and first
Firestore service layer for:

`androidapp-snapclean`

## Current State

- `firebase_core`, `firebase_auth`, `cloud_firestore`, and `firebase_storage` are added to
  `pubspec.yaml`.
- `lib/services/firebase_bootstrap.dart` initializes Firebase with
  `lib/firebase_options.dart`.
- `lib/firebase_options.dart` and `android/app/google-services.json` are
  required for the app to start with Firebase enabled.
- Android has the Google Services Gradle plugin enabled.
- `.firebaserc` points to `androidapp-snapclean`.
- `firebase.json` is prepared for Android config output and Firestore rules.
- `lib/services/auth_repository.dart` contains the first Firebase Auth methods.
- `lib/services/firestore_repository.dart` contains the first database methods.
- `lib/services/storage_repository.dart` uploads screenshot image files to
  Firebase Storage.
- `firestore.rules` protects each user's data by Firebase Auth uid.
- `storage.rules` protects each user's screenshot files by Firebase Auth uid.

## Android Config

1. Open Firebase project `androidapp-snapclean`.
2. Add an Android app with package name:

   `com.example.snapclean_flutter`

3. Download `google-services.json`.
4. Place it here:

   `android/app/google-services.json`

5. In Firebase Console, enable Authentication providers:

   - Email/password for real accounts.
   - Anonymous sign-in if you want guest testing before account creation.

6. In Firebase Console, create Cloud Firestore.

7. In Firebase Console, create Firebase Storage.

8. Run:

   `flutter clean`
   `flutter pub get`
   `flutter run`

## Initial Firestore Shape

The app will store all user data under the signed-in user's uid:

- `users/{uid}`: profile details such as name, email, and username.
- `usernames/{normalizedUsername}`: username-to-email lookup used before
  Firebase Auth sign in, so users can log in with username or email.
- `users/{uid}/screenshots/{screenshotId}`: screenshot metadata, timer status,
  local image path, created time, expiration time, and archive/delete state.
- `users/{uid}/folders/{folderId}`: saved/archive folders and their screenshot
  ids.
- `users/{uid}/settings/app`: user preferences such as cleanup behavior,
  reminders, default timer, and default save location.
- `users/{uid}/timerPresets/{presetId}`: custom timer options.
- `users/{uid}/activity/{eventId}`: lightweight activity history for future
  audit or notification features.

Screenshot images are stored in Firebase Storage:

- `users/{uid}/screenshots/{screenshotId}.jpg`

Firebase Storage requires a billing-enabled Firebase project. For release,
keep costs controlled by uploading only user-selected screenshots, deleting
test data you no longer need, setting a Google Cloud budget alert, and
monitoring Storage usage during testing.

## Deploy Firestore Rules

After Firebase CLI login is ready, run:

`firebase deploy --only firestore:rules,storage`

## Next Backend Steps

After this layer is connected to the UI, the next useful integrations are:

- Wire sign in/create account screens to `AuthRepository`.
- Sync app controller data through `FirestoreRepository`.
- Add Firebase Storage for screenshot images if cloud backup is desired.
- Add Cloud Functions later only if server-side cleanup or scheduled jobs are
  needed.

## CLI Alternative

If you want FlutterFire to generate config automatically, run:

`firebase login`

Then:

For release, replace `com.example.snapclean_flutter` with the production
Android application id you register in Firebase:

`flutterfire configure --project=androidapp-snapclean --platforms=android --android-package-name=YOUR.PRODUCTION.PACKAGE --out=lib/firebase_options.dart --yes`

The CLI requires your Firebase account session. Codex cannot complete this without access to your Firebase login token.
