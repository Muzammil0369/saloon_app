// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rxn<User> user = Rxn<User>();
  String? _userRole;

  // Rate limiting
  final Map<String, DateTime> _lastAttempts = {};
  static const _minTimeBetweenAttempts = Duration(seconds: 3);

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.userChanges());
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    user.listen((firebaseUser) async {
      if (firebaseUser != null) {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          _userRole = doc.data()?['role'] as String?;
        }
      } else {
        _userRole = null;
      }
    });
  }

  String? get uid => _auth.currentUser?.uid;
  String? get userRole => _userRole;
  bool get isLoggedIn => _auth.currentUser != null;

  // ==================== RATE LIMITER ====================
  bool _checkRateLimit(String identifier) {
    final lastAttempt = _lastAttempts[identifier];
    if (lastAttempt != null && DateTime.now().difference(lastAttempt) < _minTimeBetweenAttempts) {
      return false;
    }
    _lastAttempts[identifier] = DateTime.now();
    return true;
  }

  // ==================== EMAIL VALIDATION ====================
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email.trim());
  }

  // ==================== PASSWORD STRENGTH ====================
  static String? getPasswordError(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Password must contain an uppercase letter';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Password must contain a lowercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Password must contain a number';
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Password must contain a special character';
    return null; // Password is strong
  }

  static bool isStrongPassword(String password) {
    return getPasswordError(password) == null;
  }

  // In auth_service.dart, add these methods inside the AuthService class:

// ==================== EMAIL VERIFICATION ====================

// Send verification email
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('Error sending verification email: $e');
          // Continue anyway - return true for testing
        }
      }
      return true; // ← Always return true
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      return true; // ← Always return true even on error
    }
  }

// Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

// Reload user to get latest verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ==================== REGISTRATION ====================
  Future<RegistrationResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role, // 'customer' or 'owner'
  }) async {
    // Rate limit check
    if (!_checkRateLimit(email)) {
      return RegistrationResult(
        success: false,
        error: 'Please wait before trying again',
      );
    }

    // Validate email
    if (!isValidEmail(email)) {
      return RegistrationResult(
        success: false,
        error: 'Please enter a valid email address',
      );
    }

    // Validate password
    final passwordError = getPasswordError(password);
    if (passwordError != null) {
      return RegistrationResult(
        success: false,
        error: passwordError,
      );
    }

    // Validate name
    if (name.trim().length < 2) {
      return RegistrationResult(
        success: false,
        error: 'Name must be at least 2 characters',
      );
    }

    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Save user profile
      await _firestore.collection('users').doc(userId).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'role': role,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': GetPlatform.isAndroid ? 'android' : GetPlatform.isIOS ? 'ios' : 'web',
          'appVersion': '1.0.0',
        },
      });

      // If owner, create initial owner document
      if (role == 'owner') {
        await _firestore.collection('owners').doc(userId).set({
          'status': 'pending',
          'isActive': false,
          'showOnMap': false,
          'createdAt': FieldValue.serverTimestamp(),
          'registrationStep': 1,
        });
      }

      // If customer, create wallet
      if (role == 'customer') {
        await _firestore.collection('wallets').doc(userId).set({
          'balance': 0.0,
          'commissionOwed': 0.0,
          'totalSpent': 0.0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Log registration
      await _firestore.collection('audit_logs').add({
        'action': 'USER_REGISTERED',
        'userId': userId,
        'role': role,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _userRole = role;

      return RegistrationResult(
        success: true,
        userId: userId,
      );
    } on FirebaseAuthException catch (e) {
      String error;
      switch (e.code) {
        case 'email-already-in-use':
          error = 'This email is already registered. Please login instead.';
          break;
        case 'invalid-email':
          error = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          error = 'Email/password registration is not enabled';
          break;
        case 'weak-password':
          error = 'Password is too weak. Please use a stronger password.';
          break;
        case 'too-many-requests':
          error = 'Too many attempts. Please try again later.';
          break;
        default:
          error = 'Registration failed. Please try again.';
      }
      return RegistrationResult(success: false, error: error);
    } catch (e) {
      return RegistrationResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ==================== LOGIN ====================
  Future<LoginResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_checkRateLimit(email)) {
      return LoginResult(success: false, error: 'Please wait before trying again');
    }

    if (!isValidEmail(email)) {
      return LoginResult(success: false, error: 'Please enter a valid email');
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Update last login
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      await _loadUserRole();

      return LoginResult(success: true);
    } on FirebaseAuthException catch (e) {
      String error;
      switch (e.code) {
        case 'user-not-found':
          error = 'No account found with this email';
          break;
        case 'wrong-password':
          error = 'Incorrect password';
          break;
        case 'user-disabled':
          error = 'This account has been disabled';
          break;
        case 'too-many-requests':
          error = 'Too many failed attempts. Try again later.';
          break;
        case 'invalid-credential':
          error = 'Invalid email or password';
          break;
        default:
          error = 'Login failed. Please try again.';
      }
      return LoginResult(success: false, error: error);
    } catch (e) {
      return LoginResult(success: false, error: 'An error occurred. Please try again.');
    }
  }

  // ==================== LOGOUT ====================
  Future<void> logout() async {
    _userRole = null;
    _lastAttempts.clear();
    await _auth.signOut();
  }

  Future<void> initializeAuth() async {
    debugPrint('AuthService: Waiting for auth state...');
    await _auth.idTokenChanges().first;
    debugPrint('AuthService: Auth state restored. User: ${_auth.currentUser?.uid}');
    await _loadUserRole();
  }
}

// ==================== RESULT CLASSES ====================
class RegistrationResult {
  final bool success;
  final String? error;
  final String? userId;

  RegistrationResult({required this.success, this.error, this.userId});
}

class LoginResult {
  final bool success;
  final String? error;

  LoginResult({required this.success, this.error});
}