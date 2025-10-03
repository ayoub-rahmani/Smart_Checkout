// presentation/seller/products/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/link_generator_service.dart';

class ProductCard extends StatelessWidget {
  final String productId;
  final String productName;
  final String price;
  final String imageUrl;
  final int stock;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onGenerateLink;

  const ProductCard({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onGenerateLink,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
              // Product Image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: _buildImage(),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.success : AppColors.textHint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Actions Menu
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 16),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                onEdit();
                                break;
                              case 'toggle':
                                onToggleStatus();
                                break;
                              case 'share':
                                _shareProductLink(context);
                                break;
                              case 'link':
                                onGenerateLink();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.visibility_off : Icons.visibility,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(isActive ? 'Deactivate' : 'Activate'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share, size: 16),
                                  SizedBox(width: 8),
                                  Text('Share Link'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'link',
                              child: Row(
                                children: [
                                  Icon(Icons.link, size: 16),
                                  SizedBox(width: 8),
                                  Text('Get Link'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: stock > 5 ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '$stock in stock',
                              style: TextStyle(
                                fontSize: 11,
                                color: stock > 5 ? AppColors.success : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Quick Share Button
                          GestureDetector(
                            onTap: () => _shareProductLink(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.share, size: 12, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareProductLink(BuildContext context) async {
    try {
      await LinkGeneratorService.generateShareableLink(
        productId: productId,
        productTitle: productName,
        price: double.parse(price.replaceAll(' TND', '')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing product: $e')),
      );
    }
  }

  Widget _buildImage() {
    // Check if it's a network URL (Firebase Storage)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Image load error: $error');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 32, color: Colors.grey),
                SizedBox(height: 4),
                Text(
                  'Failed to load',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Fallback to local asset
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
          );
        },
      );
    }
  }
}