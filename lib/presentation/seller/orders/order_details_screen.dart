import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/order_provider.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _currentOrder;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _notesController.text = _currentOrder.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final success = await orderProvider.updateOrderStatus(
      _currentOrder.orderId,
      newStatus,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (success) {
      setState(() {
        _currentOrder = _currentOrder.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to ${newStatus.toUpperCase()}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${orderProvider.error}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${_currentOrder.orderCode}'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _currentOrder.orderCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order code copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Action Buttons
            if (_getNextStatuses(_currentOrder.status).isNotEmpty) ...[
              const Text(
                'Update Order Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<OrderProvider>(
                builder: (context, orderProvider, child) {
                  return Column(
                    children: _getNextStatuses(_currentOrder.status).map((status) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: orderProvider.isLoading ? null : () async => await _updateOrderStatus(status),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getStatusColor(status),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            orderProvider.isLoading
                                ? 'Updating...'
                                : 'Mark as ${status.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
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

  List<String> _getNextStatuses(String currentStatus) {
    switch (currentStatus) {
      case FirebaseConstants.orderStatusPending:
        return [FirebaseConstants.orderStatusConfirmed, FirebaseConstants.orderStatusCancelled];
      case FirebaseConstants.orderStatusConfirmed:
        return [FirebaseConstants.orderStatusPacked];
      case FirebaseConstants.orderStatusPacked:
        return [FirebaseConstants.orderStatusShipped];
      case FirebaseConstants.orderStatusShipped:
        return [FirebaseConstants.orderStatusDelivered];
      default:
        return [];
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isTotal ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
