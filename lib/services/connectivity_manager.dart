import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ConnectivityManager {
  static final Connectivity _connectivity = Connectivity();
  static bool _isOnline = true;

  static Future<void> initialize() async {
    // Verificar conectividad inicial
    _isOnline = await _checkConnection();
    
    // Escuchar cambios de conectividad
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      print(_isOnline ? '🌐 Conectado a internet' : '🔌 Sin conexión a internet');
    });
  }

  static Future<bool> _checkConnection() async {
    if (kIsWeb) {
      // En web, asumimos que hay conexión (Firebase maneja los errores)
      return true;
    }
    
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static bool get isOnline => _isOnline;
  
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none
    );
  }
}