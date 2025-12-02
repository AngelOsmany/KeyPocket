import 'package:hive/hive.dart';
import '../models/category.dart';
import '../models/credential.dart';

class LocalStorage {
  static late Box _categoriesBox;
  static late Box _credentialsBox;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (!_isInitialized) {
      try {
        _categoriesBox = await Hive.openBox('categories');
        _credentialsBox = await Hive.openBox('credentials');
        _isInitialized = true;
        print('✅ Hive inicializado correctamente');
      } catch (e) {
        print('❌ Error inicializando Hive: $e');
        rethrow;
      }
    }
  }

  // ========== OPERACIONES BÁSICAS LOCALES ==========

  // Categories
  static Future<void> insertCategory(Category category) async {
    await init();
    final userCategories = await getCategories(category.userId);
    userCategories.add(category);
    await _categoriesBox.put(category.userId, _serializeCategories(userCategories));
    print('💾 Categoría guardada localmente: ${category.name}');
  }

  static Future<List<Category>> getCategories(String userId) async {
    await init();
    try {
      final dynamic categoriesData = _categoriesBox.get(userId, defaultValue: []);
      final categories = _deserializeCategories(categoriesData);
      print('📊 Categorías locales para $userId: ${categories.length}');
      return categories;
    } catch (e) {
      print('❌ Error obteniendo categorías locales: $e');
      return [];
    }
  }

  static Future<void> deleteCategory(String categoryId, String userId) async {
    await init();
    final userCategories = await getCategories(userId);
    userCategories.removeWhere((cat) => cat.id == categoryId);
    await _categoriesBox.put(userId, _serializeCategories(userCategories));
    print('🗑️ Categoría eliminada localmente: $categoryId');
  }

  // Credentials
  static Future<void> insertCredential(Credential credential) async {
    await init();
    final userCredentials = await getAllCredentials(credential.userId);
    userCredentials.add(credential);
    await _credentialsBox.put(credential.userId, _serializeCredentials(userCredentials));
    print('💾 Credencial guardada localmente: ${credential.title}');
  }

  static Future<List<Credential>> getCredentialsByCategory(String categoryId, String userId) async {
    await init();
    final allCredentials = await getAllCredentials(userId);
    final filtered = allCredentials.where((cred) => cred.categoryId == categoryId).toList();
    print('🔍 Credenciales locales en categoría $categoryId: ${filtered.length}');
    return filtered;
  }

  static Future<List<Credential>> getAllCredentials(String userId) async {
    await init();
    try {
      final dynamic credentialsData = _credentialsBox.get(userId, defaultValue: []);
      final credentials = _deserializeCredentials(credentialsData);
      return credentials;
    } catch (e) {
      print('❌ Error obteniendo credenciales locales: $e');
      return [];
    }
  }

  static Future<void> deleteCredential(String credentialId, String userId) async {
    await init();
    final userCredentials = await getAllCredentials(userId);
    userCredentials.removeWhere((cred) => cred.id == credentialId);
    await _credentialsBox.put(userId, _serializeCredentials(userCredentials));
    print('🗑️ Credencial eliminada localmente: $credentialId');
  }

  // ========== HELPERS ==========

  static List<Map<String, dynamic>> _serializeCategories(List<Category> categories) {
    return categories.map((category) => category.toLocalMap()).toList();
  }

  static List<Category> _deserializeCategories(dynamic data) {
    try {
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return Category.fromMap(item);
          }
          return Category.fromMap({});
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error deserializando categorías: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _serializeCredentials(List<Credential> credentials) {
    return credentials.map((credential) => credential.toLocalMap()).toList();
  }

  static List<Credential> _deserializeCredentials(dynamic data) {
    try {
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return Credential.fromMap(item);
          }
          return Credential.fromMap({});
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error deserializando credenciales: $e');
      return [];
    }
  }

  // Generar IDs únicos
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}