import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class AdminScreen extends StatefulWidget {
  final Product? productToEdit;

  const AdminScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _imgCtrl;

  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '');
    _imgCtrl = TextEditingController(
        text: (p != null && p.images.isNotEmpty) ? p.images.first : '');
    _selectedCategoryId = p?.categoryId;
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación: Obligar a seleccionar categoría si quedó nula
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Por favor selecciona una categoría válida")));
      return;
    }

    final data = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'price': double.parse(_priceCtrl.text),
      'stock': int.parse(_stockCtrl.text),
      'categoryId': _selectedCategoryId,
      'images': [_imgCtrl.text],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.productToEdit == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productToEdit!.id)
            .update(data);
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Producto guardado")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.productToEdit == null
              ? "Nuevo Producto"
              : "Editar Producto")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: "Nombre"),
                validator: (v) => v!.isEmpty ? "Campo requerido" : null,
              ),
              SizedBox(height: 10),

              // --- SECCIÓN CORREGIDA (DROPDOWN INTELIGENTE) ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .snapshots(),
                builder: (ctx, snap) {
                  // Mientras carga, mostramos un indicador discreto
                  if (!snap.hasData) return LinearProgressIndicator();

                  final cats = snap.data!.docs;

                  // LÓGICA DE SEGURIDAD:
                  // Verificamos si la categoría guardada (_selectedCategoryId)
                  // realmente existe en la lista que acabamos de descargar.
                  bool categoryExists = false;
                  if (_selectedCategoryId != null) {
                    categoryExists =
                        cats.any((doc) => doc.id == _selectedCategoryId);
                  }

                  // Si la categoría antigua ("general") no existe en la lista nueva,
                  // forzamos el valor del Dropdown a null para que pida seleccionar de nuevo.
                  final valueForDropdown =
                      categoryExists ? _selectedCategoryId : null;

                  return DropdownButtonFormField<String>(
                    value: valueForDropdown,
                    decoration: InputDecoration(
                      labelText: "Categoría",
                      // Mensaje de ayuda si detectamos el error
                      helperText: !categoryExists && _selectedCategoryId != null
                          ? "La categoría antigua no existe. Selecciona una nueva."
                          : null,
                      helperStyle: TextStyle(color: Colors.orange),
                    ),
                    items: cats.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? "Requerido" : null,
                  );
                },
              ),
              // ------------------------------------------------

              SizedBox(height: 10),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(labelText: "Precio"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _stockCtrl,
                decoration: InputDecoration(labelText: "Stock Disponible"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(labelText: "Descripción"),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _imgCtrl,
                decoration: InputDecoration(
                  labelText: "URL de Imagen",
                  hintText: "https://ejemplo.com/foto.jpg",
                  suffixIcon: Icon(Icons.link),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text("GUARDAR PRODUCTO"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
