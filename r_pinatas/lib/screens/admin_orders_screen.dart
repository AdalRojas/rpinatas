import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pedidos de Clientes")),
      body: StreamBuilder<QuerySnapshot>(
        // CONSULTA: Traer TODOS los pedidos ordenados por fecha
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No hay pedidos pendientes."));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final doc = orders[i];
              final order = doc.data() as Map<String, dynamic>;
              final items = order['items'] as List<dynamic>;
              final status = order['status'] ?? 'Pendiente';
              final total = order['totalAmount'] ?? 0.0;
              final userEmail = order['userEmail'] ?? 'Anónimo';

              // Colores según estado
              Color statusColor = Colors.orange;
              if (status == 'Entregado') statusColor = Colors.green;
              if (status == 'En Proceso') statusColor = Colors.blue;

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(Icons.assignment, color: statusColor),
                  ),
                  title: Text(
                    userEmail,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ), // Muestra QUIÉN compró
                  subtitle: Text("\$${total.toStringAsFixed(0)} • $status"),
                  children: [
                    // LISTA DE PRODUCTOS
                    ...items
                        .map(
                          (item) => ListTile(
                            title: Text(item['name']),
                            trailing: Text("x${item['quantity']}"),
                          ),
                        )
                        .toList(),

                    Divider(),

                    // BOTONES PARA CAMBIAR ESTADO
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "Cambiar Estado:",
                            style: TextStyle(color: Colors.grey),
                          ),
                          ActionChip(
                            label: Text("En Proceso"),
                            backgroundColor: Colors.blue[50],
                            onPressed: () =>
                                _updateStatus(context, doc.id, 'En Proceso'),
                          ),
                          ActionChip(
                            label: Text("Entregado"),
                            backgroundColor: Colors.green[50],
                            onPressed: () =>
                                _updateStatus(context, doc.id, 'Entregado'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(BuildContext context, String docId, String newStatus) {
    FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': newStatus,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Pedido marcado como $newStatus"),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
