import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminKanbanScreen extends StatelessWidget {
  // 5 ESTADOS DEFINIDOS
  final List<String> statuses = [
    "Pedido en Revisión",
    "Pedido Autorizado (Pagado)",
    "En proceso",
    "Entregado",
    "Pedido Rechazado"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tablero Kanban de Pedidos")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          // Construimos el Tablero con scroll horizontal
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statuses.map((status) {
                // Filtramos los pedidos para esta columna
                final ordersInThisColumn = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  // Si no tiene status, asumimos "Pedido en Revisión"
                  final docStatus = data['status'] ?? "Pedido en Revisión";
                  return docStatus == status;
                }).toList();

                return _buildKanbanColumn(context, status, ordersInThisColumn);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKanbanColumn(
      BuildContext context, String title, List<QueryDocumentSnapshot> orders) {
    Color headerColor;
    switch (title) {
      case "Pedido en Revisión":
        headerColor = Colors.orange;
        break;
      case "Pedido Autorizado (Pagado)":
        headerColor = Colors.blue;
        break;
      case "En proceso":
        headerColor = Colors.purple;
        break;
      case "Entregado":
        headerColor = Colors.green;
        break;
      case "Pedido Rechazado":
        headerColor = Colors.red;
        break;
      default:
        headerColor = Colors.grey;
    }

    return Container(
      width: 280, // Ancho de la columna
      margin: EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // CABECERA DE LA COLUMNA
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            width: double.infinity,
            child: Text(
              "$title (${orders.length})",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // ZONA DE ARRASTRE (DRAG TARGET)
          Expanded(
            child: DragTarget<String>(
              // Cuando recibimos una tarjeta
              onAccept: (orderId) {
                FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .update({'status': title});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Pedido movido a: $title"),
                  duration: Duration(milliseconds: 500),
                ));
              },
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) {
                    final order = orders[i];
                    return _buildDraggableCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final clientName = data['clientName'] ?? 'Cliente';
    final total = data['totalAmount'] ?? 0;

    // Contenido de la tarjeta
    final cardContent = Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(clientName, style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Total: \$${total.toStringAsFixed(0)}"),
            SizedBox(height: 5),
            Text(
              "ID: ${doc.id.substring(0, 4).toUpperCase()}",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    // Widget que permite arrastrar
    return Draggable<String>(
      data: doc.id, // Enviamos el ID del pedido al arrastrar
      feedback: Material(
        // Lo que se ve flotando mientras arrastras
        color: Colors.transparent,
        child: Container(
          width: 260,
          child: Opacity(opacity: 0.7, child: cardContent),
        ),
      ),
      childWhenDragging: Opacity(
          // Lo que queda en el hueco original
          opacity: 0.3,
          child: cardContent),
      child: cardContent, // Tarjeta normal
    );
  }
}
