import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../providers/order_provider.dart';
import '../../../data/models/order_model.dart';
import 'widgets/order_card.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _statusTabs = [
    {'key': 'all', 'label': 'All'},
    {'key': FirebaseConstants.orderStatusPending, 'label': 'Pending'},
    {'key': FirebaseConstants.orderStatusConfirmed, 'label': 'Confirmed'},
    {'key': FirebaseConstants.orderStatusShipped, 'label': 'Shipped'},
    {'key': FirebaseConstants.orderStatusDelivered, 'label': 'Delivered'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderModel> _filterOrdersByStatus(List<OrderModel> orders, String status) {
    if (status == 'all') return orders;
    return orders.where((order) => order.status == status).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case FirebaseConstants.orderStatusPending:
        return AppColors.warning;
      case FirebaseConstants.orderStatusConfirmed:
        return AppColors.primary;
      case FirebaseConstants.orderStatusPacked:
        return Colors.orange;
      case FirebaseConstants.orderStatusShipped:
        return Colors.blue;
      case FirebaseConstants.orderStatusDelivered:
        return AppColors.success;
      case FirebaseConstants.orderStatusCancelled:
        return Colors.red;
      default:
        return AppColors.textHint;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _statusTabs.map((status) => Tab(text: status['label'])).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statusTabs.map((status) => _buildOrdersList(status['key']!)).toList(),
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            orderProvider.loadOrders();
          },
          child: Builder(
            builder: (context) {
              if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (orderProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading orders',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        orderProvider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          orderProvider.clearError();
                          orderProvider.loadOrders();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredOrders = _filterOrdersByStatus(orderProvider.orders, status);

              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text(
                        status == 'all' ? 'No orders yet' : 'No ${status} orders',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Orders will appear here when customers place them',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];

                  return RepaintBoundary(
                    child: OrderCard(
                      orderId: '#${order.orderCode}',
                      customerName: order.buyerInfo.name,
                      productName: order.orderDetails.productTitle,
                      amount: '${order.totalAmount.toStringAsFixed(3)} TND',
                      status: order.status,
                      orderDate: _formatTimeAgo(order.createdAt),
                      statusColor: _getStatusColor(order.status),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: order),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
