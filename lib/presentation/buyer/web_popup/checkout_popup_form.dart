// presentation/buyer/web_popup/checkout_popup_form.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import 'confirmation_popup_page.dart';


class CheckoutPopupForm extends StatefulWidget {
  final ProductModel product;
  final int quantity;
  final Map<String, String> selectedVariants;
  final double totalAmount;
  final VoidCallback onBack;

  const CheckoutPopupForm({
    super.key,
    required this.product,
    required this.quantity,
    required this.selectedVariants,
    required this.totalAmount,
    required this.onBack,
  });

  @override
  State<CheckoutPopupForm> createState() => _CheckoutPopupFormState();
}

class _CheckoutPopupFormState extends State<CheckoutPopupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedGovernorate = 'Tunis';
  bool _isLoading = false;
  bool _processingPayment = false;

  final List<String> _governorates = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Kairouan',
    'Kasserine', 'Sidi Bouzid', 'Sousse', 'Monastir', 'Mahdia',
    'Sfax', 'Gafsa', 'Tozeur', 'Kebili', 'Gabès', 'Medenine', 'Tataouine'
  ];

  final double _deliveryFee = 7.000;
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _processPaymentAndCreateOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _processingPayment = true;
    });

    try {
      await _createOrder();
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: $e')),
      );
      setState(() {
        _processingPayment = false;
      });
    }
  }
  }

  Future<void> _createOrder() async {
    try {
      final orderRepository = OrderRepository();

      final buyerInfo = BuyerInfo(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        governorate: _selectedGovernorate,
      );

      final orderDetails = OrderDetails(
        productTitle: widget.product.title,
        quantity: widget.quantity,
        unitPrice: widget.product.price,
        totalPrice: widget.totalAmount,
        selectedVariants: widget.selectedVariants,
        productImage: widget.product.images.isNotEmpty ? widget.product.images.first : '',
      );

      final order = OrderModel(
        orderId: '',
        orderCode: '',
        sellerId: widget.product.sellerId,
        productId: widget.product.productId,
        buyerInfo: buyerInfo,
        orderDetails: orderDetails,
        status: FirebaseConstants.orderStatusPending,
        paymentMethod: FirebaseConstants.paymentCOD,
        createdAt: DateTime.now(),
        deliveryFee: _deliveryFee,
        totalAmount: widget.totalAmount + _deliveryFee,
        notes: 'Cash on Delivery - Web Order',
      );

      final orderId = await orderRepository.createOrder(order);
      final createdOrder = await orderRepository.getOrderById(orderId);

      if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationPopupPage(
            order: createdOrder!,
              transactionId: '',
          ),
        ),
      );
      }
    } catch (e) {
      rethrow;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildOrderSummary(),
                const SizedBox(height: 24),

                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your city';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGovernorate,
                        decoration: const InputDecoration(
                          labelText: 'Governorate',
                          border: OutlineInputBorder(),
                        ),
                        items: _governorates.map((governorate) {
                          return DropdownMenuItem(
                            value: governorate,
                            child: Text(governorate),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGovernorate = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Options',
            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
            ),
          ),
        ],
      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Cash on Delivery: Pay when you receive your order',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Card Payment: Secure online payment (Coming Soon)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'For now, all orders use Cash on Delivery. The seller will contact you to confirm.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processingPayment ? null : _processPaymentAndCreateOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _processingPayment
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Confirming Order...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                        : const Text(
                      'Confirm Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.product.images.isNotEmpty
                    ? Image.network(
                  widget.product.images.first,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 50,
                  height: 50,
                  color: AppColors.border,
                  child: const Icon(Icons.image, color: AppColors.textHint),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (widget.selectedVariants.isNotEmpty)
                      Text(
                        widget.selectedVariants.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join(', '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    Text(
                      'Qty: ${widget.quantity}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.totalAmount.toStringAsFixed(3)} TND',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _buildSummaryRow('Subtotal', '${widget.totalAmount.toStringAsFixed(3)} TND'),
          _buildSummaryRow('Delivery', '${_deliveryFee.toStringAsFixed(3)} TND'),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Total',
            '${(widget.totalAmount + _deliveryFee).toStringAsFixed(3)} TND',
            isTotal: true,
          ),
        ],
      ),
    );
}

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
