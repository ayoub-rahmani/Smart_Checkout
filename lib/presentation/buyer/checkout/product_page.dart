import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import 'checkout_form_page.dart';

class ProductPage extends StatefulWidget {
  final String productId;
  final Map<String, String>? preselectedVariants;

  const ProductPage({
    super.key,
    required this.productId,
    this.preselectedVariants,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ProductRepository _productRepository = ProductRepository();
  ProductModel? _product;
  bool _isLoading = true;
  String? _error;

  int _quantity = 1;
  int _currentImageIndex = 0;
  Map<String, String> _selectedVariants = {};

  @override
  void initState() {
    super.initState();
    _selectedVariants = widget.preselectedVariants ?? {};
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await _productRepository.getProductById(widget.productId);
      if (product != null) {
        setState(() {
          _product = product;
          _isLoading = false;

          // Set default variants if not preselected
          for (var variant in product.variants) {
            if (!_selectedVariants.containsKey(variant.name) && variant.values.isNotEmpty) {
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
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _totalPrice => (_product?.price ?? 0) * _quantity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? _buildErrorState()
          : _product == null
          ? _buildNotFoundState()
          : _buildProductContent(),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProduct,
            child: const Text('Retry'),
          ),
        ],
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
            'Product not found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'This product may have been removed or is no longer available',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Images
          _buildImageGallery(),

          // Product Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_product!.price.toStringAsFixed(3)} TND',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _product!.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                // Variants Selection
                if (_product!.variants.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ..._product!.variants.map((variant) => _buildVariantSelector(variant)),
                ],

                // Quantity Selector
                const SizedBox(height: 24),
                _buildQuantitySelector(),

                // Stock Info
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _product!.stockQuantity > 0 ? Icons.check_circle : Icons.error,
                      color: _product!.stockQuantity > 0 ? AppColors.success : Colors.red,
                      size: 20,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (_product!.images.isEmpty) {
      return Container(
        height: 300,
        color: AppColors.border,
        child: const Center(
          child: Icon(Icons.image, size: 64, color: AppColors.textHint),
        ),
      );
    }

    return Container(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _product!.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                _product!.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.border,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64, color: AppColors.textHint),
                    ),
                  );
                },
              );
            },
          ),
          if (_product!.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _product!.images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: variant.values.map((value) {
            final isSelected = _selectedVariants[variant.name] == value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedVariants[variant.name] = value;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _quantity > 1 ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove,
                  color: _quantity > 1 ? Colors.white : AppColors.textHint,
                ),
              ),
            ),
            Container(
              width: 60,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _quantity < _product!.stockQuantity
                  ? () => setState(() => _quantity++)
                  : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _quantity < _product!.stockQuantity
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: _quantity < _product!.stockQuantity
                      ? Colors.white
                      : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_totalPrice.toStringAsFixed(3)} TND',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  'Buy Now',
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
    );
  }

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutFormPage(
          product: _product!,
          quantity: _quantity,
          selectedVariants: _selectedVariants,
          totalAmount: _totalPrice,
        ),
      ),
    );
  }
}
