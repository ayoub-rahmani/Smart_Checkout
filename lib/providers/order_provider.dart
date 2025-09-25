import 'package:flutter/material.dart';
import '../data/models/order_model.dart';
import '../data/repositories/order_repository.dart';
import '../data/services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _analytics;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get analytics => _analytics;

  void loadOrders() {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;

    _orderRepository.getOrdersBySeller(userId).listen(
          (orders) {
        _orders = orders;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Stream<List<OrderModel>> getOrdersByStatus(String status) {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    return _orderRepository.getOrdersByStatus(userId, status);
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus, {String? notes}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _orderRepository.updateOrderStatus(orderId, newStatus, notes: notes);

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<OrderModel>> getRecentOrders({int limit = 5}) async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return [];

    try {
      return await _orderRepository.getRecentOrders(userId, limit: limit);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<void> loadAnalytics() async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;

    try {
      _analytics = await _orderRepository.getOrderAnalytics(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<OrderModel?> getOrderByCode(String orderCode) async {
    try {
      return await _orderRepository.getOrderByCode(orderCode);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
