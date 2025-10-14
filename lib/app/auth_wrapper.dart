import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';
import '../services/connectivity_manager.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    await ConnectivityManager.initialize();
    
    // Escuchar cambios de conectividad
    ConnectivityManager.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() {}); // Redibujar cuando cambie la conexión
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // Mostrar estado de conexión
        final isOnline = ConnectivityManager.isOnline;
        
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error, isOnline);
        }
        
        if (snapshot.hasData) {
          return _buildHomeWithConnectionStatus(isOnline);
        }
        
        return _buildLoginWithConnectionStatus(isOnline);
      },
    );
  }

  Widget _buildHomeWithConnectionStatus(bool isOnline) {
    return Stack(
      children: [
        HomePage(), // QUITAR const
        if (!isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'MODO OFFLINE - Trabajando localmente',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoginWithConnectionStatus(bool isOnline) {
    return Stack(
      children: [
        const LoginPage(), // Este sí puede ser const
        if (!isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'SIN CONEXIÓN - Algunas funciones limitadas',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorScreen(Object? error, bool isOnline) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Error de aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            Text(
              isOnline ? '🌐 Conectado' : '🔌 Sin conexión',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                );
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}