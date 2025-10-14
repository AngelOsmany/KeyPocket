import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar SQLite FFI para escritorio
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      print('🖥️ Inicializando SQLite FFI para escritorio...');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('✅ SQLite FFI inicializado');
    } else {
      print('📱 Usando SQLite nativo para móvil');
      // Para móvil, no necesitamos hacer nada, usa la implementación por defecto
    }

    _isInitialized = true;
  }
}