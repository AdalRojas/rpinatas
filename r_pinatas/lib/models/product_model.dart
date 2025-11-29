// Modelo de Producto para mapear desde/hacia Firestore
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.images,
  });

  // Factory para crear un objeto Product desde un documento de Firebase (Map)
  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: data['stock'] ?? 0,
      categoryId: data['categoryId'] ?? '',
      // Aseguramos que la lista sea de Strings
      images: List<String>.from(data['images'] ?? []),
    );
  }

  // Método para convertir nuestro objeto a Map para guardarlo en Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'images': images,
    };
  }
}
