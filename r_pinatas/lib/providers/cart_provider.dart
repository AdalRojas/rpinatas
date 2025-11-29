import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, int> _items = {};
  final Map<String, Product> _products = {};

  Map<String, int> get items => _items;
  Map<String, Product> get productDetails =>
      _products; // Para acceder a los detalles

  // ARREGLO: Esto suma las cantidades reales (Ej: 2 Batman + 1 Unicornio = 3)
  int get totalItems {
    int count = 0;
    _items.forEach((key, quantity) {
      count += quantity;
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

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(product.id, (existing) => existing + 1);
    } else {
      _items.putIfAbsent(product.id, () => 1);
      _products.putIfAbsent(product.id, () => product);
    }
    notifyListeners();
  }

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

  void clearCart() {
    _items.clear();
    _products.clear();
    notifyListeners();
  }
}
