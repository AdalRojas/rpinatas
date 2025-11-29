// ESTE ARCHIVO ES VITAL PARA CONECTAR CON FIREBASE
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // HEMOS QUITADO EL IF/ELSE PARA QUE FUNCIONE EN WEB (CHROME) Y ANDROID
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    // 1. TU API KEY REAL (Sacada de tu captura):
    apiKey: 'AIzaSyBUoFRDQzx6_O5Zqchx78H15qdr9itc_cU',

    // 2. TU APP ID REAL:
    appId: '1:704805194188:android:44112d52a4bc9e04ffb569',

    // 3. TU SENDER ID REAL:
    messagingSenderId: '704805194188',

    // 4. TU PROYECTO:
    projectId: 'r-pinatas',

    // ESTÁNDAR:
    storageBucket: 'r-pinatas.firebasestorage.app',
  );
}
