import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatelessWidget {
  final List<String> validStatuses = [
    "Pedido en Revisión",
    "Pedido Autorizado (Pagado)",
    "En proceso",
    "Entregado",
    "Pedido Rechazado"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(title: Text("Lista Detallada de Pedidos")),
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
            padding: EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;

              final clientName = data['clientName'] ?? 'Cliente (Sin Nombre)';
              String currentStatus = data['status'] ?? 'Pedido en Revisión';
              if (currentStatus == 'Pendiente')
                currentStatus = 'Pedido en Revisión';

              final total = (data['totalAmount'] ?? 0).toDouble();

              DateTime? date;
              if (data['createdAt'] != null)
                date = (data['createdAt'] as Timestamp).toDate();

              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getStatusColor(currentStatus).withOpacity(0.1),
                    child: Icon(Icons.person,
                        color: _getStatusColor(currentStatus)),
                  ),
                  title: Text(
                    clientName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total: \$${total.toStringAsFixed(0)}"),
                      Text(
                        date != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                            : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(currentStatus),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getShortStatus(currentStatus),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  children: [
                    Divider(),

                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Productos:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700])),
                          if (data['items'] != null)
                            ..._buildOrderItems(data['items']),
                        ],
                      ),
                    ),

                    Divider(),

                    // --- SECCIÓN CORREGIDA (NO MÁS OVERFLOW) ---
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        // Eliminamos mainAxisAlignment: spaceBetween para controlar mejor el espacio
                        children: [
                          Text("Cambiar Estado:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 10), // Un pequeño espacio

                          // USAMOS EXPANDED: "Ocupa todo el espacio restante, pero no más"
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded:
                                      true, // <--- CLAVE: Ajustar texto al ancho disponible
                                  value: validStatuses.contains(currentStatus)
                                      ? currentStatus
                                      : null,
                                  hint: Text("Seleccionar"),
                                  items: validStatuses.map((String status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle,
                                              size: 10,
                                              color: _getStatusColor(status)),
                                          SizedBox(width: 8),
                                          // Usamos Flexible para que el texto se corte si es muy largo
                                          Flexible(
                                            child: Text(
                                              status,
                                              style: TextStyle(fontSize: 13),
                                              overflow: TextOverflow
                                                  .ellipsis, // <--- CLAVE: Puntos suspensivos
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(doc.id)
                                          .update({'status': newStatus});
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
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
      case "Pedido en Revisión":
        return Colors.orange;
      case "Pedido Autorizado (Pagado)":
        return Colors.blue;
      case "En proceso":
        return Colors.purple;
      case "Entregado":
        return Colors.green;
      case "Pedido Rechazado":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getShortStatus(String status) {
    if (status.contains("Autorizado")) return "Autorizado";
    if (status.contains("Revisión")) return "Revisión";
    return status;
  }

  List<Widget> _buildOrderItems(dynamic items) {
    List<Widget> widgets = [];
    try {
      if (items is Map) {
        items.forEach((key, value) {
          final itemData = value as Map<String, dynamic>;
          widgets.add(_buildSingleItemText(itemData));
        });
      } else if (items is List) {
        for (var item in items) {
          if (item is Map) {
            widgets.add(_buildSingleItemText(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      widgets.add(Text("Error items"));
    }
    return widgets;
  }

  Widget _buildSingleItemText(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text("• ", style: TextStyle(color: Colors.grey)),
          Text(
            "${item['quantity']}x ",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              item['name'] ?? 'Producto',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
