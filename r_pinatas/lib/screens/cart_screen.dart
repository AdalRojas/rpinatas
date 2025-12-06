import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import 'payment_screen.dart'; // <--- IMPORTANTE: Importar pantalla de pago

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items;
    final details = cart.productDetails;

    return Scaffold(
      appBar: AppBar(title: Text("Tu Carrito (${cart.totalItems})")),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text("El carrito está vacío",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      String productId = items.keys.elementAt(i);
                      int quantity = items.values.elementAt(i);
                      var product = details[productId];

                      return Dismissible(
                        key: Key(productId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          cart.removeItem(productId);
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              child: product!.images.isNotEmpty
                                  ? Image.network(product.images.first,
                                      fit: BoxFit.cover)
                                  : Icon(Icons.image),
                            ),
                            title: Text(product.name),
                            subtitle: Text("\$${product.price} x $quantity"),
                            trailing: Text(
                              "\$${(product.price * quantity).toStringAsFixed(0)}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total:",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("\$${cart.totalAmount.toStringAsFixed(0)}",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink),
                          // --- AQUÍ ESTÁ EL CAMBIO ---
                          onPressed: () {
                            // En lugar de procesar, vamos a PAGAR
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PaymentScreen()),
                            );
                          },
                          // ---------------------------
                          child: Text("Ir a Pagar",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
