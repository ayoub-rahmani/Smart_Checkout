import 'package:cloud_firestore/cloud_firestore.dart';

class ProductVariant {
  final String name; // e.g., 'Size', 'Color'
  final List<String> values; // e.g., ['S', 'M', 'L'] or ['Red', 'Blue']

  ProductVariant({
    required this.name,
    required this.values,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      name: map['name'] ?? '',
      values: List<String>.from(map['values'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'values': values,
    };
  }
}

class ProductModel {
  final String productId;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final List<ProductVariant> variants;
  final int stockQuantity;
  final String buyLink;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category;
  final Map<String, dynamic>? metadata;

  ProductModel({
    required this.productId,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.variants,
    required this.stockQuantity,
    required this.buyLink,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.metadata,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: doc.id,
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      variants: (data['variants'] as List<dynamic>?)
          ?.map((v) => ProductVariant.fromMap(v))
          .toList() ?? [],
      stockQuantity: data['stockQuantity'] ?? 0,
      buyLink: data['buyLink'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      category: data['category'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'images': images,
      'variants': variants.map((v) => v.toMap()).toList(),
      'stockQuantity': stockQuantity,
      'buyLink': buyLink,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'category': category,
      'metadata': metadata,
    };
  }

  ProductModel copyWith({
    String? productId,
    String? sellerId,
    String? title,
    String? description,
    double? price,
    List<String>? images,
    List<ProductVariant>? variants,
    int? stockQuantity,
    String? buyLink,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      buyLink: buyLink ?? this.buyLink,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }
}
