import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../providers/cart_provider.dart';
import '../models/product_model.dart';
import '../widgets/custom_image.dart';
import 'product_detail_screen.dart';
import 'admin_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado para el filtro
  String _selectedCategory = 'Todas';
  final List<String> _categories = [
    'Todas',
    'Piñatas',
    'Dulces',
    'Globos',
    'Extras',
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.pink),
              accountName: Text(user?.displayName ?? "Usuario"),
              accountEmail: Text(user?.email ?? ""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.pink),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Catálogo'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Mis Pedidos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrdersScreen()),
                );
              },
            ),

            // ZONA ADMIN
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists)
                  return const SizedBox();
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                if (userData['role'] != 'admin') return const SizedBox();

                return Column(
                  children: [
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "ADMINISTRADOR",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.dashboard,
                        color: Colors.purple,
                      ),
                      title: const Text('Dashboard del Negocio'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: () => AuthService().signOut(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "R Piñatas",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartScreen()),
                ),
              ),
              if (cart.totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Column(
        children: [
          // --- BARRA DE FILTROS ---
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.pink,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.grey[200],
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // --- LISTA DE PRODUCTOS ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // CONSULTA INTELIGENTE: Si es "Todas", trae todo. Si no, filtra.
              stream: _selectedCategory == 'Todas'
                  ? FirebaseFirestore.instance
                        .collection('products')
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('products')
                        .where('categoryId', isEqualTo: _selectedCategory)
                        .snapshots(),
              builder: (ctx, productSnap) {
                if (productSnap.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                // Obtener Rol
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .get(),
                  builder: (context, userSnap) {
                    bool isAdmin = false;
                    if (userSnap.hasData && userSnap.data!.exists) {
                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>;
                      isAdmin = userData['role'] == 'admin';
                    }

                    List<Product> products = [];
                    if (productSnap.hasData &&
                        productSnap.data!.docs.isNotEmpty) {
                      products = productSnap.data!.docs
                          .map(
                            (doc) => Product.fromMap(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                            ),
                          )
                          .toList();
                    }

                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "No hay productos en '$_selectedCategory'",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.70,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: products.length,
                      itemBuilder: (ctx, i) =>
                          _ProductCard(product: products[i], isAdmin: isAdmin),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// TARJETA DE PRODUCTO (Igual que antes)
class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isAdmin;

  const _ProductCard({required this.product, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(
      context,
      listen: false,
    ); // Optimización

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomImage(
                      imageUrl: product.images.isNotEmpty
                          ? product.images[0]
                          : '',
                      borderRadius: 20,
                    ),
                  ),
                  if (isAdmin)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminScreen(productToEdit: product),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${product.price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!isAdmin)
                        GestureDetector(
                          onTap: () {
                            cart.addItem(product);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Agregado +1"),
                                duration: Duration(milliseconds: 500),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.add_circle,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar Producto?"),
        content: Text("Estás a punto de borrar '${product.name}'."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(product.id)
                  .delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Producto eliminado")),
              );
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
