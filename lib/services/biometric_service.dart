import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Comprueba si el dispositivo soporta biometría facial
  Future<bool> hasFace() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.contains(BiometricType.face);
    } catch (_) {
      return false;
    }
  }

  // Autentica usando solo biometría (face)
  Future<bool> authenticateWithFace({String reason = 'Autentícate con tu cara'}) async {
    final isFace = await hasFace();
    if (!isFace) return false;
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      return didAuth;
    } catch (_) {
      return false;
    }
  }
}