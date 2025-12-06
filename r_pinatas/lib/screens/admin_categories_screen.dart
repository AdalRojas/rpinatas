import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCategoriesScreen extends StatelessWidget {
  // Controlador para el campo de texto del diálogo
  final TextEditingController _nameController = TextEditingController();

  // Función para mostrar el diálogo de Agregar/Editar
  void _showCategoryDialog(BuildContext context, {DocumentSnapshot? doc}) {
    // Si es edición, ponemos el nombre actual
    if (doc != null) {
      _nameController.text = doc['name'];
    } else {
      _nameController.clear();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc == null ? "Nueva Categoría" : "Editar Categoría"),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Nombre de la categoría",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) return;

              final name = _nameController.text.trim();
              final navigator = Navigator.of(ctx); // Guardamos ref para cerrar

              try {
                if (doc == null) {
                  // CREAR
                  await FirebaseFirestore.instance
                      .collection('categories')
                      .add({
                    'name': name,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  // ACTUALIZAR
                  await FirebaseFirestore.instance
                      .collection('categories')
                      .doc(doc.id)
                      .update({'name': name});
                }
                navigator.pop(); // Cerrar diálogo
              } catch (e) {
                print("Error: $e");
              }
            },
            child: Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestionar Categorías"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCategoryDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .orderBy('name') // Orden alfabético
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No hay categorías.\n¡Agrega la primera!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("¿Eliminar categoría?"),
                      content: Text(
                          "Esto no borrará los productos asociados, pero podrían quedar sin categoría visible."),
                      actions: [
                        TextButton(
                            child: Text("No"),
                            onPressed: () => Navigator.pop(ctx, false)),
                        TextButton(
                            child: Text("Sí, borrar"),
                            onPressed: () => Navigator.pop(ctx, true)),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  FirebaseFirestore.instance
                      .collection('categories')
                      .doc(doc.id)
                      .delete();
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink[50],
                    child: Text(
                      data['name'].toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                          color: Colors.pink, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(data['name'],
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Icon(Icons.edit, color: Colors.grey),
                  onTap: () => _showCategoryDialog(context, doc: doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
