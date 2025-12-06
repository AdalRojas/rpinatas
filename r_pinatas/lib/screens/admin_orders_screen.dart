import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pedidos de Clientes")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text("No hay pedidos aún"));

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pendiente';

              DateTime? date;
              if (data['createdAt'] != null)
                date = (data['createdAt'] as Timestamp).toDate();

              return Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(
                    "Orden #${doc.id.substring(0, 5).toUpperCase()}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${date != null ? DateFormat('dd/MM HH:mm').format(date) : ''} - \$${(data['totalAmount'] ?? 0).toString()}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(status,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  children: [
                    Divider(),
                    // LISTA DE PRODUCTOS (Híbrida)
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Productos:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 5),
                          // Usamos la función inteligente aquí
                          if (data['items'] != null)
                            ..._buildOrderItems(data['items']),
                        ],
                      ),
                    ),

                    Divider(),

                    // BOTONES DE ACCIÓN
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0, right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status != 'Pendiente')
                            TextButton(
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('orders')
                                      .doc(doc.id)
                                      .update({'status': 'Pendiente'});
                                },
                                child: Text("Marcar Pendiente",
                                    style: TextStyle(color: Colors.orange))),
                          SizedBox(width: 10),
                          if (status != 'Entregado')
                            ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('orders')
                                      .doc(doc.id)
                                      .update({'status': 'Entregado'});
                                },
                                icon: Icon(Icons.check, size: 18),
                                label: Text("Entregar")),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Entregado':
        return Colors.green;
      case 'Pendiente':
        return Colors.orange;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // --- FUNCIÓN INTELIGENTE (COPIADA DE ORDERS_SCREEN) ---
  List<Widget> _buildOrderItems(dynamic items) {
    List<Widget> widgets = [];
    try {
      if (items is Map) {
        // CASO A: Mapa (Formato Nuevo)
        items.forEach((key, value) {
          final itemData = value as Map<String, dynamic>;
          widgets.add(_buildSingleItemText(itemData));
        });
      } else if (items is List) {
        // CASO B: Lista (Formato Antiguo)
        for (var item in items) {
          if (item is Map) {
            widgets.add(_buildSingleItemText(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      widgets.add(Text("Error visualizando items: $e",
          style: TextStyle(color: Colors.red)));
    }
    return widgets;
  }

  Widget _buildSingleItemText(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(Icons.arrow_right, size: 16, color: Colors.grey),
          Text(
            "${item['quantity']}x ",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          Expanded(
            child: Text(
              item['name'] ?? 'Producto',
              style: TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
