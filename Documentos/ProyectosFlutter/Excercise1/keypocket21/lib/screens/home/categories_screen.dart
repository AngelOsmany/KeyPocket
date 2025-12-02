import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../services/sync_service.dart';
import 'credentials_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String userId;

  const CategoriesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _categoryNameController = TextEditingController();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      final syncService = Provider.of<SyncService>(context, listen: false);
      final categories = await syncService.getCategories(widget.userId);
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando categorías: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory() async {
    if (_categoryNameController.text.isEmpty) return;

    final newCategory = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _categoryNameController.text,
      userId: widget.userId,
      createdAt: DateTime.now(),
    );

    try {
      final syncService = Provider.of<SyncService>(context, listen: false);
      await syncService.saveCategory(newCategory);
      _categoryNameController.clear();
      await _loadCategories(); // Recargar después de guardar
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Categoría "${newCategory.name}" guardada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error agregando categoría: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando categoría'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nueva Categoría'),
        content: TextField(
          controller: _categoryNameController,
          decoration: InputDecoration(
            hintText: 'Nombre de la categoría',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _addCategory,
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String id) async {
    try {
      final syncService = Provider.of<SyncService>(context, listen: false);
      await syncService.deleteCategory(id, widget.userId);
      await _loadCategories();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Categoría eliminada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error eliminando categoría: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error eliminando categoría'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncData() async {
    try {
      final syncService = Provider.of<SyncService>(context, listen: false);
      await syncService.syncAllData(widget.userId);
      await _loadCategories(); // Recargar después de sincronizar
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Datos sincronizados con la nube'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error sincronizando: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sincronizando datos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Categorías'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _syncData,
            tooltip: 'Sincronizar con la nube',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay categorías',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Agrega una nueva categoría para comenzar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.category, color: Colors.blue),
                        title: Text(
                          category.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Creada: ${_formatDate(category.createdAt)}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(category),
                        ),
                        onTap: () {
                          print('🎯 NAVEGANDO A CREDENCIALES:');
                          print('   - userId: ${widget.userId}');
                          print('   - categoryId: ${category.id}');
                          print('   - categoryName: ${category.name}');
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CredentialsScreen(
                                userId: widget.userId,
                                categoryId: category.id, // ¡IMPORTANTE: category.id!
                                categoryName: category.name,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de que quieres eliminar la categoría "${category.name}"? También se eliminarán todas sus credenciales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCategory(category.id);
            },
            child: Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}