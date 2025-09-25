import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseApp? _app;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  // Private constructor
  FirebaseService._();

  // Singleton instance
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  // Initialize Firebase (call this once in main.dart)
  static Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        print('Firebase already initialized');
        _app = Firebase.app();
        return;
      }

      print('Initializing Firebase...');
      _app = await Firebase.initializeApp();
      print('Firebase initialized successfully');

    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        print('Firebase already initialized (duplicate-app caught)');
        _app = Firebase.app();
      } else {
        print('Firebase initialization error: $e');
        rethrow;
      }
    }
  }

  // Firebase Auth instance
  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instanceFor(app: _app!);
    return _auth!;
  }

  // Firestore instance
  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instanceFor(app: _app!);
    return _firestore!;
  }

  // Current user
  User? get currentUser => auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Sign out
  Future<void> signOut() async {
    await auth.signOut();
  }
}
