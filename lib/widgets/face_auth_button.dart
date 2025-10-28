import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

class FaceAuthButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  const FaceAuthButton({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<FaceAuthButton> createState() => _FaceAuthButtonState();
}

class _FaceAuthButtonState extends State<FaceAuthButton> {
  final BiometricService _biometricService = BiometricService();
  bool _loading = false;

  void _auth() async {
    setState(() => _loading = true);
    final ok = await _biometricService.authenticateWithFace();
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Autenticación exitosa' : 'Autenticación fallida o Face no disponible')),
    );
    if (ok && widget.onSuccess != null) widget.onSuccess!();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.face),
      label: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Autenticar con Face'),
      onPressed: _loading ? null : _auth,
    );
  }
}