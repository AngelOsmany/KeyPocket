import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ Importar el archivo completo
import 'app/my_app.dart';
import 'widgets/face_auth_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyPocket',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KeyPocket')),
      body: Center(
        child: FaceAuthButton(
          onSuccess: () {
            // ejemplo: navegar a zona segura
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurePage()));
          },
        ),
      ),
    );
  }
}

class SecurePage extends StatelessWidget {
  const SecurePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zona segura')),
      body: const Center(child: Text('Acceso concedido')),
    );
  }
}