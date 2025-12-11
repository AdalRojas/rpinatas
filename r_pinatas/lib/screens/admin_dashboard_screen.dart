import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';
import 'admin_categories_screen.dart';
import 'home_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_kanban_screen.dart'; // Asegúrate de importar el Kanban
import 'login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("Dashboard R Piñatas"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resumen del Negocio",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),

            // --- SECCIÓN DE MÉTRICAS (RECUPERADA) ---
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (ctx, orderSnap) {
                // Cálculo de datos en tiempo real
                if (!orderSnap.hasData)
                  return Center(child: LinearProgressIndicator());

                final orders = orderSnap.data!.docs;
                double totalSales = 0;
                int pendingOrders = 0;

                for (var doc in orders) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Sumamos todo lo que no esté cancelado ni rechazado
                  if (data['status'] != 'Cancelado' &&
                      data['status'] != 'Pedido Rechazado') {
                    totalSales += (data['totalAmount'] ?? 0).toDouble();
                  }
                  // Contamos pendientes o en revisión
                  if (data['status'] == 'Pendiente' ||
                      data['status'] == 'Pedido en Revisión') {
                    pendingOrders++;
                  }
                }

                return Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: "Ventas Totales",
                        value: "\$${totalSales.toStringAsFixed(0)}",
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _MetricCard(
                        title: "Por Atender",
                        value: "$pendingOrders",
                        icon: Icons.access_time_filled,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
            // ----------------------------------------

            SizedBox(height: 30),

            Text(
              "Acciones Rápidas",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),

            // --- BOTÓN 1: TABLERO KANBAN (NUEVO) ---
            _ActionTile(
              title: "Tablero Kanban",
              subtitle: "Mover pedidos visualmente (Drag & Drop)",
              icon: Icons.view_kanban,
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminKanbanScreen()),
              ),
            ),

            SizedBox(height: 10),

            // --- BOTÓN 2: VER TIENDA ---
            _ActionTile(
              title: "Ver Tienda / Catálogo",
              subtitle: "Ir al modo cliente para editar piñatas",
              icon: Icons.storefront,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              ),
            ),

            SizedBox(height: 10),

            // --- BOTÓN 3: CATEGORÍAS ---
            _ActionTile(
              title: "Categorías",
              subtitle: "Crear etiquetas (Piñatas, Dulces...)",
              icon: Icons.category,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminCategoriesScreen()),
              ),
            ),

            SizedBox(height: 10),

            // --- BOTÓN 4: LISTA PEDIDOS (ANTIGUO) ---
            _ActionTile(
              title: "Lista de Pedidos",
              subtitle: "Vista detallada en lista",
              icon: Icons.list_alt,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminOrdersScreen()),
              ),
            ),

            SizedBox(height: 10),

            // --- BOTÓN 5: AGREGAR MANUAL ---
            _ActionTile(
              title: "Agregar Producto (Manual)",
              subtitle: "Formulario directo",
              icon: Icons.add_circle,
              color: Colors.pink,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminScreen()),
              ),
            ),

            SizedBox(height: 30), // Espacio final
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _MetricCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color)),
          SizedBox(height: 15),
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)
            ]),
        child: Row(
          children: [
            Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28)),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
