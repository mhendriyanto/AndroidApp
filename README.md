# SnapClean

SnapClean is a Flutter Android app for managing temporary screenshots. Users can import selected screenshots, assign countdown timers, archive important images, organize saved screenshots into folders, and keep their account data synced with Firebase.

## Project Status

SnapClean is currently in demo phase. The app has been tested on an Android emulator and includes the main user workflow for account sign in, screenshot import, timer assignment, saved folders, settings, and cloud persistence.

The project is being maintained as a working prototype for demonstration, testing, and coursework. The current focus is showing the user experience and Firebase-backed app flow in a realistic Android environment.

## Features

- Email and password authentication with Firebase Auth
- Username or email sign in
- Forgot password and forgot username flows
- Screenshot import through the Android image picker
- Multiple screenshot import workflow
- Per-screenshot timer selection
- Default timers and custom timers
- Active timer screen with countdown status
- Automatic expired screenshot cleanup state
- Archive/Saved area for screenshots kept without a timer
- Folder creation, folder deletion, and folder assignment
- Recently Deleted restore flow
- Profile and account settings
- Theme/background settings
- Privacy policy and app information screens
- Firestore metadata sync
- Firebase Storage upload support for selected screenshots

## Tech Stack

- Flutter
- Dart
- Android
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

## Repository Structure

```text
lib/
  app.dart                         App root and theme setup
  main.dart                        Firebase bootstrap and app launch
  models/                          Screenshot, folder, user, and timer models
  screens/                         Auth, home, timer, import, saved, settings, profile screens
  services/                        Firebase Auth, Firestore, and Storage repositories
  state/                           AppController and shared app state
  theme/                           Colors and typography
  widgets/                         Shared UI components

android/                           Android project files
design/                            Original HTML/design reference
firestore.rules                    Firestore security rules
storage.rules                      Firebase Storage security rules
FIREBASE_SETUP.md                  Firebase setup notes
PRIVACY_POLICY.md                  Privacy policy draft
```

## Firebase Setup

SnapClean uses Firebase project:

```text
androidapp-snapclean
```

Required Firebase files:

```text
lib/firebase_options.dart
android/app/google-services.json
```

Firebase services used:

- Authentication for user accounts
- Firestore for user profiles, screenshot metadata, folders, settings, and custom timers
- Storage for selected screenshot files

Deploy rules after changing Firestore or Storage rules:

```sh
firebase deploy --only firestore:rules,storage
```

More details are available in [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

## Run Locally

Install dependencies:

```sh
flutter pub get
```

Run on an Android emulator or connected Android device:

```sh
flutter run
```

If native Android files changed, rebuild cleanly:

```sh
flutter clean
flutter pub get
flutter run
```

## Emulator Screenshot Testing

To create screenshots inside the emulator storage:

```sh
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell mkdir -p /sdcard/Pictures/Screenshots
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell screencap -p /sdcard/Pictures/Screenshots/screenshot.png
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/Screenshots/screenshot.png
```

Then open SnapClean and use:

```text
+ button -> Choose Image -> Pictures -> Screenshots
```

## Privacy

SnapClean imports only screenshots selected by the user through the Android picker. It does not scan the full photo library. Account data, screenshot metadata, app settings, and selected screenshot files may be stored with Firebase to support account sync and persistence.

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## Development Notes

This project is built for a school app development project and investor-style demo presentation. The current focus is a complete Android user workflow without a custom backend server. Firebase is used for authentication, metadata storage, and screenshot file storage.
