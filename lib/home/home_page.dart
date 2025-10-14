import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/data_repository.dart';
import '../services/mode_manager.dart';
import 'category_details_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _categoryNameController = TextEditingController();
  final DataRepository _dataRepository = DataRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          // Selector de modo Online/Offline
          Row(
            children: [
              Icon(
                ModeManager.isOnlineMode ? Icons.cloud : Icons.cloud_off,
                color: ModeManager.isOnlineMode ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Switch(
                value: ModeManager.isOnlineMode,
                onChanged: (value) async {
                  await ModeManager.setOnlineMode(value);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Modo ONLINE activado' : 'Modo OFFLINE activado',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _dataRepository.getCategoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No hay categorías. ¡Añade una!"),
                  const SizedBox(height: 20),
                  Text(
                    ModeManager.isOnlineMode ? '🌐 Modo Online' : '📱 Modo Offline',
                    style: TextStyle(
                      color: ModeManager.isOnlineMode ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final categories = snapshot.data!;

          return Column(
            children: [
              // Indicador de modo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: ModeManager.isOnlineMode ? Colors.green[50] : Colors.orange[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ModeManager.isOnlineMode ? Icons.cloud : Icons.cloud_off,
                      color: ModeManager.isOnlineMode ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ModeManager.isOnlineMode ? 'MODO ONLINE' : 'MODO OFFLINE',
                      style: TextStyle(
                        color: ModeManager.isOnlineMode ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: categories.map((category) {
                    return ListTile(
                      title: Text(category['name']),
                      subtitle: Text(
                        category['fromFirebase'] ? 'En la nube' : 'Solo local',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailsPage(
                              categoryId: category['id'],
                              categoryName: category['name'],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        tooltip: 'Crear Categoría',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Crear Nueva Categoría'),
          content: TextField(
            controller: _categoryNameController,
            decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _addCategory(dialogContext),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _addCategory(BuildContext context) async {
    if (_categoryNameController.text.isNotEmpty) {
      try {
        await _dataRepository.saveCategory(_categoryNameController.text);
        _categoryNameController.clear();
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Categoría guardada en ${ModeManager.isOnlineMode ? 'la nube' : 'localmente'}',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}