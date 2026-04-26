// TODO: Replace this entire file by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// The generated file will contain your real API keys and project identifiers.
// NEVER commit real keys to a public repository.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Unsupported platform: $defaultTargetPlatform. '
          'Run flutterfire configure to generate options.',
        );
    }
  }

  // TODO: Replace ALL placeholder values below with real values from FlutterFire CLI
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO_WEB_API_KEY',
    appId: 'TODO_WEB_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    authDomain: 'TODO_PROJECT_ID.firebaseapp.com',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
    measurementId: 'TODO_MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO_ANDROID_API_KEY',
    appId: 'TODO_ANDROID_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO_IOS_API_KEY',
    appId: 'TODO_IOS_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
    iosClientId: 'TODO_IOS_CLIENT_ID',
    iosBundleId: 'com.vibzcheck.app',
  );
}
