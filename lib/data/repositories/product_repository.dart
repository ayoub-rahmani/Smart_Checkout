import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firebase_constants.dart';

class ProductRepository {
  final FirebaseService _firebaseService = FirebaseService.instance;

  // Create product
  Future<String> createProduct(ProductModel product) async {
    try {
      final docRef = await _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .get();
      return doc.exists ? ProductModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // TEMPORARY: Ultra-simple query to avoid index issues completely
  Stream<List<ProductModel>> getProductsBySeller(String sellerId) {
    print('DEBUG: Starting getProductsBySeller for seller: $sellerId');

    return _firebaseService.firestore
        .collection(FirebaseConstants.productsCollection)
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .handleError((error) {
      print('DEBUG: Stream error in getProductsBySeller: $error');
      print('DEBUG: Error type: ${error.runtimeType}');
      if (error is FirebaseException) {
        print('DEBUG: Firebase error code: ${error.code}');
        print('DEBUG: Firebase error message: ${error.message}');
      }
    })
        .map((snapshot) {
      print('DEBUG: Received ${snapshot.docs.length} documents from Firestore');

      List<ProductModel> products = [];

      for (var doc in snapshot.docs) {
        try {
          print('DEBUG: Processing document ${doc.id}');
          final product = ProductModel.fromFirestore(doc);

          // Client-side filtering - no indexes needed
          if (product.isActive) {
            products.add(product);
            print('DEBUG: Added active product: ${product.title}');
          } else {
            print('DEBUG: Skipped inactive product: ${product.title}');
          }
        } catch (e) {
          print('DEBUG: Error parsing product ${doc.id}: $e');
        }
      }

      // Client-side sorting - no indexes needed
      products.sort((a, b) {
        final comparison = b.createdAt.compareTo(a.createdAt);
        print('DEBUG: Sorting ${a.title} vs ${b.title}: $comparison');
        return comparison;
      });

      print('DEBUG: Returning ${products.length} active products');
      return products;
    });
  }

  // Alternative: Get products with simple pagination (absolutely no indexes needed)
  Future<List<ProductModel>> getProductsBySellerPaginated(
      String sellerId, {
        DocumentSnapshot? lastDoc,
        int limit = 20,
      }) async {
    try {
      print('DEBUG: getProductsBySellerPaginated for seller: $sellerId');

      // Start with the simplest possible query
      Query query = _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .where('sellerId', isEqualTo: sellerId)
          .limit(limit * 2); // Get extra for client-side filtering

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
        print('DEBUG: Using pagination starting after doc: ${lastDoc.id}');
      }

      print('DEBUG: Executing Firestore query...');
      final snapshot = await query.get();
      print('DEBUG: Query returned ${snapshot.docs.length} documents');

      List<ProductModel> products = [];
      for (var doc in snapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);
          if (product.isActive) {
            products.add(product);
          }
          if (products.length >= limit) break;
        } catch (e) {
          print('DEBUG: Error parsing product ${doc.id}: $e');
        }
      }

      // Sort client-side
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('DEBUG: Returning ${products.length} products');

      return products;
    } catch (e) {
      print('DEBUG: getProductsBySellerPaginated error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      throw Exception('Failed to get products: $e');
    }
  }

  // EMERGENCY: Get products with zero Firestore queries (just in case)
  Future<List<ProductModel>> getProductsEmergencyFallback(String sellerId) async {
    try {
      print('DEBUG: Using emergency fallback - basic collection scan');

      final snapshot = await _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .get();

      print('DEBUG: Emergency scan got ${snapshot.docs.length} total documents');

      List<ProductModel> sellerProducts = [];
      for (var doc in snapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);
          if (product.sellerId == sellerId && product.isActive) {
            sellerProducts.add(product);
          }
        } catch (e) {
          print('DEBUG: Error in emergency fallback for ${doc.id}: $e');
        }
      }

      sellerProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('DEBUG: Emergency fallback found ${sellerProducts.length} products for seller');

      return sellerProducts;
    } catch (e) {
      print('DEBUG: Emergency fallback also failed: $e');
      return [];
    }
  }

  // Update product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(product.productId)
          .update(product.toFirestore());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      await _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Update stock
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .update({
        'stockQuantity': newStock,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // Ultra-simplified search
  Future<List<ProductModel>> searchProducts({
    String? query,
    String? category,
    int limit = 20,
  }) async {
    try {
      print('DEBUG: searchProducts - query: $query, category: $category');

      // Use the simplest possible query structure
      Query firestoreQuery = _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .limit(limit * 3);

      // Only add category filter if specified
      if (category != null && category.isNotEmpty && category != 'all') {
        firestoreQuery = firestoreQuery.where('category', isEqualTo: category);
        print('DEBUG: Added category filter: $category');
      }

      final snapshot = await firestoreQuery.get();
      print('DEBUG: Search query returned ${snapshot.docs.length} documents');

      List<ProductModel> products = [];
      for (var doc in snapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);

          if (!product.isActive) continue;

          // Client-side text search if query provided
          if (query != null && query.isNotEmpty) {
            final queryLower = query.toLowerCase();
            final titleMatch = product.title.toLowerCase().contains(queryLower);
            final descMatch = product.description.toLowerCase().contains(queryLower);

            if (!titleMatch && !descMatch) continue;
          }

          products.add(product);
        } catch (e) {
          print('DEBUG: Error parsing search result ${doc.id}: $e');
        }
      }

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final result = products.take(limit).toList();
      print('DEBUG: Search returning ${result.length} products');

      return result;
    } catch (e) {
      print('DEBUG: Search failed: $e');
      throw Exception('Failed to search products: $e');
    }
  }

  // Analytics with simple queries
  Future<Map<String, dynamic>> getProductAnalytics(String sellerId) async {
    try {
      print('DEBUG: Getting analytics for seller: $sellerId');

      final snapshot = await _firebaseService.firestore
          .collection(FirebaseConstants.productsCollection)
          .where('sellerId', isEqualTo: sellerId)
          .get();

      print('DEBUG: Analytics query returned ${snapshot.docs.length} documents');

      int totalProducts = 0;
      int activeProducts = 0;
      int outOfStock = 0;
      double totalValue = 0;

      for (var doc in snapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);
          totalProducts++;

          if (product.isActive) {
            activeProducts++;
            totalValue += product.price * product.stockQuantity;
          }

          if (product.stockQuantity == 0) {
            outOfStock++;
          }
        } catch (e) {
          print('DEBUG: Error processing analytics for ${doc.id}: $e');
        }
      }

      final analytics = {
        'totalProducts': totalProducts,
        'activeProducts': activeProducts,
        'outOfStock': outOfStock,
        'inventoryValue': totalValue.toStringAsFixed(2),
        'averagePrice': activeProducts > 0 ? (totalValue / activeProducts).toStringAsFixed(2) : '0.00',
      };

      print('DEBUG: Analytics result: $analytics');
      return analytics;
    } catch (e) {
      print('DEBUG: Analytics failed: $e');
      throw Exception('Failed to get analytics: $e');
    }
  }
}