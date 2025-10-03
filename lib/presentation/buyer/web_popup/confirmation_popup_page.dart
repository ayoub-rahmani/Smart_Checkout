// presentation/buyer/web_popup/confirmation_popup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/link_generator_service.dart';

class ConfirmationPopupPage extends StatelessWidget {
  final OrderModel order;
  final String transactionId;

  const ConfirmationPopupPage({
    super.key,
    required this.order,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final trackingLink = LinkGeneratorService.generateTrackingLink(order.orderCode);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Success Message
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Your order has been confirmed and payment processed successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Order Details
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Order Code', order.orderCode),
                          const SizedBox(height: 8),
                          _buildDetailRow('Amount', '${order.totalAmount.toStringAsFixed(3)} TND'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Status', 'Confirmed'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Transaction ID', transactionId),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tracking Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.track_changes, color: AppColors.primary),
                          const SizedBox(height: 8),
                          const Text(
                            'Track Your Order',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trackingLink,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: order.orderCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order code copied!')),
                              );
                            },
                            child: const Text('Copy Order Code'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close the popup
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}