import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/my_app.dart';

// Configuración específica para web
const firebaseConfig = FirebaseOptions(
  apiKey: 'AIzaSyCW067iCfEz4XNzA3O4MfLLGLTTk48W39g',
  appId: '1:88088570075:web:5e0847226b14a62f6ac4fe',
  messagingSenderId: '88088570075',
  projectId: 'keypocket-da8ee',
  authDomain: 'keypocket-da8ee.firebaseapp.com',
  storageBucket: 'keypocket-da8ee.firebasestorage.app',
  measurementId: 'G-7MTCYSMLJV',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando aplicación...');
  
  try {
    await Firebase.initializeApp(options: firebaseConfig);
    print('✅ Firebase inicializado');
  } catch (e) {
    print('❌ Error con Firebase: $e');
  }
  
  runApp(const MyApp());
}