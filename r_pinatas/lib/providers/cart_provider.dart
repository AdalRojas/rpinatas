import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartProvider with ChangeNotifier {
  Map<String, int> _items = {};
  Map<String, Product> _products =
      {}; // Cache local de productos para info rápida

  Map<String, int> get items => _items;
  Map<String, Product> get productDetails => _products;

  int get totalItems {
    int count = 0;
    _items.forEach((key, value) {
      count += value;
    });
    return count;
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, quantity) {
      if (_products.containsKey(key)) {
        total += _products[key]!.price * quantity;
      }
    });
    return total;
  }

  // Agregar producto al carrito
  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(product.id, (existing) => existing + 1);
    } else {
      _items.putIfAbsent(product.id, () => 1);
      _products.putIfAbsent(product.id, () => product);
    }
    notifyListeners();
  }

  // Quitar un solo ítem
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]! > 1) {
      _items.update(productId, (existing) => existing - 1);
    } else {
      _items.remove(productId);
      _products.remove(productId);
    }
    notifyListeners();
  }

  // Eliminar producto completo del carrito
  void removeItem(String productId) {
    _items.remove(productId);
    _products.remove(productId);
    notifyListeners();
  }

  // Vaciar carrito
  void clearCart() {
    _items = {};
    _products = {};
    notifyListeners();
  }

  // --- AQUÍ ESTÁ LA LÓGICA DE COMPRA ---
  Future<void> placeOrder(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // Se usa runTransaction para asegurar que el stock no cambie mientras compramos
    await firestore.runTransaction((transaction) async {
      double calculatedTotal = 0.0;

      // 1. (NUEVO) BUSCAR EL NOMBRE DEL CLIENTE EN LA BASE DE DATOS
      // Leemos el documento del usuario para sacar su 'fullName'
      DocumentReference userRef = firestore.collection('users').doc(userId);
      DocumentSnapshot userDoc = await transaction.get(userRef);

      String clientName = "Cliente (Sin nombre)";

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        // Si tiene el campo fullName, lo usamos
        if (userData.containsKey('fullName')) {
          clientName = userData['fullName'];
        }
      }

      // 2. VERIFICAR STOCK
      for (var entry in _items.entries) {
        String productId = entry.key;
        int quantityNeeded = entry.value;

        DocumentReference productRef =
            firestore.collection('products').doc(productId);
        DocumentSnapshot productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception("El producto ya no existe.");
        }

        int currentStock = productDoc.get('stock');
        if (currentStock < quantityNeeded) {
          throw Exception("Stock insuficiente para: ${productDoc.get('name')}");
        }

        double price = (productDoc.get('price') ?? 0).toDouble();
        calculatedTotal += price * quantityNeeded;
      }

      // 3. ACTUALIZAR STOCK (Restar)
      for (var entry in _items.entries) {
        DocumentReference productRef =
            firestore.collection('products').doc(entry.key);
        transaction
            .update(productRef, {'stock': FieldValue.increment(-entry.value)});
      }

      // 4. CREAR LA ORDEN (CON EL NOMBRE CORRECTO)
      DocumentReference orderRef = firestore.collection('orders').doc();

      transaction.set(orderRef, {
        'userId': userId,
        'clientName': clientName,
        'totalAmount': calculatedTotal,
        'items': _items.map((key, value) => MapEntry(key, {
              'quantity': value,
              'name': _products[key]?.name ?? 'Producto',
              'price': _products[key]?.price ?? 0,
            })),
        'status': 'Pendiente', // Estado inicial
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // Si todo salió bien, vaciamos el carrito local
    clearCart();
  }
}
