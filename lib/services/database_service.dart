import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;
  static bool get isSupported => !kIsWeb; // SQLite no soportado en web

  static Future<Database?> get database async {
    if (kIsWeb) {
      print('⚠️ SQLite no está disponible en web');
      return null;
    }

    if (_database != null) return _database!;

    try {
      _database = await openDatabase(
        'keypocket.db',
        version: 1,
        onCreate: _createTables,
      );
      print('✅ Base de datos SQLite inicializada');
      return _database!;
    } catch (e) {
      print('❌ Error inicializando SQLite: $e');
      return null;
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id TEXT PRIMARY KEY,
        name TEXT,
        userId TEXT,
        createdAt INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS credentials(
        id TEXT PRIMARY KEY,
        categoryId TEXT,
        username TEXT,
        password TEXT,
        userId TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');
  }


  // 🔹 Verificar y crear columna userId en tablas existentes (migración en caliente)
  static Future<void> _ensureUserIdColumnExists(Database db) async {
    // categories
    final catInfo = await db.rawQuery("PRAGMA table_info('categories')");
    final catHasUserId = catInfo.any((row) => row['name'] == 'userId');
    if (!catHasUserId) {
      try {
        await db.execute("ALTER TABLE categories ADD COLUMN userId TEXT");
      } catch (e) {
        print('⚠️ No se pudo agregar columna userId a categories: $e');
      }
    }

    // credentials
    final credInfo = await db.rawQuery("PRAGMA table_info('credentials')");
    final credHasUserId = credInfo.any((row) => row['name'] == 'userId');
    if (!credHasUserId) {
      try {
        await db.execute("ALTER TABLE credentials ADD COLUMN userId TEXT");
      } catch (e) {
        print('⚠️ No se pudo agregar columna userId a credentials: $e');
      }
    }
  }

  static Future<void> close() async {
    if (!kIsWeb) {
      await _database?.close();
      _database = null;
    }
  }
}