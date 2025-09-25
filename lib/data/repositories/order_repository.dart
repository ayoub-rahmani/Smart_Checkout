import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firebase_constants.dart';
import 'dart:math';

class OrderRepository {
  final FirebaseService _firebaseService = FirebaseService.instance;

  // Create order
  Future<String> createOrder(OrderModel order) async {
    try {
      // Generate unique order code
      final orderCode = _generateOrderCode();
      final orderWithCode = order.copyWith(orderCode: orderCode);

      final docRef = await _firebaseService.firestore
          .collection(FirebaseConstants.ordersCollection)
          .add(orderWithCode.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Get order by tracking code
  Future<OrderModel?> getOrderByCode(String orderCode) async {
    try {
      final query = await _firebaseService.firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('orderCode', isEqualTo: orderCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return OrderModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order by code: $e');
    }
  }

  // Get orders by seller (real-time)
  Stream<List<OrderModel>> getOrdersBySeller(String sellerId) {
    return _firebaseService.firestore
        .collection(FirebaseConstants.ordersCollection)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList());
  }

  // Get orders by status
  Stream<List<OrderModel>> getOrdersByStatus(String sellerId, String status) {
    return _firebaseService.firestore
        .collection(FirebaseConstants.ordersCollection)
        .where('sellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList());
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
    try {
      final updateData = {
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      // Add to status history
      final orderDoc = await _firebaseService.firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final order = OrderModel.fromFirestore(orderDoc);
        final statusHistory = order.statusHistory ?? [];
        statusHistory.add('${DateTime.now().toIso8601String()}: $newStatus');
        updateData['statusHistory'] = statusHistory;
      }

      await _firebaseService.firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get order analytics
  Future<Map<String, dynamic>> getOrderAnalytics(String sellerId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('sellerId', isEqualTo: sellerId)
          .get();

      int totalOrders = 0;
      int pendingOrders = 0;
      int completedOrders = 0;
      double totalRevenue = 0;

      for (var doc in snapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        totalOrders++;

        switch (order.status) {
          case FirebaseConstants.orderStatusPending:
            pendingOrders++;
            break;
          case FirebaseConstants.orderStatusDelivered:
            completedOrders++;
            totalRevenue += order.totalAmount;
            break;
        }
      }

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Failed to get order analytics: $e');
    }
  }

  // Generate 6-digit order code
  String _generateOrderCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Get recent orders for dashboard
  Future<List<OrderModel>> getRecentOrders(String sellerId, {int limit = 5}) async {
    try {
      final query = await _firebaseService.firestore
          .collection(FirebaseConstants.ordersCollection)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get recent orders: $e');
    }
  }
}
