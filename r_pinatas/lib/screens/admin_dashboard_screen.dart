import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';
import 'admin_categories_screen.dart';
import 'home_screen.dart'; // <--- IMPORTANTE: Importar el Home
import 'admin_orders_screen.dart';
import 'admin_dashboard_screen.dart'; // <--- IMPORT PARA PODER REGRESAR
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
                (route) => false, // Esto borra todas las pantallas anteriores
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
            // ... (El código de las métricas/gráficas se queda igual que antes) ...
            // (Si lo borraste, avísame y te lo paso, pero asumo que ya lo tienes)

            Text(
              "Acciones Rápidas",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),

            // --- BOTÓN 1: VER TIENDA (NUEVO) ---
            _ActionTile(
              title: "Ver Tienda / Catálogo",
              subtitle: "Ir al modo cliente para editar piñatas visualmente",
              icon: Icons.storefront,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        HomeScreen()), // <--- Aquí te lleva al catálogo
              ),
            ),

            SizedBox(height: 10),

            // --- BOTÓN 2: CATEGORÍAS ---
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

            // --- BOTÓN 3: GESTIONAR PEDIDOS ---
            _ActionTile(
              title: "Gestionar Pedidos",
              subtitle: "Ver lista de pedidos y cambiar estado",
              icon: Icons.local_shipping,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminOrdersScreen()),
              ),
            ),

            SizedBox(height: 10),

            // --- BOTÓN 4: AGREGAR MANUAL ---
            _ActionTile(
              title: "Agregar Producto (Manual)",
              subtitle: "Formulario directo sin ver tienda",
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

// ... (Las clases _MetricCard y _ActionTile siguen igual abajo) ...
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
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
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
