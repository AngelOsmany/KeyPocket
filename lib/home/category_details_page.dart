import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/data_repository.dart';

class CategoryDetailsPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDetailsPage({super.key, required this.categoryId, required this.categoryName});

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final DataRepository _dataRepository = DataRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // initSQLite ya no es necesario, se inicializa automáticamente
  }

  // ... el resto del código permanece igual
  void _addCredential() async {
    if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      try {
        await _dataRepository.saveCredential(
          widget.categoryId,
          _usernameController.text,
          _passwordController.text,
        );

        _usernameController.clear();
        _passwordController.clear();
        FocusScope.of(context).unfocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credencial guardada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCredentialDetails(String username, String password) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Credencial Completa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: $username'),
            const SizedBox(height: 8),
            Text('Contraseña: $password'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cerrar'))],
      ),
    );
  }

  void _showAdminPasswordPrompt(String username, String password) {
    _adminPasswordController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verificar Administrador'),
        content: TextField(
          controller: _adminPasswordController,
          decoration: const InputDecoration(labelText: 'Contraseña de la cuenta'),
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final localPasswordCheck = _adminPasswordController.text == 'password';
              Navigator.of(dialogContext).pop();
              if (localPasswordCheck) {
                _showCredentialDetails(username, password);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contraseña incorrecta')),
                );
              }
            },
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Usuario no encontrado")));

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Correo o Usuario'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _addCredential,
                child: const Text('Guardar Credencial'),
              ),
            ),
            const Divider(height: 40),
            const Text(
              'Credenciales Guardadas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _dataRepository.getCredentialsStream(widget.categoryId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No hay credenciales guardadas."));
                  }

                  final credentials = snapshot.data!;

                  return ListView(
                    children: credentials.map((credential) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text('Usuario: ${credential['username']}'),
                          subtitle: Text(credential['fromFirebase'] ? 'En la nube' : 'Solo local'),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'Ver credencial',
                            onPressed: () => _showAdminPasswordPrompt(
                              credential['username'],
                              credential['password'],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}