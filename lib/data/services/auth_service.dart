import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firebase_constants.dart';

class AuthService {
  final FirebaseService _firebaseService = FirebaseService.instance;

  Future<UserCredential?> registerSeller({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String businessName,
  }) async {
    UserCredential? credential;

    try {
      // First, create the Firebase Auth user
      credential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user account');
      }

      print('Firebase Auth user created: ${credential.user!.uid}');

      // Then create the Firestore user document
      final userData = {
        'role': 'seller',
        'name': name,
        'phone': phone,
        'email': email,
        'businessName': businessName,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profileImageUrl': null,
        'businessInfo': null,
      };

      // Use the user's UID as the document ID for proper security rules
      await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(userData);

      print('Firestore user document created');

      // Wait a moment for Firestore to process
      await Future.delayed(const Duration(milliseconds: 500));

      return credential;

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during registration: ${e.code} - ${e.message}');
      await _cleanupFailedRegistration(credential);
      throw Exception(_handleAuthException(e));
    } on FirebaseException catch (e) {
      print('FirebaseException during registration: ${e.code} - ${e.message}');
      await _cleanupFailedRegistration(credential);
      throw Exception('Database error during registration: ${e.message}');
    } catch (e) {
      print('General exception during registration: $e');
      await _cleanupFailedRegistration(credential);
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting sign in for: $email');

      final credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed: No user returned');
      }

      print('Firebase Auth successful for: ${credential.user!.uid}');

      // Verify the user document exists in Firestore
      try {
        final userDoc = await _firebaseService.firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(credential.user!.uid)
            .get();

        if (!userDoc.exists) {
          print('User document does not exist in Firestore');
          await _firebaseService.auth.signOut();
          throw Exception('Account found but profile is missing. Please contact support.');
        }

        if (userDoc.data() == null || (userDoc.data() as Map).isEmpty) {
          print('User document exists but is empty');
          await _firebaseService.auth.signOut();
          throw Exception('Account found but profile is incomplete. Please contact support.');
        }

        print('User document verified in Firestore');

      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          await _firebaseService.auth.signOut();
          throw Exception('Access denied. Please check your account permissions.');
        }
        rethrow;
      }

      return credential;

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    } on FirebaseException catch (e) {
      print('FirebaseException during sign in: ${e.code} - ${e.message}');
      throw Exception('Database access error: ${e.message}');
    } catch (e) {
      print('General exception during sign in: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Sign in failed: ${e.toString()}');
      }
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    final user = _firebaseService.currentUser;
    if (user == null) {
      print('No authenticated user found');
      return null;
    }

    try {
      print('Fetching user data for: ${user.uid}');

      final doc = await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        print('User document does not exist in Firestore');
        return null;
      }

      final data = doc.data();
      if (data == null || data.isEmpty) {
        print('User document exists but contains no data');
        return null;
      }

      print('User data retrieved successfully');
      return _parseUserModel(doc);

    } on FirebaseException catch (e) {
      print('FirebaseException getting user data: ${e.code} - ${e.message}');

      if (e.code == 'permission-denied') {
        print('Permission denied accessing user data');
        // Don't return null immediately, this might be a temporary issue
        throw Exception('Access denied: Please check your account permissions');
      }

      return null;
    } catch (e) {
      print('Exception getting user data: $e');
      return null;
    }
  }

  UserModel _parseUserModel(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      userId: doc.id,
      role: data['role'] ?? 'seller',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      businessName: data['businessName'],
      isVerified: data['isVerified'] ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      profileImageUrl: data['profileImageUrl'],
      businessInfo: data['businessInfo'],
    );
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Future<void> _cleanupFailedRegistration(UserCredential? credential) async {
    if (credential?.user == null) return;

    try {
      print('Cleaning up failed registration for: ${credential!.user!.uid}');

      // Delete Firestore document first
      await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(credential.user!.uid)
          .delete();

      // Then delete the auth user
      await credential.user!.delete();

      print('Cleanup completed');
    } catch (e) {
      print('Error during cleanup (non-critical): $e');
      // Silent cleanup failure - this is non-critical
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await _firebaseService.auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      print('Error checking email existence: ${e.code} - ${e.message}');

      // If user-not-found, email doesn't exist
      if (e.code == 'user-not-found') {
        return false;
      }

      // For other errors, assume email might exist (safer approach)
      return true;
    } catch (e) {
      print('General error checking email: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      print('Signing out user');
      await _firebaseService.signOut();
      print('Sign out completed');
    } catch (e) {
      print('Error during sign out: $e');
      // Don't throw, just log the error
    }
  }

  // Test method to verify Firestore connectivity
  Future<bool> testFirestoreConnection() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        print('No user to test Firestore connection');
        return false;
      }

      print('Testing Firestore connection for user: ${user.uid}');

      // Try to read the user document
      final doc = await _firebaseService.firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();

      print('Firestore connection test successful');
      return true;

    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait before trying again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }
}