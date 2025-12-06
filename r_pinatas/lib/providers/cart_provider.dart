import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  // Mapa de ID -> Cantidad
  final Map<String, int> _items = {};
  // Mapa de ID -> Objeto Producto (para tener precio, nombre, etc.)
  final Map<String, Product> _products = {};

  Map<String, int> get items => _items;
  Map<String, Product> get productDetails => _products;

  // Total de artículos
  int get totalItems {
    int count = 0;
    _items.forEach((key, quantity) => count += quantity);
    return count;
  }

  // Monto total en dinero
  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, quantity) {
      if (_products.containsKey(key)) {
        total += _products[key]!.price * quantity;
      }
    });
    return total;
  }

  // Agregar item con validación básica local
  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      // Validamos visualmente que no se pase del stock que "conocemos"
      if (_items[product.id]! < product.stock) {
        _items.update(product.id, (existing) => existing + 1);
      } else {
        // Opcional: Podrías notificar aquí que se alcanzó el límite
        print("Límite de stock alcanzado localmente");
      }
    } else {
      if (product.stock > 0) {
        _items.putIfAbsent(product.id, () => 1);
        _products.putIfAbsent(product.id, () => product);
      }
    }
    notifyListeners();
  }

  // Eliminar un solo item
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

  // Limpiar carrito
  void clearCart() {
    _items.clear();
    _products.clear();
    notifyListeners();
  }

  // --- LÓGICA DE COMPRA SEGURA (TRANSACCIÓN) ---
  // Retorna true si fue exitoso, lanza error si falla.
  Future<void> placeOrder(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // Usamos runTransaction para asegurar operaciones atómicas
    await firestore.runTransaction((transaction) async {
      double calculatedTotal = 0.0;

      // 1. LECTURA Y VALIDACIÓN
      for (var entry in _items.entries) {
        String productId = entry.key;
        int quantityNeeded = entry.value;

        DocumentReference productRef =
            firestore.collection('products').doc(productId);
        DocumentSnapshot productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception("El producto ${productId} ya no existe.");
        }

        // Obtenemos el stock REAL actual de la base de datos
        int currentStock = productDoc.get('stock');
        double price = (productDoc.get('price') ?? 0).toDouble();
        String name = productDoc.get('name');

        if (currentStock < quantityNeeded) {
          throw Exception(
              "Lo sentimos, '$name' se agotó. Stock actual: $currentStock");
        }

        calculatedTotal += price * quantityNeeded;
      }

      // 2. ESCRITURA (Si pasamos la validación, descontamos stock)
      for (var entry in _items.entries) {
        DocumentReference productRef =
            firestore.collection('products').doc(entry.key);
        transaction
            .update(productRef, {'stock': FieldValue.increment(-entry.value)});
      }

      // 3. CREAR LA ORDEN
      DocumentReference orderRef = firestore.collection('orders').doc();
      transaction.set(orderRef, {
        'userId': userId,
        'amount': calculatedTotal,
        'totalAmount': calculatedTotal, // Para compatibilidad con tu dashboard
        'items': _items.map((key, value) => MapEntry(key, {
              'quantity': value,
              'name': _products[key]?.name ?? 'Producto',
              'price': _products[key]?.price ?? 0,
            })),
        'status': 'Pendiente',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // Si la transacción no falló, limpiamos el carrito local
    clearCart();
  }
}
