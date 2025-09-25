import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firebase_constants.dart';

class UserRepository {
  final FirebaseService _firebaseService = FirebaseService.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String userId) {
    return _firebaseService.firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.userId)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Create user
  Future<void> createUser(UserModel user) async {
    try {
      await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.userId)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Get sellers (for admin purposes)
  Future<List<UserModel>> getSellers({int limit = 20}) async {
    try {
      final query = await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .where('role', isEqualTo: 'seller')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get sellers: $e');
    }
  }

  // Verify seller account
  Future<void> verifySeller(String userId) async {
    try {
      await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({'isVerified': true});
    } catch (e) {
      throw Exception('Failed to verify seller: $e');
    }
  }
}
