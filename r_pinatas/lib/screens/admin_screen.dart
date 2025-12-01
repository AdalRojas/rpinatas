import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart'; // Asegúrate de importar el modelo

class AdminScreen extends StatefulWidget {
  final Product?
  productToEdit; // Si es null, estamos CREANDO. Si trae datos, estamos EDITANDO.

  const AdminScreen({super.key, this.productToEdit});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Piñatas'; // Categoría por defecto

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // SI ESTAMOS EDITANDO, LLENAMOS LOS CAMPOS CON LOS DATOS DEL PRODUCTO
    if (widget.productToEdit != null) {
      _nameController.text = widget.productToEdit!.name;
      _descController.text = widget.productToEdit!.description;
      _priceController.text = widget.productToEdit!.price.toString();
      _stockController.text = widget.productToEdit!.stock.toString();
      _selectedCategory = widget
          .productToEdit!
          .categoryId; // Asumiendo que categoryId guarda el nombre visual
      if (widget.productToEdit!.images.isNotEmpty) {
        _imageUrlController.text = widget.productToEdit!.images[0];
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productData = {
        'name': _nameController.text,
        'description': _descController.text,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'categoryId': _selectedCategory, // Guardamos la categoría seleccionada
        'images': [_imageUrlController.text],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.productToEdit == null) {
        // --- MODO CREAR ---
        productData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("¡Producto Creado!")));
      } else {
        // --- MODO EDITAR ---
        await FirebaseFirestore.instance
            .collection('products')
            .doc(
              widget.productToEdit!.id,
            ) // Usamos el ID del producto para actualizar
            .update(productData);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("¡Producto Actualizado!")));
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Título dinámico
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Producto" : "Nuevo Producto"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre del Producto",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Precio (\$)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Stock",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // SELECTOR DE CATEGORÍA SIMPLE
              DropdownButtonFormField<String>(
                value:
                    [
                      'Piñatas',
                      'Dulces',
                      'Globos',
                      'Extras',
                    ].contains(_selectedCategory)
                    ? _selectedCategory
                    : 'Piñatas',
                decoration: const InputDecoration(
                  labelText: "Categoría",
                  border: OutlineInputBorder(),
                ),
                items: ['Piñatas', 'Dulces', 'Globos', 'Extras'].map((
                  String category,
                ) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: "URL Imagen",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),

              // PREVIEW DE IMAGEN (Para ver si el link funciona)
              if (_imageUrlController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 100,
                    child: Image.network(
                      _imageUrlController.text,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProduct,
                icon: isEditing
                    ? const Icon(Icons.save)
                    : const Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? "GUARDAR CAMBIOS" : "CREAR PRODUCTO"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
