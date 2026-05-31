import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyALotba81Kr1sMZdLkbXnK8Y54fQgg_qz4',
    authDomain: 'financeapp-e95f8.firebaseapp.com',
    projectId: 'financeapp-e95f8',
    storageBucket: 'financeapp-e95f8.firebasestorage.app',
    messagingSenderId: '12259720484',
    appId: '1:12259720484:web:17654828064a89d39707b1',
  );
}