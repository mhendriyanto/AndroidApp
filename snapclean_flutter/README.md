# SnapClean Flutter Prototype

UI-only Flutter prototype for SnapClean. No backend or Firebase is implemented.

The original HTML design reference is included at:

```text
design/index.html
```

## Screens

- Sign In
- Sign Up
- Forgot Password
- Forgot Username
- Home
- Import + Timer
- Timer Set
- Active
- Expiring
- Keep Forever
- Profile
- Edit Profile
- Settings

## Current Prototype Features

- Local sign-in/sign-out flow
- Local screenshot import from the Android emulator image picker
- Custom import timers
- Active and Expiring timer tabs
- Auto-delete expired screenshots while the app is open
- In-app notification when expired screenshots are deleted
- Screenshot detail screen with keep, snooze, and delete actions

## Android SDK

The project is configured to use:

```text
/Users/hendricushendriyanto/Library/Android/sdk
```

## Run

Once Flutter is working locally:

```sh
cd /Users/hendricushendriyanto/Documents/Final/snapclean_flutter
/Users/hendricushendriyanto/development/flutter/bin/flutter pub get
/Users/hendricushendriyanto/development/flutter/bin/flutter run
```
