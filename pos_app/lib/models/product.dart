class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;
  final String? barcode;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.barcode,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'barcode': barcode,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'] is int ? (map['price'] as int).toDouble() : map['price'],
      stock: map['stock'],
      imageUrl: map['image_url'],
      barcode: map['barcode'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
    String? imageUrl,
    String? barcode,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
