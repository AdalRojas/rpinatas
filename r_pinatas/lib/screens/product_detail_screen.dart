import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import 'admin_screen.dart'; // Importamos para poder ir a editar

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final bool isAdmin; // <--- ESTO ES LO QUE FALTABA

  const ProductDetailScreen(
      {Key? key,
      required this.product,
      this.isAdmin = false // Por defecto es falso si no se especifica
      })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = product.stock > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      // BOTÓN FLOTANTE DE EDICIÓN (SOLO PARA ADMIN)
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navegar a la pantalla de edición
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminScreen(productToEdit: product),
                  ),
                );
              },
              label: Text("Editar Piñata"),
              icon: Icon(Icons.edit),
              backgroundColor: Colors.blue,
            )
          : null,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN GRANDE
            Container(
              height: 400,
              width: double.infinity,
              color: Colors.white,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product.images.isNotEmpty
                        ? Image.network(product.images.first, fit: BoxFit.cover)
                        : Icon(Icons.image_not_supported,
                            size: 100, color: Colors.grey),
                  ),
                  // Sombra inferior para que se lea el texto
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.white, Colors.white.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // DETALLES
            Transform.translate(
              offset: Offset(0, -40), // Subir un poco el contenido
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.1),
                          ),
                        ),
                        Text(
                          "\$${product.price.toStringAsFixed(0)}",
                          style: TextStyle(
                              fontSize: 28,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // STOCK
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                isAvailable ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isAvailable ? Colors.green : Colors.red,
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  isAvailable
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 16,
                                  color:
                                      isAvailable ? Colors.green : Colors.red),
                              SizedBox(width: 5),
                              Text(
                                isAvailable
                                    ? "En Stock: ${product.stock}"
                                    : "Agotado",
                                style: TextStyle(
                                    color: isAvailable
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 25),
                    Text("Descripción",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                      product.description,
                      style: TextStyle(
                          color: Colors.grey[600], height: 1.6, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isAdmin
          ? Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5))
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: isAvailable
                    ? () {
                        Provider.of<CartProvider>(context, listen: false)
                            .addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("¡Agregado al carrito!"),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 1)),
                        );
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      isAvailable ? "Agregar al Carrito" : "No disponible",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(), // Si es admin, no mostramos el botón de comprar, sino el flotante de editar
    );
  }
}
