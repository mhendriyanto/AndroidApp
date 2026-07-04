import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

enum FirebaseStartupState { ready, missingConfig, failed }

class FirebaseStartupResult {
  final FirebaseStartupState state;
  final Object? error;

  const FirebaseStartupResult._(this.state, [this.error]);

  const FirebaseStartupResult.ready() : this._(FirebaseStartupState.ready);

  const FirebaseStartupResult.missingConfig(Object error)
      : this._(FirebaseStartupState.missingConfig, error);

  const FirebaseStartupResult.failed(Object error)
      : this._(FirebaseStartupState.failed, error);

  bool get isReady => state == FirebaseStartupState.ready;
}

class FirebaseBootstrap {
  static FirebaseStartupResult? lastResult;

  static Future<FirebaseStartupResult> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      lastResult = const FirebaseStartupResult.ready();
    } catch (error, stackTrace) {
      debugPrint('Firebase is not configured yet: $error');
      debugPrintStack(stackTrace: stackTrace);
      lastResult = FirebaseStartupResult.missingConfig(error);
    }
    return lastResult!;
  }
}
