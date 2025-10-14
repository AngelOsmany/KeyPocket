import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'connectivity_manager.dart';

class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Database? _database;

  // Inicializar SQLite solo cuando sea necesario
  Future<void> _initDatabaseIfNeeded() async {
    if (_database != null) return;
    
    if (!kIsWeb) {
      try {
        _database = await openDatabase(
          'keypocket.db',
          version: 1,
          onCreate: (Database db, int version) async {
            await db.execute('''
              CREATE TABLE categories(
                id TEXT PRIMARY KEY,
                name TEXT,
                createdAt INTEGER,
                synced INTEGER DEFAULT 0
              )
            ''');
            await db.execute('''
              CREATE TABLE credentials(
                id TEXT PRIMARY KEY,
                categoryId TEXT,
                username TEXT,
                password TEXT,
                synced INTEGER DEFAULT 0
              )
            ''');
            print('✅ Base de datos SQLite creada');
          },
        );
      } catch (e) {
        print('❌ Error creando SQLite: $e');
      }
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;

  // Determinar automáticamente si usar Firebase o SQLite
  bool get _shouldUseFirebase {
    if (kIsWeb) {
      // En web, siempre intentar usar Firebase primero
      return true;
    }
    return ConnectivityManager.isOnline;
  }

  Future<void> saveCategory(String name) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Usuario no autenticado');

    if (_shouldUseFirebase) {
      // Intentar con Firebase
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .add({
          'name': name,
          'createdAt': Timestamp.now(),
        });
        
        print('✅ Categoría guardada en Firebase: ${docRef.id}');
        
        // También guardar en SQLite como backup
        if (!kIsWeb) {
          await _initDatabaseIfNeeded();
          await _database?.insert(
            'categories',
            {
              'id': docRef.id,
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
        // Continuar con guardado local
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
          'name': name,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'synced': 0,
        },
      );
      print('✅ Categoría guardada localmente: $localId');
    } else {
      throw Exception('No se pudo guardar. Sin conexión y SQLite no disponible en web.');
    }
  }

  Stream<List<Map<String, dynamic>>> getCategoriesStream() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    if (_shouldUseFirebase) {
      // Stream desde Firebase con fallback a SQLite si hay error
      return _firestore
          .collection('users')
          .doc(userId)
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
            // Fallback a SQLite
            if (!kIsWeb) {
              await _initDatabaseIfNeeded();
              final categories = await _database!.query('categories');
              return categories.map((map) => ({
                'id': map['id'] as String,
                'name': map['name'] as String,
                'fromFirebase': (map['synced'] as int) == 1,
              })).toList();
            }
            return [];
          });
    } else {
      // Stream desde SQLite (modo offline)
      if (kIsWeb) {
        return Stream.value([]); // En web sin conexión, no hay datos
      }
      
      return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        await _initDatabaseIfNeeded();
        final categories = await _database!.query('categories', orderBy: 'name');
        return categories.map((map) => ({
          'id': map['id'] as String,
          'name': map['name'] as String,
          'fromFirebase': (map['synced'] as int) == 1,
        })).toList();
      });
    }
  }

  Future<void> saveCredential(String categoryId, String username, String password) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Usuario no autenticado');

    if (_shouldUseFirebase) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc(categoryId)
            .collection('credentials')
            .add({
          'username': username,
          'password': password,
        });
        
        print('✅ Credencial guardada en Firebase');
        
        if (!kIsWeb) {
          await _initDatabaseIfNeeded();
          await _database?.insert(
            'credentials',
            {
              'id': docRef.id,
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
          'categoryId': categoryId,
          'username': username,
          'password': password,
          'synced': 0,
        },
      );
      print('✅ Credencial guardada localmente');
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
          .doc(userId)
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
                where: 'categoryId = ?',
                whereArgs: [categoryId],
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
          where: 'categoryId = ?',
          whereArgs: [categoryId],
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

    // Sincronizar categorías pendientes
    final pendingCategories = await _database!.query(
      'categories',
      where: 'synced = ?',
      whereArgs: [0],
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
        });

        await _database!.update(
          'categories',
          {'id': docRef.id, 'synced': 1},
          where: 'id = ?',
          whereArgs: [category['id']],
        );
        print('✅ Categoría sincronizada: ${category['name']}');
      } catch (e) {
        print('❌ Error sincronizando categoría: $e');
      }
    }

    // Sincronizar credenciales pendientes
    final pendingCredentials = await _database!.query(
      'credentials',
      where: 'synced = ?',
      whereArgs: [0],
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
        });

        await _database!.update(
          'credentials',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [credential['id']],
        );
        print('✅ Credencial sincronizada');
      } catch (e) {
        print('❌ Error sincronizando credencial: $e');
      }
    }
  }
}