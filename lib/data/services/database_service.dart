import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firebase_constants.dart';

class DatabaseService {
  final FirebaseService _firebaseService = FirebaseService.instance;

  // Initialize database with basic setup (no complex index testing)
  Future<void> initializeDatabase() async {
    try {
      // Enable offline persistence first
      await _setupOfflinePersistence();

      // Set up real-time listeners for critical collections
      await _setupRealtimeListeners();

      // Test basic connectivity with simple queries
      await _testBasicConnectivity();

      print('Database initialized successfully');
    } catch (e) {
      print('Database initialization error: $e');
    }
  }

  // Setup offline persistence
  Future<void> _setupOfflinePersistence() async {
    try {
      await _firebaseService.firestore.enablePersistence();
      print('Offline persistence enabled');
    } catch (e) {
      // Persistence might already be enabled
      if (!e.toString().contains('already enabled')) {
        print('Persistence setup warning: $e');
      }
    }
  }

  // Test basic connectivity with simple queries (no indexes needed)
  Future<void> _testBasicConnectivity() async {
    try {
      // Test simple count query
      await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .limit(1)
          .get()
          .timeout(Duration(seconds: 10));

      print('Database connectivity test passed');
    } catch (e) {
      print('Database connectivity test failed: $e');
    }
  }

  // Setup real-time listeners for performance
  Future<void> _setupRealtimeListeners() async {
    // Set up basic settings for better performance
    final settings = _firebaseService.firestore.settings;
    if (settings.persistenceEnabled==true) {
      print('Persistence is enabled');
    }
  }

  // Batch operations for better performance
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firebaseService.firestore.batch();

      for (final operation in operations) {
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String?;
        final data = operation['data'] as Map<String, dynamic>;
        final operationType = operation['type'] as String; // 'set', 'update', 'delete'

        final docRef = docId != null
            ? _firebaseService.firestore.collection(collection).doc(docId)
            : _firebaseService.firestore.collection(collection).doc();

        switch (operationType) {
          case 'set':
            batch.set(docRef, data);
            break;
          case 'update':
            batch.update(docRef, data);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Batch operation failed: $e');
    }
  }

  // Transaction for atomic operations
  Future<T> runTransaction<T>(Future<T> Function(Transaction) updateFunction) async {
    try {
      return await _firebaseService.firestore.runTransaction(updateFunction);
    } catch (e) {
      throw Exception('Transaction failed: $e');
    }
  }

  // Get collection statistics with simple queries
  Future<Map<String, int>> getCollectionStats() async {
    try {
      final stats = <String, int>{};

      // Use simple collection references for counting
      try {
        final usersSnapshot = await _firebaseService.firestore
            .collection(FirebaseConstants.usersCollection)
            .count()
            .get()
            .timeout(Duration(seconds: 10));
        stats['users'] = usersSnapshot.count ?? 0;
      } catch (e) {
        print('Users count error: $e');
        stats['users'] = 0;
      }

      try {
        final productsSnapshot = await _firebaseService.firestore
            .collection(FirebaseConstants.productsCollection)
            .count()
            .get()
            .timeout(Duration(seconds: 10));
        stats['products'] = productsSnapshot.count ?? 0;
      } catch (e) {
        print('Products count error: $e');
        stats['products'] = 0;
      }

      try {
        final ordersSnapshot = await _firebaseService.firestore
            .collection(FirebaseConstants.ordersCollection)
            .count()
            .get()
            .timeout(Duration(seconds: 10));
        stats['orders'] = ordersSnapshot.count ?? 0;
      } catch (e) {
        print('Orders count error: $e');
        stats['orders'] = 0;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get collection stats: $e');
    }
  }

  // Health check for database
  Future<bool> healthCheck() async {
    try {
      await _firebaseService.firestore
          .collection('_health')
          .doc('check')
          .set({
        'timestamp': Timestamp.now(),
        'status': 'ok'
      })
          .timeout(Duration(seconds: 5));

      return true;
    } catch (e) {
      print('Database health check failed: $e');
      return false;
    }
  }
}