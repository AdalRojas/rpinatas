import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NECESARIO PARA GUARDAR
import 'package:firebase_auth/firebase_auth.dart'; // NECESARIO PARA SABER QUIEN COMPRA
import '../providers/cart_provider.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final products = cart.productDetails;

    // Función para guardar el pedido en Firebase
    Future<void> _processOrder() async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: No identificado")));
        return;
      }

      setState(() => _isProcessing = true);

      try {
        // 1. Preparar los datos de los items
        final List<Map<String, dynamic>> orderItems = [];
        cart.items.forEach((productId, quantity) {
          final product = products[productId]!;
          orderItems.add({
            'productId': productId,
            'name': product.name,
            'price': product.price,
            'quantity': quantity,
            'image': product.images.isNotEmpty ? product.images[0] : '',
          });
        });

        // 2. Crear el objeto del pedido
        final orderData = {
          'userId': user.uid,
          'userEmail': user.email,
          'totalAmount': cart.totalAmount,
          'status': 'Pendiente', // RF-03.4 Estado inicial
          'createdAt': FieldValue.serverTimestamp(),
          'items': orderItems,
        };

        // 3. Guardar en Firestore (Colección 'orders')
        await FirebaseFirestore.instance.collection('orders').add(orderData);

        // 4. Limpiar carrito y éxito
        cart.clearCart();

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            icon: Icon(Icons.check_circle, color: Colors.green, size: 60),
            title: Text("¡Pedido Recibido!"),
            content: Text("Tu compra ha sido registrada correctamente."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra dialogo
                  Navigator.pop(context); // Regresa al Home
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PaymentScreen(totalAmount: cart.totalAmount),
                    ),
                  );
                },
                child: Text("Entendido"),
              ),
            ],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al procesar: $e")));
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Mi Carrito", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Tu carrito está vacío",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      String productId = cart.items.keys.elementAt(i);
                      int quantity = cart.items.values.elementAt(i);
                      var product = products[productId]!;

                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(
                                  product.images.isNotEmpty
                                      ? product.images[0]
                                      : '',
                                ),
                                fit: BoxFit.cover,
                              ),
                              color: Colors.grey[200],
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text("${quantity} x \$${product.price}"),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[300]),
                            onPressed: () => cart.removeSingleItem(productId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total:", style: TextStyle(fontSize: 18)),
                            Text(
                              "\$${cart.totalAmount}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _processOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                            ),
                            child: _isProcessing
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    "CONFIRMAR COMPRA",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
