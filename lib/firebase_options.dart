import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

// TODO: Replace all placeholder values below with your Firebase project config
// Get these from: Firebase Console → Project Settings → Your apps → Web app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Only web is supported');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyAbXF6ZHnHYvQIZBdFRM44ayDaDWGCyO_Q',
    authDomain:        'learn-english-e7d67.firebaseapp.com',
    projectId:         'learn-english-e7d67',
    storageBucket:     'learn-english-e7d67.firebasestorage.app',
    messagingSenderId: '1038382941727',
    appId:             '1:1038382941727:web:2de8b3bbc3d0d1b492f72a',
  );
}
