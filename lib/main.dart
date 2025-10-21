import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ Importar el archivo completo
import 'app/my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando aplicación...');
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // ✅ Usar todas las plataformas
    );
    print('✅ Firebase inicializado para: ${DefaultFirebaseOptions.currentPlatform.appId}');
  } catch (e) {
    print('❌ Error con Firebase: $e');
  }
  
  runApp(const MyApp());
}