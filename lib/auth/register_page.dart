import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! Ahora inicia sesión.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Ocurrió un error desconocido.";
      
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este correo electrónico ya está en uso. Por favor, inicia sesión.';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del correo electrónico no es válido.';
          break;
        case 'network-request-failed':
          errorMessage = 'Error de red. Revisa tu conexión a internet.';
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo Electrónico'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña (mín. 6 caracteres)'), obscureText: true),
            const SizedBox(height: 16),
            TextField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirmar Contraseña'), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _register, child: const Text('Registrarse')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}