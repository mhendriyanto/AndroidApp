# SnapClean Release Checklist

Use this checklist before publishing SnapClean publicly.

## Required External Setup

- Choose a production Android package name, for example
  `com.snapclean.app`.
- Update `android/app/build.gradle`:
  - `namespace`
  - `applicationId`
- Update `android/app/src/main/AndroidManifest.xml` package if keeping that
  attribute.
- Add the production Android app in Firebase using the same package name.
- Download the new `android/app/google-services.json`.
- Re-run FlutterFire configuration if needed.
- Deploy Firestore and Storage rules:

```sh
firebase deploy --only firestore:rules,storage
```

## Android Release

- Configure release signing in Android Studio or Gradle.
- Build a release App Bundle:

```sh
flutter build appbundle --release
```

- Install and test a release build on a physical Android device.
- Verify app icon, app name, splash screen, and Android permissions.

## Functional Tests

- Create account
- Sign in with email
- Sign in with username
- Forgot password
- Forgot username
- Import photos
- Save screenshots with timers
- Archive screenshots
- Create, rename, delete, and switch folders
- Restore from Recently Deleted
- Verify screenshots persist after reinstall/sign-in
- Verify settings persist after sign-out/sign-in
- Verify Firebase Storage files are created for screenshots

## Store Listing

- App name: SnapClean
- Short description
- Full description
- Screenshots for phone layouts
- Feature graphic
- Privacy policy URL
- Support email
- Data safety form

## Remaining Product Hardening

- Add true scheduled local notifications for timers.
- Add permanent delete for Recently Deleted and remove matching Storage files.
- Add retry controls for failed screenshot uploads.
- Add account deletion/data deletion request flow.
