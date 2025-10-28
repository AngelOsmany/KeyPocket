import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'connectivity_manager.dart';

class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Database? _database;
  static String? _cachedUserId;

  // Permitir establecer cache del userId (llamar desde login/logout)
  void setCachedUserId(String? id) {
    _cachedUserId = id;
  }

  // Cargar userId cache desde SharedPreferences
  Future<void> _loadCachedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUserId = prefs.getString('userId');
    } catch (_) {}
  }

  // Obtener el ID del usuario actual

  String? get currentUserId => _auth.currentUser?.uid ?? _cachedUserId;

  // Verificar si hay usuario autenticado
  bool get isUserAuthenticated => _auth.currentUser != null;

  // Inicializar SQLite solo cuando sea necesario
  Future<void> _initDatabaseIfNeeded() async {
    if (_database != null || kIsWeb) return;
    // Cargar userId cache para poder usarlo aún sin conexión
    await _loadCachedUserId();
    
    try {
      _database = await openDatabase(
        'keypocket.db',
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE categories(
              id TEXT PRIMARY KEY,
              userId TEXT,
              name TEXT,
              createdAt INTEGER,
              synced INTEGER DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE credentials(
              id TEXT PRIMARY KEY,
              userId TEXT,
              categoryId TEXT,
              username TEXT,
              password TEXT,
              synced INTEGER DEFAULT 0
            )
          ''');
          print('✅ Base de datos SQLite creada con relaciones de usuario');
        },
      );
    } catch (e) {
      print('❌ Error creando SQLite: $e');
    }
  }

  bool get _shouldUseFirebase {
    if (kIsWeb) return true;
    return ConnectivityManager.isOnline;
  }

  // --- OPERACIONES PARA CATEGORÍAS ---

  Future<void> saveCategory(String name) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Usuario no autenticado');

    if (_shouldUseFirebase) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(userId) // 🔥 RELACIÓN CON USUARIO
            .collection('categories')
            .add({
          'name': name,
          'createdAt': Timestamp.now(),
          'userId': userId, // 🔥 GUARDAR USER ID EN EL DOCUMENTO
        });
        
        print('✅ Categoría guardada en Firebase para usuario: $userId');
        
        // También guardar en SQLite como backup
        if (!kIsWeb) {
          await _initDatabaseIfNeeded();
          await _database?.insert(
            'categories',
            {
              'id': docRef.id,
              'userId': userId, // 🔥 RELACIÓN EN SQLITE
              'name': name,
              'createdAt': DateTime.now().millisecondsSinceEpoch,
              'synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return;
      } catch (e) {
        print('❌ Error con Firebase, guardando localmente: $e');
      }
    }

    // Guardar en SQLite (modo offline o fallback)
    if (!kIsWeb) {
      await _initDatabaseIfNeeded();
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      await _database!.insert(
        'categories',
        {
          'id': localId,
          'userId': userId, // 🔥 RELACIÓN EN SQLITE
          'name': name,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'synced': 0,
        },
      );
      print('✅ Categoría guardada localmente para usuario: $userId');
    } else {
      throw Exception('No se pudo guardar. Sin conexión y SQLite no disponible en web.');
    }
  }

  Stream<List<Map<String, dynamic>>> getCategoriesStream() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    if (_shouldUseFirebase) {
      // Stream desde Firebase - SOLO categorías del usuario actual
      return _firestore
          .collection('users')
          .doc(userId) // 🔥 SOLO categorías de ESTE usuario
          .collection('categories')
          .orderBy('name')
          .snapshots()
          .asyncMap((snapshot) async {
            // Actualizar SQLite con datos de Firebase
            if (!kIsWeb) {
              await _initDatabaseIfNeeded();
              for (final doc in snapshot.docs) {
                await _database?.insert(
                  'categories',
                  {
                    'id': doc.id,
                    'userId': userId,
                    'name': doc['name'],
                    'createdAt': (doc['createdAt'] as Timestamp).millisecondsSinceEpoch,
                    'synced': 1,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
            return snapshot.docs.map((doc) => {
              'id': doc.id,
              'name': doc['name'],
              'fromFirebase': true,
            }).toList();
          })
          .handleError((error) async {
            print('❌ Error con Firebase stream, usando datos locales: $error');
            // Fallback a SQLite - SOLO categorías del usuario
            if (!kIsWeb) {
              await _initDatabaseIfNeeded();
              final categories = await _database!.query(
                'categories',
                where: 'userId = ?', // 🔥 FILTRAR POR USUARIO
                whereArgs: [userId],
                orderBy: 'name',
              );
              return categories.map((map) => ({
                'id': map['id'] as String,
                'name': map['name'] as String,
                'fromFirebase': (map['synced'] as int) == 1,
              })).toList();
            }
            return [];
          });
    } else {
      // Stream desde SQLite - SOLO categorías del usuario actual
      if (kIsWeb) return Stream.value([]);
      
      return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        await _initDatabaseIfNeeded();
        final categories = await _database!.query(
          'categories',
          where: 'userId = ?', // 🔥 FILTRAR POR USUARIO
          whereArgs: [userId],
          orderBy: 'name',
        );
        return categories.map((map) => ({
          'id': map['id'] as String,
          'name': map['name'] as String,
          'fromFirebase': (map['synced'] as int) == 1,
        })).toList();
      });
    }
  }

  // --- OPERACIONES PARA CREDENCIALES ---

  Future<void> saveCredential(String categoryId, String username, String password) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Usuario no autenticado');

    if (_shouldUseFirebase) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(userId) // 🔥 RELACIÓN CON USUARIO
            .collection('categories')
            .doc(categoryId)
            .collection('credentials')
            .add({
          'username': username,
          'password': password,
          'userId': userId, // 🔥 GUARDAR USER ID
        });
        
        print('✅ Credencial guardada en Firebase para usuario: $userId');
        
        if (!kIsWeb) {
          await _initDatabaseIfNeeded();
          await _database?.insert(
            'credentials',
            {
              'id': docRef.id,
              'userId': userId, // 🔥 RELACIÓN EN SQLITE
              'categoryId': categoryId,
              'username': username,
              'password': password,
              'synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return;
      } catch (e) {
        print('❌ Error con Firebase, guardando localmente: $e');
      }
    }

    if (!kIsWeb) {
      await _initDatabaseIfNeeded();
      final localId = 'cred_local_${DateTime.now().millisecondsSinceEpoch}';
      await _database!.insert(
        'credentials',
        {
          'id': localId,
          'userId': userId, // 🔥 RELACIÓN EN SQLITE
          'categoryId': categoryId,
          'username': username,
          'password': password,
          'synced': 0,
        },
      );
      print('✅ Credencial guardada localmente para usuario: $userId');
    } else {
      throw Exception('No se pudo guardar. Sin conexión.');
    }
  }

  Stream<List<Map<String, dynamic>>> getCredentialsStream(String categoryId) {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    if (_shouldUseFirebase) {
      return _firestore
          .collection('users')
          .doc(userId) // 🔥 SOLO credenciales de ESTE usuario
          .collection('categories')
          .doc(categoryId)
          .collection('credentials')
          .snapshots()
          .asyncMap((snapshot) async {
            if (!kIsWeb) {
              await _initDatabaseIfNeeded();
              for (final doc in snapshot.docs) {
                await _database?.insert(
                  'credentials',
                  {
                    'id': doc.id,
                    'userId': userId,
                    'categoryId': categoryId,
                    'username': doc['username'],
                    'password': doc['password'],
                    'synced': 1,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
            return snapshot.docs.map((doc) => ({
              'id': doc.id,
              'username': doc['username'],
              'password': doc['password'],
              'fromFirebase': true,
            })).toList();
          })
          .handleError((error) async {
            print('❌ Error con Firebase stream, usando datos locales: $error');
            if (!kIsWeb) {
              await _initDatabaseIfNeeded();
              final credentials = await _database!.query(
                'credentials',
                where: 'userId = ? AND categoryId = ?', // 🔥 FILTRAR POR USUARIO Y CATEGORÍA
                whereArgs: [userId, categoryId],
              );
              return credentials.map((map) => ({
                'id': map['id'] as String,
                'username': map['username'] as String,
                'password': map['password'] as String,
                'fromFirebase': (map['synced'] as int) == 1,
              })).toList();
            }
            return [];
          });
    } else {
      if (kIsWeb) return Stream.value([]);
      
      return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        await _initDatabaseIfNeeded();
        final credentials = await _database!.query(
          'credentials',
          where: 'userId = ? AND categoryId = ?', // 🔥 FILTRAR POR USUARIO Y CATEGORÍA
          whereArgs: [userId, categoryId],
        );
        return credentials.map((map) => ({
          'id': map['id'] as String,
          'username': map['username'] as String,
          'password': map['password'] as String,
          'fromFirebase': (map['synced'] as int) == 1,
        })).toList();
      });
    }
  }

  // Sincronizar datos locales cuando se recupere la conexión
  Future<void> syncPendingData() async {
    if (kIsWeb || _database == null) return;

    final userId = currentUserId;
    if (userId == null) return;

    // Sincronizar categorías pendientes del usuario actual
    final pendingCategories = await _database!.query(
      'categories',
      where: 'synced = ? AND userId = ?', // 🔥 SOLO del usuario actual
      whereArgs: [0, userId],
    );

    for (final category in pendingCategories) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .add({
          'name': category['name'] as String,
          'createdAt': Timestamp.now(),
          'userId': userId,
        });

        await _database!.update(
          'categories',
          {'id': docRef.id, 'synced': 1},
          where: 'id = ? AND userId = ?',
          whereArgs: [category['id'], userId],
        );
        print('✅ Categoría sincronizada: ${category['name']}');
      } catch (e) {
        print('❌ Error sincronizando categoría: $e');
      }
    }

    // Sincronizar credenciales pendientes del usuario actual
    final pendingCredentials = await _database!.query(
      'credentials',
      where: 'synced = ? AND userId = ?', // 🔥 SOLO del usuario actual
      whereArgs: [0, userId],
    );

    for (final credential in pendingCredentials) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc(credential['categoryId'] as String)
            .collection('credentials')
            .add({
          'username': credential['username'] as String,
          'password': credential['password'] as String,
          'userId': userId,
        });

        await _database!.update(
          'credentials',
          {'synced': 1},
          where: 'id = ? AND userId = ?',
          whereArgs: [credential['id'], userId],
        );
        print('✅ Credencial sincronizada para usuario: $userId');
      } catch (e) {
        print('❌ Error sincronizando credencial: $e');
      }
    }
  }

  // Limpiar datos locales cuando el usuario cierre sesión
  Future<void> clearLocalData() async {
    if (kIsWeb || _database == null) return;

    final userId = currentUserId;
    if (userId == null) return;

    try {
      // Eliminar solo los datos del usuario actual
      await _database!.delete(
        'categories',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await _database!.delete(
        'credentials', 
        where: 'userId = ?',
        whereArgs: [userId],
      );
      print('✅ Datos locales eliminados para usuario: $userId');
    } catch (e) {
      print('❌ Error eliminando datos locales: $e');
    }
  }
}