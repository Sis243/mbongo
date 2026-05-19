import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return android; // same project, iOS config added when needed
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDnUo0CRXOQM7WeJ4ugAE9ikkgR03LvudU',
    appId: '1:958059982436:android:abdeef821e626a3a9c7971',
    messagingSenderId: '958059982436',
    projectId: 'mbongo-b6d1a',
    storageBucket: 'mbongo-b6d1a.firebasestorage.app',
  );
}
