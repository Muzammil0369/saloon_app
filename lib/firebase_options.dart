import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
        return const FirebaseOptions(
          apiKey: 'AIzaSyD5boyAKlClcBuLrCir0BWD_prHoI2q8N8',
          authDomain: 'saloon-app-d8686.firebaseapp.com',
          projectId: 'saloon-app-d8686',
          storageBucket: 'saloon-app-d8686.firebasestorage.app',
          messagingSenderId: '324975557388',
          appId: '1:324975557388:web:568eda2683964f86a42729',
        );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyD0RHz9bl-05jcqnCCFzV9vsVnDLrz__S4',
          appId: '1:324975557388:android:b7b3a145fb798b2fa42729',
          messagingSenderId: '324975557388',
          projectId: 'saloon-app-d8686',
          storageBucket: 'saloon-app-d8686.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS not configured');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows not configured');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}
