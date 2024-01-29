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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCePlj5KGq3DrziAktq7hWLYN2p0pHrXqg',
    appId: '1:840015609445:web:0fe5449c8044f279da108c',
    messagingSenderId: '840015609445',
    projectId: 'mb-uns-1103',
    authDomain: 'mb-uns-1103.firebaseapp.com',
    storageBucket: 'mb-uns-1103.appspot.com',
    measurementId: 'G-C7FNWEHN1E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyARm3rG-_bCX8KBM9_yRqKssfQYbid7V7g',
    appId: '1:840015609445:android:364e0be09803d2d4da108c',
    messagingSenderId: '840015609445',
    projectId: 'mb-uns-1103',
    storageBucket: 'mb-uns-1103.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCY-s-Y3IBTC0S4qWTTCELay2jYljhcD8I',
    appId: '1:840015609445:ios:62d9949bd406340eda108c',
    messagingSenderId: '840015609445',
    projectId: 'mb-uns-1103',
    storageBucket: 'mb-uns-1103.appspot.com',
    iosBundleId: 'com.example.mbUns',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCY-s-Y3IBTC0S4qWTTCELay2jYljhcD8I',
    appId: '1:840015609445:ios:7d080ee8e4713ee0da108c',
    messagingSenderId: '840015609445',
    projectId: 'mb-uns-1103',
    storageBucket: 'mb-uns-1103.appspot.com',
    iosBundleId: 'com.example.mbUns.RunnerTests',
  );
}
