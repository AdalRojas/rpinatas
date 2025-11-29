import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen.dart'; // Para ir a agregar productos
import 'admin_orders_screen.dart'; // Para ir a ver pedidos

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("Dashboard del Negocio"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Resumen del Día",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),

            // --- SECCIÓN DE TARJETAS DE MÉTRICAS (STREAMBUILDER) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (ctx, orderSnap) {
                if (!orderSnap.hasData) return LinearProgressIndicator();

                // Lógica de Negocio: Calcular ventas de HOY
                double ventasHoy = 0;
                int pedidosHoy = 0;
                final now = DateTime.now();

                for (var doc in orderSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['createdAt'] != null) {
                    DateTime date = (data['createdAt'] as Timestamp).toDate();
                    // Comparamos si es el mismo día, mes y año
                    if (date.day == now.day &&
                        date.month == now.month &&
                        date.year == now.year) {
                      ventasHoy += (data['totalAmount'] ?? 0).toDouble();
                      pedidosHoy += 1;
                    }
                  }
                }

                return Row(
                  children: [
                    _MetricCard(
                      title: "Ventas Hoy",
                      value: "\$${ventasHoy.toStringAsFixed(0)}",
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    SizedBox(width: 15),
                    _MetricCard(
                      title: "Pedidos Hoy",
                      value: "$pedidosHoy",
                      icon: Icons.shopping_bag,
                      color: Colors.blue,
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 15),

            // --- SECCIÓN DE STOCK BAJO ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('stock', isLessThan: 5)
                  .snapshots(),
              builder: (ctx, productSnap) {
                if (!productSnap.hasData) return SizedBox();
                int lowStockCount = productSnap.data!.docs.length;

                return _MetricCard(
                  title: "Alerta Stock Bajo",
                  value: "$lowStockCount productos",
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                  isWide: true,
                );
              },
            ),

            SizedBox(height: 30),
            Text(
              "Acciones Rápidas",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),

            // --- BOTONES DE ACCIÓN ---
            _ActionTile(
              title: "Gestionar Pedidos",
              subtitle: "Ver pedidos pendientes de entrega",
              icon: Icons.local_shipping,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminOrdersScreen()),
              ),
            ),
            SizedBox(height: 10),
            _ActionTile(
              title: "Agregar Producto",
              subtitle: "Crear piñata o artículo nuevo",
              icon: Icons.add_circle,
              color: Colors.pink,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para las tarjetas de números
class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: isWide ? 0 : 1,
      child: Container(
        width: isWide ? double.infinity : null,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                SizedBox(width: 10),
                if (isWide)
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (!isWide) SizedBox(height: 10),
            if (!isWide)
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para los botones de lista
class _ActionTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
