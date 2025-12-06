import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Mis Pedidos")),
        body: Center(child: Text("Debes iniciar sesión para ver tus pedidos")),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("Mis Pedidos"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error al cargar pedidos: ${snapshot.error}",
                  textAlign: TextAlign.center),
            ));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 10),
                  Text("Aún no tienes pedidos",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final orderData = orders[i].data() as Map<String, dynamic>;
              final status = orderData['status'] ?? 'Pendiente';
              final total = (orderData['totalAmount'] ?? 0).toDouble();

              DateTime? date;
              if (orderData['createdAt'] != null) {
                date = (orderData['createdAt'] as Timestamp).toDate();
              }

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                                : "Fecha desconocida",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          _StatusBadge(status: status),
                        ],
                      ),
                      Divider(height: 20),

                      // --- AQUÍ ESTÁ LA CORRECCIÓN CLAVE ---
                      // Pasamos el objeto 'items' tal cual, y la función decide qué hacer
                      if (orderData['items'] != null)
                        ..._buildOrderItems(orderData['items']),

                      Divider(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Pagado",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "\$${total.toStringAsFixed(0)}",
                            style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- FUNCIÓN BLINDADA CONTRA ERRORES ---
  // Ahora acepta 'dynamic' para poder recibir Mapas O Listas sin explotar
  List<Widget> _buildOrderItems(dynamic items) {
    List<Widget> widgets = [];

    try {
      if (items is Map) {
        // CASO A: Es un MAPA (Formato nuevo/correcto)
        items.forEach((key, value) {
          final itemData = value as Map<String, dynamic>;
          widgets.add(_buildSingleItemRow(itemData));
        });
      } else if (items is List) {
        // CASO B: Es una LISTA (Formato antiguo/manual)
        for (var item in items) {
          if (item is Map<String, dynamic>) {
            widgets.add(_buildSingleItemRow(item));
          } else if (item is Map) {
            // Conversión segura si viene como Map<dynamic, dynamic>
            widgets.add(_buildSingleItemRow(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      widgets.add(Text("Error al mostrar productos: $e",
          style: TextStyle(color: Colors.red, fontSize: 10)));
    }

    return widgets;
  }

  // Helper para no repetir código visual
  Widget _buildSingleItemRow(Map<String, dynamic> itemData) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "${itemData['quantity'] ?? 1}x ",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
          ),
          Expanded(
            child: Text(
              itemData['name'] ?? 'Producto Desconocido',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text("\$${itemData['price'] ?? 0}"),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'entregado':
        color = Colors.green;
        break;
      case 'cancelado':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
