import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerInfo {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String governorate;
  final String? email;

  BuyerInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.governorate,
    this.email,
  });

  factory BuyerInfo.fromMap(Map<String, dynamic> map) {
    return BuyerInfo(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      governorate: map['governorate'] ?? '',
      email: map['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'governorate': governorate,
      'email': email,
    };
  }
}

class OrderDetails {
  final String productTitle;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, String> selectedVariants; // e.g., {'Size': 'L', 'Color': 'Blue'}
  final String productImage;

  OrderDetails({
    required this.productTitle,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.selectedVariants,
    required this.productImage,
  });

  factory OrderDetails.fromMap(Map<String, dynamic> map) {
    return OrderDetails(
      productTitle: map['productTitle'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      selectedVariants: Map<String, String>.from(map['selectedVariants'] ?? {}),
      productImage: map['productImage'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productTitle': productTitle,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'selectedVariants': selectedVariants,
      'productImage': productImage,
    };
  }
}

class OrderModel {
  final String orderId;
  final String orderCode; // 6-digit public tracking code
  final String sellerId;
  final String productId;
  final BuyerInfo buyerInfo;
  final OrderDetails orderDetails;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double deliveryFee;
  final double totalAmount;
  final String? notes;
  final List<String>? statusHistory;

  OrderModel({
    required this.orderId,
    required this.orderCode,
    required this.sellerId,
    required this.productId,
    required this.buyerInfo,
    required this.orderDetails,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
    required this.deliveryFee,
    required this.totalAmount,
    this.notes,
    this.statusHistory,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId: doc.id,
      orderCode: data['orderCode'] ?? '',
      sellerId: data['sellerId'] ?? '',
      productId: data['productId'] ?? '',
      buyerInfo: BuyerInfo.fromMap(data['buyerInfo'] ?? {}),
      orderDetails: OrderDetails.fromMap(data['orderDetails'] ?? {}),
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'cod',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      notes: data['notes'],
      statusHistory: data['statusHistory'] != null
          ? List<String>.from(data['statusHistory'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderCode': orderCode,
      'sellerId': sellerId,
      'productId': productId,
      'buyerInfo': buyerInfo.toMap(),
      'orderDetails': orderDetails.toMap(),
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'notes': notes,
      'statusHistory': statusHistory,
    };
  }

  OrderModel copyWith({
    String? orderId,
    String? orderCode,
    String? sellerId,
    String? productId,
    BuyerInfo? buyerInfo,
    OrderDetails? orderDetails,
    String? status,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? deliveryFee,
    double? totalAmount,
    String? notes,
    List<String>? statusHistory,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      buyerInfo: buyerInfo ?? this.buyerInfo,
      orderDetails: orderDetails ?? this.orderDetails,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}
