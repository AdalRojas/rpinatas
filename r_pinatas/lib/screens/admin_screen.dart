import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Eliminamos la importación de product_model que no se usaba

class AdminScreen extends StatefulWidget {
  // Agregamos la 'key' para quitar la advertencia azul
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newProduct = {
        'name': _nameController.text,
        'description': _descController.text,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'categoryId': 'general',
        'images': [_imageUrlController.text],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('products').add(newProduct);

      // --- CORRECCIÓN DE SENIOR ---
      // Verificamos si la pantalla sigue "montada" (activa) antes de usar 'context'
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Producto Guardado!")));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agregar Nuevo Producto")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nombre del Producto",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Precio (\$)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Stock",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: "Descripción",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: "URL de la Imagen (Link de internet)",
                  border: OutlineInputBorder(),
                  helperText: "Ej: https://i.imgur.com/example.jpg",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(15),
                ),
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text("GUARDAR EN LA NUBE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
