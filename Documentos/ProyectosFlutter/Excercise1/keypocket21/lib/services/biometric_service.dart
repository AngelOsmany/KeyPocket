import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica si el dispositivo tiene capacidad biométrica
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      print('🔍 canCheckBiometrics: $canCheck');
      return canCheck;
    } on PlatformException catch (e) {
      print('Error verificando biométricos: $e');
      return false;
    }
  }

  /// Verifica si hay biométricos disponibles en el dispositivo
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      print('🔍 isDeviceSupported: $isSupported');
      return isSupported;
    } on PlatformException catch (e) {
      print('Error verificando soporte del dispositivo: $e');
      return false;
    }
  }

  /// Obtiene la lista de métodos biométricos disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error obteniendo biométricos disponibles: $e');
      return [];
    }
  }

  /// Autentica al usuario usando biométricos
  /// Retorna true si la autenticación fue exitosa
  Future<bool> authenticate({
    String localizedReason = 'Por favor autentícate para ver tus contraseñas',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // Verificar si el dispositivo soporta biométricos
      final isSupported = await isDeviceSupported();
      print('🔍 Dispositivo soporta biométricos: $isSupported');
      if (!isSupported) {
        print('❌ Dispositivo no soporta biométricos');
        return false;
      }

      // Verificar si hay biométricos disponibles
      final canCheck = await canCheckBiometrics();
      print('🔍 Puede verificar biométricos: $canCheck');
      if (!canCheck) {
        print('❌ No se pueden verificar biométricos');
        return false;
      }

      // Obtener lista de biométricos disponibles
      final availableBiometrics = await getAvailableBiometrics();
      print('🔍 Biométricos disponibles: $availableBiometrics');
      if (availableBiometrics.isEmpty) {
        print('❌ No hay biométricos configurados en el dispositivo');
        return false;
      }

      print('✅ Biométricos disponibles: $availableBiometrics');
      print('🔐 Iniciando autenticación...');

      // Autenticar
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Permite usar PIN como fallback
        ),
      );

      if (authenticated) {
        print('✅ Autenticación biométrica exitosa');
      } else {
        print('❌ Autenticación biométrica fallida');
      }

      return authenticated;
    } on PlatformException catch (e) {
      print('❌ PlatformException: ${e.code}');
      print('❌ Message: ${e.message}');
      print('❌ Details: ${e.details}');
      
      if (e.code == auth_error.notAvailable) {
        print('❌ Biométricos no disponibles en este dispositivo');
      } else if (e.code == auth_error.notEnrolled) {
        print('❌ No hay biométricos registrados en el dispositivo');
      } else if (e.code == auth_error.lockedOut || 
                 e.code == auth_error.permanentlyLockedOut) {
        print('❌ Biométricos bloqueados temporalmente');
      } else {
        print('❌ Error durante autenticación: ${e.code} - ${e.message}');
      }
      return false;
    } catch (e) {
      print('❌ Error inesperado: $e');
      return false;
    }
  }
}
