import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for your app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Values from your google-services.json
    return const FirebaseOptions(
      apiKey: 'AIzaSyCHko14jfDqLVtUrzoI6b4_8qR8XbBSVkU',
      appId: '1:851088787303:android:b3757379dbd15ff98b11c2',
      messagingSenderId: '851088787303',
      projectId: 'alphamini-a291d',
      storageBucket: 'alphamini-a291d.firebasestorage.app',
      databaseURL:
          'https://alphamini-a291d-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
  }
}
