import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/credential.dart';
import '../../services/sync_service.dart';
import '../../services/biometric_service.dart';

class CredentialsScreen extends StatefulWidget {
  final String userId;
  final String? categoryId;
  final String? categoryName;

  const CredentialsScreen({
    Key? key,
    required this.userId,
    this.categoryId,
    this.categoryName,
  }) : super(key: key);

  @override
  _CredentialsScreenState createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  List<Credential> _credentials = [];
  bool _obscurePassword = true;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    print('🎯 CredentialsScreen iniciado:');
    print('   - userId: ${widget.userId}');
    print('   - categoryId: ${widget.categoryId}');
    print('   - categoryName: ${widget.categoryName}');
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      setState(() => _isLoading = true);
      if (widget.categoryId != null) {
        final syncService = Provider.of<SyncService>(context, listen: false);
        final credentials = await syncService.getCredentialsByCategory(
          widget.userId,       // ← PRIMERO: userId
          widget.categoryId!,
        );
        setState(() {
          _credentials = credentials;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error cargando credenciales: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddCredentialDialog() {
    if (widget.categoryId == null) {
      _showErrorDialog('No se puede agregar credencial', 'Primero selecciona una categoría');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CredentialDialog(
        userId: widget.userId,
        categoryId: widget.categoryId!, // ¡Pasar el categoryId correcto!
        onSaved: _loadCredentials,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCredential(String id) async {
    try {
      final syncService = Provider.of<SyncService>(context, listen: false);
      await syncService.deleteCredential(id, widget.userId);
      await _loadCredentials();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credencial eliminada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error eliminando credencial: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error eliminando credencial'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _debugCredentials() async {
    final syncService = Provider.of<SyncService>(context, listen: false);
    await syncService.debugAllCredentials(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Todas las Credenciales'),
        actions: [
          // Botón de debug temporal
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _debugCredentials,
            tooltip: 'Debug credenciales',
          ),
        ],
      ),
      body: widget.categoryId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Selecciona una categoría',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Para agregar credenciales, primero selecciona una categoría',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _isLoading
              ? Center(child: CircularProgressIndicator())
              : _credentials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay credenciales',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Agrega tu primera credencial',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _credentials.length,
                      itemBuilder: (context, index) {
                        final credential = _credentials[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: Icon(Icons.lock, color: Colors.green),
                            title: Text(
                              credential.title,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text('Usuario: ${credential.username}'),
                                Text('Email: ${credential.email}'),
                                Text(
                                  'Contraseña: ${_obscurePassword || !_isAuthenticated ? '••••••••' : credential.password}',
                                ),
                                if (credential.website != null) 
                                  Text('Sitio: ${credential.website}'),
                                if (credential.notes != null) 
                                  Text('Notas: ${credential.notes}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    if (_obscurePassword) {
                                      // Si está oculta, intentar autenticación biométrica
                                      print('👆 Usuario presionó el botón para ver contraseñas');
                                      
                                      final authenticated = await _biometricService.authenticate(
                                        localizedReason: 'Autentícate para ver tus contraseñas',
                                      );
                                      
                                      print('🔐 Resultado de autenticación: $authenticated');
                                      
                                      if (authenticated) {
                                        setState(() {
                                          _isAuthenticated = true;
                                          _obscurePassword = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Autenticación exitosa'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Autenticación fallida. Verifica la consola de debug para más detalles.'),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } else {
                                      // Si ya está visible, simplemente ocultarla
                                      setState(() {
                                        _obscurePassword = true;
                                        _isAuthenticated = false;
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteConfirmation(credential),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: widget.categoryId != null
          ? FloatingActionButton(
              onPressed: _showAddCredentialDialog,
              child: Icon(Icons.add),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  void _showDeleteConfirmation(Credential credential) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Credencial'),
        content: Text('¿Estás seguro de que quieres eliminar la credencial "${credential.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCredential(credential.id);
            },
            child: Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

class CredentialDialog extends StatefulWidget {
  final String userId;
  final String categoryId; // ¡Este es el ID correcto de la categoría!
  final VoidCallback onSaved;

  const CredentialDialog({
    Key? key,
    required this.userId,
    required this.categoryId, // Recibimos el categoryId correcto
    required this.onSaved,
  }) : super(key: key);

  @override
  _CredentialDialogState createState() => _CredentialDialogState();
}

class _CredentialDialogState extends State<CredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  Future<void> _saveCredential() async {
    if (!_formKey.currentState!.validate()) return;

    // ¡IMPORTANTE! Usar widget.categoryId que es el ID correcto de la categoría
    final credential = Credential(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      website: _websiteController.text.isEmpty ? null : _websiteController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      categoryId: widget.categoryId, // ← ¡ESTE ES EL ID CORRECTO!
      userId: widget.userId,
      createdAt: DateTime.now(),
    );

    // LOG DE DIAGNÓSTICO
    print('🎯 CREANDO CREDENCIAL:');
    print('   - userId: ${credential.userId}');
    print('   - categoryId: ${credential.categoryId}');
    print('   - title: ${credential.title}');

    try {
      final syncService = Provider.of<SyncService>(context, listen: false);
      await syncService.saveCredential(credential);
      
      _titleController.clear();
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _websiteController.clear();
      _notesController.clear();
      
      widget.onSaved();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credencial "${credential.title}" guardada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error guardando credencial: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando credencial'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nueva Credencial'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una contraseña';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(
                  labelText: 'Website (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveCredential,
          child: Text('Guardar'),
        ),
      ],
    );
  }
}