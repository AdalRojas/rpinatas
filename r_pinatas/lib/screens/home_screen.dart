import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'admin_screen.dart';
import 'admin_dashboard_screen.dart'; // <--- IMPORT NUEVO PARA PODER REGRESAR
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = "";
  String? _selectedCategory;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  void _checkAdmin() async {
    String role = await AuthService().getUserRole();
    setState(() {
      _isAdmin = (role == 'admin');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          appBar: AppBar(
            title: _isAdmin
                ? Text("Modo Tienda (Admin)")
                : Text("Catálogo R Piñatas"),
            backgroundColor: _isAdmin
                ? Colors.deepPurple
                : Theme.of(context)
                    .primaryColor, // Color diferente para que sepas que eres admin
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CartScreen())),
                  ),
                  if (cart.totalItems > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(10)),
                        constraints:
                            BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('${cart.totalItems}',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
            ],
          ),
          drawer: _buildDrawer(context),
          body: Column(
            children: [
              // 1. BARRA DE BÚSQUEDA
              Padding(
                padding: EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Buscar piñata...",
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),

              // 2. FILTROS
              Container(
                height: 50,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .orderBy('name')
                      .snapshots(),
                  builder: (ctx, catSnap) {
                    if (!catSnap.hasData) return SizedBox();
                    final categories = catSnap.data!.docs;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      itemCount: categories.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0)
                          return _buildCategoryChip(
                              "Todos",
                              _selectedCategory == null,
                              () => setState(() => _selectedCategory = null));
                        final doc = categories[i - 1];
                        return _buildCategoryChip(
                            doc['name'],
                            _selectedCategory == doc.id,
                            () => setState(() => _selectedCategory = doc.id));
                      },
                    );
                  },
                ),
              ),

              // 3. PRODUCTOS
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .snapshots(),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                      return Center(child: Text("No hay productos"));

                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['name'] ?? '').toString().toLowerCase();
                      final categoryId = data['categoryId'] ?? '';
                      bool matchesSearch = name.contains(_searchQuery);
                      bool matchesCategory = _selectedCategory == null ||
                          categoryId == _selectedCategory;
                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (filteredDocs.isEmpty)
                      return Center(
                          child: Text("No se encontraron resultados"));

                    return GridView.builder(
                      padding: EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (ctx, i) {
                        final data =
                            filteredDocs[i].data() as Map<String, dynamic>;
                        final product =
                            Product.fromMap(data, filteredDocs[i].id);
                        final bool isOutOfStock = product.stock <= 0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Pasamos el parámetro isAdmin correctamente
                                  builder: (_) => ProductDetailScreen(
                                      product: product, isAdmin: _isAdmin),
                                ));
                          },
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(15)),
                                          color: Colors.grey[200],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(15)),
                                          child: ColorFiltered(
                                            colorFilter: isOutOfStock
                                                ? ColorFilter.mode(Colors.grey,
                                                    BlendMode.saturation)
                                                : ColorFilter.mode(
                                                    Colors.transparent,
                                                    BlendMode.multiply),
                                            child: product.images.isNotEmpty
                                                ? Image.network(
                                                    product.images.first,
                                                    fit: BoxFit.cover)
                                                : Icon(Icons.image,
                                                    color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                              "\$${product.price.toStringAsFixed(0)}",
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (isOutOfStock)
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -0.2,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.red, width: 2),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Text("AGOTADO",
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_isAdmin)
                                  Positioned(
                                    right: 5,
                                    top: 5,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      radius: 18,
                                      child: IconButton(
                                        icon: Icon(Icons.edit,
                                            size: 18, color: Colors.blue),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AdminScreen(
                                                    productToEdit: product),
                                              ));
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.black),
      ),
    );
  }

  // --- DRAWER ACTUALIZADO CON BOTÓN DE REGRESO ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
                color: _isAdmin
                    ? Colors.deepPurple
                    : Theme.of(context).primaryColor),
            accountName: Text(_isAdmin ? "Administrador" : "Cliente R Piñatas"),
            accountEmail: Text(AuthService().currentUser?.email ?? ""),
            currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person,
                    color: _isAdmin
                        ? Colors.deepPurple
                        : Theme.of(context).primaryColor)),
          ),

          // --- BOTÓN EXCLUSIVO PARA ADMIN: VOLVER AL DASHBOARD ---
          if (_isAdmin)
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.deepPurple),
              title: Text('Volver al Dashboard',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                // Regresar a la pantalla anterior (que debería ser el Dashboard)
                Navigator.pop(context);
              },
            ),

          if (_isAdmin) Divider(), // Separador visual

          ListTile(
            leading: Icon(Icons.history),
            title: Text('Mis Pedidos (Prueba)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => OrdersScreen()));
            },
          ),
          ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService().signOut();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              }),
        ],
      ),
    );
  }
}
