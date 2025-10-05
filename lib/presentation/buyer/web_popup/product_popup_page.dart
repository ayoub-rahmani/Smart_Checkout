// presentation/buyer/web_popup/product_popup_page.dart
import 'package:flutter/material.dart';




import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import 'checkout_popup_form.dart';

class ProductPopupPage extends StatefulWidget {
  const ProductPopupPage({super.key});

  @override
  State<ProductPopupPage> createState() => _ProductPopupPageState();
}

class _ProductPopupPageState extends State<ProductPopupPage> {
  final ProductRepository _productRepository = ProductRepository();
  ProductModel? _product;
  bool _isLoading = true;
  String? _error;

  int _quantity = 1;
  int _currentImageIndex = 0;
  Map<String, String> _selectedVariants = {};
  bool _showCheckout = false;

  @override
  void initState() {
    super.initState();
    _loadProductFromUrl();
  }

  Future<void> _loadProductFromUrl() async {
    try {
      final uri = Uri.base;
      final productId = uri.queryParameters['product'];

      if (productId == null || productId.isEmpty) {
        setState(() {
          _error = 'Invalid product link: No product ID found';
          _isLoading = false;
        });
        return;
      }

      print('Loading product with ID: $productId');
      final product = await _productRepository.getProductById(productId);

      if (product != null) {
        setState(() {
          _product = product;
          _isLoading = false;
          for (var variant in product.variants) {
            if (variant.values.isNotEmpty) {
              _selectedVariants[variant.name] = variant.values.first;
            }
          }
        });
      } else {
    setState(() {
          _error = 'Product not found';
          _isLoading = false;
    });
  }
    } catch (e) {
    setState(() {
        _error = 'Error loading product: $e';
        _isLoading = false;
    });
  }
  }

  double get _totalPrice => (_product?.price ?? 0) * _quantity;

  void _proceedToCheckout() {
                setState(() {
      _showCheckout = true;
                });
  }

  void _backToProduct() {
    setState(() {
      _showCheckout = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
            ? _buildErrorState()
            : _product == null
            ? _buildNotFoundState()
            : _showCheckout
            ? CheckoutPopupForm(
          product: _product!,
          quantity: _quantity,
          selectedVariants: _selectedVariants,
          totalAmount: _totalPrice,
          onBack: _backToProduct,
        )
            : _buildProductContent(),
        ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
      children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Loading product...'),
          ],
        ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductFromUrl,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
}

  Widget _buildNotFoundState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'Product Not Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),

          _buildImageGallery(),

          const SizedBox(height: 16),

          Text(
            _product!.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_product!.price.toStringAsFixed(3)} TND',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _product!.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          if (_product!.variants.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._product!.variants.map((variant) => _buildVariantSelector(variant)),
          ],

          const SizedBox(height: 20),
          _buildQuantitySelector(),

          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _product!.stockQuantity > 0 ? Icons.check_circle : Icons.error,
                color: _product!.stockQuantity > 0 ? AppColors.success : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _product!.stockQuantity > 0
                    ? '${_product!.stockQuantity} in stock'
                    : 'Out of stock',
                style: TextStyle(
                  color: _product!.stockQuantity > 0 ? AppColors.success : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _product!.stockQuantity > 0 ? _proceedToCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed to Checkout',
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
    );
  }

  Widget _buildImageGallery() {
    if (_product!.images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 48, color: AppColors.textHint),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(_product!.images.first),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildVariantSelector(ProductVariant variant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          variant.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: variant.values.map((value) {
            final isSelected = _selectedVariants[variant.name] == value;
            return ChoiceChip(
              label: Text(value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedVariants[variant.name] = value;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _quantity.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _quantity < _product!.stockQuantity
                  ? () => setState(() => _quantity++)
                  : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
