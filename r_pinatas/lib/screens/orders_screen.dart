import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ELIMINAMOS LA IMPORTACIÓN DE INTL QUE CAUSABA EL ERROR

class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Mis Pedidos", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(), // Quitamos el orderBy por un momento para evitar errores de índices
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 70, color: Colors.grey[300]),
                  Text(
                    "No tienes pedidos pasados.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final order = orders[i].data() as Map<String, dynamic>;
              final items = order['items'] as List<dynamic>;
              final status = order['status'] ?? 'Pendiente';
              final total = order['totalAmount'] ?? 0.0;

              // TRUCO: Convertir fecha sin usar paquete intl
              String fecha = "Fecha desconocida";
              if (order['createdAt'] != null) {
                DateTime dt = (order['createdAt'] as Timestamp).toDate();
                fecha = "${dt.day}/${dt.month}/${dt.year}";
              }

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink[50],
                    child: Icon(Icons.inventory_2, color: Colors.pink),
                  ),
                  title: Text("Pedido del $fecha"),
                  subtitle: Text(
                    "\$${total.toStringAsFixed(0)} • $status",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: status == 'Entregado'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  children: items.map((item) {
                    return ListTile(
                      dense: true,
                      title: Text(item['name']),
                      trailing: Text("x${item['quantity']}"),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
