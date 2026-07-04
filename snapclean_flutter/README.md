# SnapClean

SnapClean helps users manage temporary screenshots with timers, folders,
archiving, account sync, and restore controls.

## Features

- Firebase email/password authentication
- Username sign-in support
- Password reset and username recovery
- Device photo picker import
- Default and custom screenshot timers
- Archive and folder organization
- Firebase Firestore metadata sync
- Firebase Storage screenshot upload
- Recently Deleted restore flow
- Profile, settings, theme, and notification preferences

## Firebase

The app uses Firebase Core, Authentication, Firestore, and Storage.

Before running a new environment, make sure these files exist:

```text
lib/firebase_options.dart
android/app/google-services.json
```

Deploy security rules after changing Firestore or Storage rules:

```sh
firebase deploy --only firestore:rules,storage
```

## Run

```sh
cd /Users/hendricushendriyanto/Documents/Final/snapclean_flutter
flutter pub get
flutter run
```

## Release Checklist

- Configure a production Android application id.
- Add the matching Android app in Firebase and replace `google-services.json`.
- Configure Android release signing.
- Build and test a release APK or App Bundle on a physical device.
- Prepare store listing screenshots, privacy policy, and support contact.
- Verify Firebase Auth, Firestore, Storage, import, restore, and delete flows.
