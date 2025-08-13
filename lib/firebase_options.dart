// Generated file. Do not edit.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'apiKey',
    appId: '1:1234567890:web:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'placeholder',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'apiKey',
    appId: '1:1234567890:android:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'placeholder',
    storageBucket: 'placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'apiKey',
    appId: '1:1234567890:ios:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'placeholder',
    storageBucket: 'placeholder.appspot.com',
    iosBundleId: 'com.example.poker_ai_analyzer',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'apiKey',
    appId: '1:1234567890:macos:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'placeholder',
    storageBucket: 'placeholder.appspot.com',
    iosBundleId: 'com.example.poker_ai_analyzer',
  );
}
