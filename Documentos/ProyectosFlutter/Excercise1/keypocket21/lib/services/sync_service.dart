import 'package:connectivity_plus/connectivity_plus.dart';
import 'firestore_service.dart';
import 'local_storage.dart';
import '../models/category.dart';
import '../models/credential.dart';

class SyncService {
  final FirestoreService _firestore = FirestoreService();
  final Connectivity _connectivity = Connectivity();

  // Verificar conexión a internet
  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // ========== OPERACIONES HÍBRIDAS ==========

  // Guardar categoría (ambos lugares)
  Future<void> saveCategory(Category category) async {
    print('💾 Guardando categoría: ${category.name}');
    print('   - userId: ${category.userId}');
    print('   - categoryId: ${category.id}');
    
    // Siempre guardar localmente
    await LocalStorage.insertCategory(category);
    
    // Guardar en Firestore si hay conexión
    if (await isConnected) {
      try {
        await _firestore.saveCategory(category);
      } catch (e) {
        print('⚠️ No se pudo guardar en Firestore, pero se guardó localmente');
      }
    } else {
      print('📴 Sin conexión - Categoría guardada solo localmente');
    }
  }

  // Guardar credencial (ambos lugares)
  Future<void> saveCredential(Credential credential) async {
    print('💾 Guardando credencial: ${credential.title}');
    print('   - userId: ${credential.userId}');
    print('   - categoryId: ${credential.categoryId}');
    print('   - título: ${credential.title}');
    
    // Siempre guardar localmente
    await LocalStorage.insertCredential(credential);
    
    // Guardar en Firestore si hay conexión
    if (await isConnected) {
      try {
        await _firestore.saveCredential(credential);
      } catch (e) {
        print('⚠️ No se pudo guardar en Firestore, pero se guardó localmente');
      }
    } else {
      print('📴 Sin conexión - Credencial guardada solo localmente');
    }
  }

  // Obtener categorías (primero local, luego sincronizar)
  Stream<List<Category>> getCategoriesStream(String userId) {
    return _firestore.getCategoriesStream(userId);
  }

  Future<List<Category>> getCategories(String userId) async {
    print('📂 Solicitando categorías para usuario: $userId');
    
    // Primero obtener de local storage (instantáneo)
    final localCategories = await LocalStorage.getCategories(userId);
    
    // Si hay conexión, intentar sincronizar con Firestore
    if (await isConnected) {
      try {
        final cloudCategories = await _firestore.getCategories(userId);
        // Si la nube está vacía pero local tiene datos, mantener locales
        if (cloudCategories.isEmpty && localCategories.isNotEmpty) {
          print('☁️ Nube vacía, usando categorías locales (${localCategories.length})');
          return localCategories;
        }

        // Si hay diferencias (por cantidad), actualizar local con nube
        if (cloudCategories.length != localCategories.length) {
          print('🔄 Sincronizando categorías desde la nube...');
          for (final category in cloudCategories) {
            await LocalStorage.insertCategory(category);
          }
          return cloudCategories;
        }
        
        return cloudCategories;
      } catch (e) {
        print('⚠️ No se pudo obtener de Firestore, usando datos locales');
      }
    }
    
    return localCategories;
  }

  // Obtener credenciales (primero local, luego sincronizar)
  Stream<List<Credential>> getCredentialsStream(String userId, String categoryId) {
    return _firestore.getCredentialsStream(userId, categoryId);
  }

  Future<List<Credential>> getCredentialsByCategory(String userId, String categoryId) async {
  print('📂 Solicitando credenciales para:');
  print('   - userId: $userId');
  print('   - categoryId: $categoryId');
  
  // Primero obtener de local storage
  final localCredentials = await LocalStorage.getCredentialsByCategory(categoryId, userId);
  print('   - Credenciales locales encontradas: ${localCredentials.length}');
  
  // Si hay conexión, intentar sincronizar
  if (await isConnected) {
    try {
      final allCloudCredentials = await _firestore.getAllCredentials(userId);
      final cloudCredentials = allCloudCredentials
          .where((cred) => cred.categoryId == categoryId)
          .toList();

      print('   - Credenciales en la nube para esta categoría: ${cloudCredentials.length}');
      
      // Debug: mostrar info de credenciales
      for (final cred in cloudCredentials) {
        print('     🔍 Credencial nube - categoryId: ${cred.categoryId}, title: ${cred.title}');
      }

      // Si hay diferencias, actualizar local
      if (cloudCredentials.length != localCredentials.length) {
        print('🔄 Sincronizando credenciales desde la nube...');
        for (final credential in cloudCredentials) {
          await LocalStorage.insertCredential(credential);
        }
        return cloudCredentials;
      }
      
      return cloudCredentials;
    } catch (e) {
      print('⚠️ No se pudo obtener de Firestore, usando datos locales');
    }
  }
  
  return localCredentials;
}

  // Eliminar categoría (ambos lugares)
  Future<void> deleteCategory(String categoryId, String userId) async {
    print('🗑️ Eliminando categoría: $categoryId');
    
    // Siempre eliminar localmente
    await LocalStorage.deleteCategory(categoryId, userId);
    
    // Eliminar de Firestore si hay conexión
    if (await isConnected) {
      try {
        await _firestore.deleteCategory(categoryId, userId);
      } catch (e) {
        print('⚠️ No se pudo eliminar de Firestore, pero se eliminó localmente');
      }
    }
  }

  // Eliminar credencial (ambos lugares)
  Future<void> deleteCredential(String credentialId, String userId) async {
    print('🗑️ Eliminando credencial: $credentialId');
    
    // Siempre eliminar localmente
    await LocalStorage.deleteCredential(credentialId, userId);
    
    // Eliminar de Firestore si hay conexión
    if (await isConnected) {
      try {
        await _firestore.deleteCredential(credentialId, userId);
      } catch (e) {
        print('⚠️ No se pudo eliminar de Firestore, pero se eliminó localmente');
      }
    }
  }

  // Sincronizar todos los datos locales con la nube
  Future<void> syncAllData(String userId) async {
    if (!await isConnected) {
      print('📴 Sin conexión - No se puede sincronizar');
      return;
    }

    try {
      final localCategories = await LocalStorage.getCategories(userId);
      final localCredentials = await LocalStorage.getAllCredentials(userId);
      
      await _firestore.syncUserData(userId, localCategories, localCredentials);
      print('✅ Todos los datos sincronizados con Firestore');
    } catch (e) {
      print('❌ Error sincronizando datos: $e');
    }
  }

  // Método de debug para ver todas las credenciales
  Future<void> debugAllCredentials(String userId) async {
    print('=== DEBUG TODAS LAS CREDENCIALES ===');
    
    // Locales
    final localAll = await LocalStorage.getAllCredentials(userId);
    print('📱 CREDENCIALES LOCALES (${localAll.length}):');
    for (final cred in localAll) {
      print('   - ${cred.title} | categoryId: ${cred.categoryId} | userId: ${cred.userId}');
    }
    
    // De la nube (si hay conexión)
    if (await isConnected) {
      try {
        final cloudAll = await _firestore.getAllCredentials(userId);
        print('☁️ CREDENCIALES NUBE (${cloudAll.length}):');
        for (final cred in cloudAll) {
          print('   - ${cred.title} | categoryId: ${cred.categoryId} | userId: ${cred.userId}');
        }
      } catch (e) {
        print('❌ Error obteniendo credenciales de nube para debug: $e');
      }
    }
    
    print('=== FIN DEBUG ===');
  }
}