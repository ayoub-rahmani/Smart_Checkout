import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String role; // 'seller' or 'buyer'
  final String name;
  final String phone;
  final String email;
  final String? businessName; // Only for sellers
  final bool isVerified;
  final DateTime createdAt;
  final String? profileImageUrl;
  final Map<String, dynamic>? businessInfo;

  UserModel({
    required this.userId,
    required this.role,
    required this.name,
    required this.phone,
    required this.email,
    this.businessName,
    required this.isVerified,
    required this.createdAt,
    this.profileImageUrl,
    this.businessInfo,
  });

  // Convert from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      role: data['role'] ?? 'seller',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      businessName: data['businessName'],
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      profileImageUrl: data['profileImageUrl'],
      businessInfo: data['businessInfo'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'role': role,
      'name': name,
      'phone': phone,
      'email': email,
      'businessName': businessName,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileImageUrl': profileImageUrl,
      'businessInfo': businessInfo,
    };
  }

  // Copy with method for updates
  UserModel copyWith({
    String? userId,
    String? role,
    String? name,
    String? phone,
    String? email,
    String? businessName,
    bool? isVerified,
    DateTime? createdAt,
    String? profileImageUrl,
    Map<String, dynamic>? businessInfo,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      businessInfo: businessInfo ?? this.businessInfo,
    );
  }
}
