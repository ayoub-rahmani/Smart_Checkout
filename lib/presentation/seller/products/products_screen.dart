// presentation/seller/products/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/shared/widgets/custom_button.dart';
import '../../../providers/product_provider.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/link_generator_service.dart';
import 'add_product_screen.dart';
import 'widgets/product_card.dart';
import 'widgets/link_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (_searchQuery.isEmpty) return products;

    return products.where((product) =>
    product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.description.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _showProductActions(ProductModel product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit screen
              },
            ),
            ListTile(
              leading: Icon(
                product.isActive ? Icons.visibility_off : Icons.visibility,
                color: AppColors.warning,
              ),
              title: Text(product.isActive ? 'Deactivate' : 'Activate'),
              onTap: () async {
                Navigator.pop(context);
                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                final updatedProduct = product.copyWith(isActive: !product.isActive);
                await productProvider.updateProduct(updatedProduct);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primary),
              title: const Text('Share Product Link'),
              onTap: () {
                Navigator.pop(context);
                _shareProductLink(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: const Text('Get Product Link'),
              onTap: () {
                Navigator.pop(context);
                _showProductLink(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: AppColors.primary),
              title: const Text('Generate QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showQRCode(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Product'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: const Text('Are you sure you want to delete this product?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final productProvider = Provider.of<ProductProvider>(context, listen: false);
                  await productProvider.deleteProduct(product.productId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareProductLink(ProductModel product) async {
    try {
      await LinkGeneratorService.generateShareableLink(
        productId: product.productId,
        productTitle: product.title,
        price: product.price,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing product: $e')),
      );
    }
  }

  void _showProductLink(ProductModel product) {
    final productLink = LinkGeneratorService.generateProductLink(product.productId);

    showDialog(
      context: context,
      builder: (context) => LinkDialog(
        productName: product.title,
        productLink: productLink,
        qrData: LinkGeneratorService.generateQRCodeData(product.productId),
      ),
    );
  }

  void _showQRCode(ProductModel product) {
    final qrData = LinkGeneratorService.generateQRCodeData(product.productId);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan to Buy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // You can add a QR code widget here
              // QrImageView(data: qrData, size: 200),
              Container(
                width: 200,
                height: 200,
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('QR Code Preview'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                product.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                qrData,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _shareProductLink(product),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Bulk share all products
              _showBulkShareOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Products Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading && productProvider.products.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (productProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading products',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            productProvider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              productProvider.clearError();
                              productProvider.loadProducts();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredProducts = _filterProducts(productProvider.products);

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No products yet' : 'No products found',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Add your first product to get started'
                                : 'Try adjusting your search terms',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Product'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      return RepaintBoundary(
                        child: ProductCard(
                          productId: product.productId,
                          productName: product.title,
                          price: '${product.price.toStringAsFixed(3)} TND',
                          imageUrl: product.images.isNotEmpty ? product.images.first : 'assets/images/products/headphones-wireless.png',
                          stock: product.stockQuantity,
                          isActive: product.isActive,
                          onTap: () => _showProductActions(product),
                          onEdit: () => _showProductActions(product),
                          onToggleStatus: () async {
                            final updatedProduct = product.copyWith(isActive: !product.isActive);
                            await Provider.of<ProductProvider>(context, listen: false).updateProduct(updatedProduct);
                          },
                          onGenerateLink: () => _showProductLink(product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showBulkShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share All Products'),
              subtitle: const Text('Generate links for all active products'),
              onTap: () {
                Navigator.pop(context);
                _shareAllProducts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate QR Codes'),
              subtitle: const Text('Create QR codes for all products'),
              onTap: () {
                Navigator.pop(context);
                // Implement bulk QR generation
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareAllProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final activeProducts = productProvider.products.where((p) => p.isActive).toList();

    if (activeProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active products to share')),
      );
      return;
    }

    final shareText = StringBuffer('🛍️ **My Products**\n\n');

    for (final product in activeProducts) {
      final productLink = LinkGeneratorService.generateProductLink(product.productId);
      shareText.write('''
📦 ${product.title}
💰 ${product.price.toStringAsFixed(3)} TND
🔗 $productLink

''');
    }

    shareText.write('\n💳 Secure Checkout • 🚚 Fast Delivery');
  }
}