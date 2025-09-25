import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  FirebaseService? _firebaseService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('Firebase not initialized yet, waiting...');
        await _waitForFirebase();
      }

      _firebaseService = FirebaseService.instance;

      _firebaseService!.authStateChanges.listen((User? user) async {
        print('Auth state changed - User: ${user?.uid}');

        if (user != null) {
          // User signed in, load their data
          await _loadUserData(user);
        } else {
          // User signed out
          _currentUser = null;
          _isInitialized = true;
          notifyListeners();
        }
      });
    } catch (e) {
      print('Error initializing auth: $e');
      _error = 'Authentication service unavailable';
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _waitForFirebase() async {
    int attempts = 0;
    const maxAttempts = 50;

    while (Firebase.apps.isEmpty && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase initialization timeout');
    }
  }

  Future<void> _loadUserData(User user) async {
    try {
      print('Loading user data for user: ${user.uid}');

      // Show loading only for explicit auth operations, not state changes
      if (!_isLoading) {
        _setLoading(true);
      }

      _currentUser = await _authService.getCurrentUserData();

      if (_currentUser == null) {
        print('No user data found in Firestore for authenticated user');
        _error = 'Unable to load user profile. Your account may be incomplete.';
      } else {
        print('User data loaded successfully: ${_currentUser!.name}');
        _error = null;
      }

      _isInitialized = true;
      _setLoading(false);

    } catch (e) {
      print('Error loading user data: $e');
      _error = 'Failed to load user profile: ${e.toString()}';

      if (e.toString().contains('permission-denied') ||
          e.toString().contains('unauthenticated') ||
          e.toString().contains('invalid-credential')) {
        print('Auth error detected, signing out');
        await _authService.signOut();
        _currentUser = null;
      }

      _isInitialized = true;
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_firebaseService == null) {
      _error = 'Authentication service not available';
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Wait for auth state change with shorter timeout
      int waitTime = 0;
      const maxWaitTime = 5000; // Reduced to 5 seconds

      while (_isLoading && waitTime < maxWaitTime) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitTime += 100;
      }

      if (_currentUser == null && _error == null) {
        _error = 'Sign in succeeded but failed to load user profile.';
        return false;
      }

      return _currentUser != null;

    } catch (e) {
      print('Sign in error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerSeller({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String businessName,
  }) async {
    if (_firebaseService == null) {
      _error = 'Authentication service not available';
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      print('Starting registration process...');

      // Check if email is already in use
      final emailExists = await _authService.checkEmailExists(email);
      if (emailExists) {
        _error = 'This email is already registered. Please sign in instead.';
        return false;
      }

      // Proceed with registration
      final credential = await _authService.registerSeller(
        email: email,
        password: password,
        name: name,
        phone: phone,
        businessName: businessName,
      );

      if (credential?.user != null) {
        print('Registration successful, waiting for user data to load...');

        // Optimized wait - shorter timeout and more frequent checks
        int waitTime = 0;
        const maxWaitTime = 8000; // Reduced to 8 seconds
        const checkInterval = 150; // Check every 150ms

        while ((_currentUser == null || !_isInitialized) &&
            waitTime < maxWaitTime &&
            _error == null) {
          await Future.delayed(const Duration(milliseconds: checkInterval));
          waitTime += checkInterval;
        }

        if (_currentUser != null) {
          print('Registration completed successfully');
          return true;
        } else {
          _error = _error ?? 'Registration completed but failed to load user profile. Please try signing in.';
          return false;
        }
      }

      _error = 'Registration failed. Please try again.';
      return false;

    } catch (e) {
      print('Registration error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future signOut() async {
    if (_firebaseService == null) return;
    try {
      _setLoading(true);
      await _authService.signOut();
      _currentUser = null;
      _clearError();
      // Remove remember me preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Sign out error: $e');
    } finally {
      _setLoading(false);
    }
  }


  Future<bool> sendPasswordResetEmail(String email) async {
    if (_firebaseService == null) {
      _error = 'Authentication service not available';
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkEmailExists(String email) async {
    if (_firebaseService == null) return false;

    try {
      return await _authService.checkEmailExists(email);
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  Future<bool> retryLoadUserData() async {
    if (_firebaseService == null) return false;

    final user = _firebaseService!.currentUser;
    if (user != null) {
      await _loadUserData(user);
      return _currentUser != null;
    }
    return false;
  }

  /*Future<bool> cleanupCurrentUser() async {
    if (_firebaseService == null) return false;

    try {
      _setLoading(true);
      await _authService.deleteCurrentUser();
      _currentUser = null;
      _clearError();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }*/

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Add method to manually trigger success state
  void _triggerAuthSuccess() {
    if (_currentUser != null) {
      notifyListeners();
    }
  }
}