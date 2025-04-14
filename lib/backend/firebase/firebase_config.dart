import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAtK5zTjyt6ZlzJxrnfENuwTPBdmdoEN9U",
            authDomain: "road-asisstance.firebaseapp.com",
            projectId: "road-asisstance",
            storageBucket: "road-asisstance.firebasestorage.app",
            messagingSenderId: "593816543777",
            appId: "1:593816543777:web:7ad106b965f9f69e903960",
            measurementId: "G-6GLH57ZV3P"));
  } else {
    await Firebase.initializeApp();
  }
}
