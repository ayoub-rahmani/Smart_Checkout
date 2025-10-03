import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';
import '../data/services/storage_service.dart';
import '../data/services/firebase_service.dart';
import 'dart:io';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();
  final StorageService _storageService = StorageService();
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  bool _isListening = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadProducts() {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null || _isListening) return;

    _isListening = true;
    _setLoading(true);

    _productRepository.getProductsBySeller(userId).listen(
          (products) {
        _products = products;
        _setLoading(false, null);
      },
      onError: (error) {
        print('Product loading error: $error');

        // Handle index error gracefully
        if (error.toString().contains('requires an index') ||
            error.toString().contains('FAILED_PRECONDITION')) {
          _handleIndexError();
        } else {
          _setLoading(false, 'Failed to load products: ${error.toString()}');
        }
      },
    );
  }

  void _handleIndexError() async {
    try {
      print('Index error detected, falling back to simple query...');

      // Fallback: load products with pagination instead of real-time
      final userId = _firebaseService.currentUser?.uid;
      if (userId != null) {
        final products = await _productRepository.getProductsBySellerPaginated(userId);
        _products = products;
        _setLoading(false, null);
      } else {
        _setLoading(false, 'User not authenticated');
      }
    } catch (e) {
      _setLoading(false, 'Failed to load products: ${e.toString()}');
    }
  }

  Future<bool> createProduct({
    required String title,
    required String description,
    required double price,
    required int stockQuantity,
    required List<File> imageFiles,
    List<ProductVariant>? variants,
    String? category,
  }) async {
    try {
      _setLoading(true);

      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      if (imageFiles.isEmpty) {
        throw Exception('At least one product image is required');
      }

      // Validate images
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        if (!await file.exists()) {
          throw Exception('Image ${i + 1} not found');
        }
        final size = await file.length();
        if (size > 10 * 1024 * 1024) {
          throw Exception('Image ${i + 1} is too large (max 10MB)');
        }
        print('Image $i validated: ${size} bytes');
      }

      // Generate product ID
      final productId = DateTime.now().millisecondsSinceEpoch.toString();
      print('Creating product with ID: $productId');

      // Add small delay to ensure Firebase is ready
      await Future.delayed(Duration(milliseconds: 500));

      // Upload images
      print('Starting image upload...');
      final imageUrls = await _storageService.uploadProductImages(imageFiles, productId);
      print('All images uploaded successfully: ${imageUrls.length}');

      // Create product
      final product = ProductModel(
        productId: '',
        sellerId: userId,
        title: title,
        description: description,
        price: price,
        images: imageUrls,
        variants: variants ?? [],
        stockQuantity: stockQuantity,
        buyLink: 'https://yourapp.com/buy/$productId',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: category ?? 'general',
      );

      final createdId = await _productRepository.createProduct(product);
      print('Product created in Firestore with ID: $createdId');

      // Update with actual ID
      final finalProduct = product.copyWith(
        productId: createdId,
        buyLink: 'https://yourapp.com/buy/$createdId',
      );
      await _productRepository.updateProduct(finalProduct);

      // Refresh products list
      await refreshProducts();

      _setLoading(false, null);
      return true;
    } catch (e) {
      print('Create product error: $e');
      print('Error type: ${e.runtimeType}');
      _setLoading(false, e.toString());
      return false;
    }
  }
  Future<bool> updateProduct(ProductModel product) async {
    try {
      _setLoading(true);
      final updated = product.copyWith(updatedAt: DateTime.now());
      await _productRepository.updateProduct(updated);
      await refreshProducts();
      _setLoading(false, null);
      return true;
    } catch (e) {
      _setLoading(false, e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      await _productRepository.deleteProduct(productId);
      await refreshProducts();
      _setLoading(false, null);
      return true;
    } catch (e) {
      _setLoading(false, e.toString());
      return false;
    }
  }

  Future<bool> updateStock(String productId, int newStock) async {
    try {
      await _productRepository.updateStock(productId, newStock);
      await refreshProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) return null;
      return await _productRepository.getProductAnalytics(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Manual refresh without real-time listeners
  Future<void> refreshProducts() async {
    try {
      print('Manual refresh started...');
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) return;

      // Try multiple strategies in sequence
      try {
        // Strategy 1: Paginated query
        final products = await _productRepository.getProductsBySellerPaginated(userId);
        _products = products;
        print('Manual refresh successful with ${products.length} products');
        notifyListeners();
        return;
      } catch (e1) {
        print('Paginated refresh failed: $e1');
      }

      try {
        // Strategy 2: Emergency fallback
        final products = await _productRepository.getProductsEmergencyFallback(userId);
        _products = products;
        print('Emergency refresh successful with ${products.length} products');
        notifyListeners();
        return;
      } catch (e2) {
        print('Emergency refresh failed: $e2');
      }

      print('All refresh strategies failed');
    } catch (e) {
      print('Refresh products error: $e');
    }
  }

  // Force refresh with user feedback
  Future<bool> forceRefresh() async {
    try {
      _setLoading(true);
      await refreshProducts();
      _setLoading(false, null);
      return _products.isNotEmpty;
    } catch (e) {
      _setLoading(false, 'Refresh failed: ${e.toString()}');
      return false;
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts({
    String? query,
    String? category,
  }) async {
    try {
      return await _productRepository.searchProducts(
        query: query,
        category: category,
        limit: 50,
      );
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  void _setLoading(bool loading, [String? error]) {
    _isLoading = loading;
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isListening = false;
    super.dispose();
  }
}