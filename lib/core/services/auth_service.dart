// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

// Send verification email (Firebase built-in mail — free on the Spark plan).
  // Returns true if the mail was sent OR the address is already verified.
  // On failure returns false and fills [lastVerificationError].
  String? lastVerificationError;

  Future<bool> sendEmailVerification() async {
    lastVerificationError = null;
    final user = _auth.currentUser;
    if (user == null) {
      lastVerificationError = 'Please sign in again.';
      return false;
    }
    if (user.emailVerified) return true;
    try {
      await user.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('sendEmailVerification failed: ${e.code}');
      lastVerificationError = e.code == 'too-many-requests'
          ? 'Too many emails requested. Please wait a few minutes and try again.'
          : 'Could not send the email. Check your connection and try again.';
      return false;
    } catch (e) {
      debugPrint('sendEmailVerification failed: $e');
      lastVerificationError = 'Could not send the email. Please try again.';
      return false;
    }
  }

  /// True for password accounts whose email is not verified yet.
  /// Google accounts are already verified by Google.
  bool get needsEmailVerification {
    final u = _auth.currentUser;
    if (u == null || u.emailVerified) return false;
    return u.providerData.any((p) => p.providerId == 'password');
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
        if (role == 'customer') 'profileSetupDone': false,
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

  // ==================== GOOGLE SIGN-IN ====================
  /// Step 1: Google account picker -> Firebase sign-in.
  /// Returns whether a Salonify profile (users/{uid}) already exists.
  /// A brand-new Google user has NO profile yet: the UI must ask for a role
  /// and call [completeGoogleSignup] (or [logout] if they back out).
  Future<GoogleAuthResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return GoogleAuthResult(cancelled: true); // user closed the picker
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userRole = doc.data()?['role'] as String?;
        await _firestore.collection('users').doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
        return GoogleAuthResult(success: true, isNewUser: false);
      }
      return GoogleAuthResult(success: true, isNewUser: true);
    } on FirebaseAuthException catch (e) {
      String error;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          error = 'This email is already registered with a password. Please sign in with your email and password.';
          break;
        case 'user-disabled':
          error = 'This account has been disabled';
          break;
        case 'network-request-failed':
          error = 'No internet connection';
          break;
        default:
          error = 'Google sign-in failed. Please try again.';
      }
      return GoogleAuthResult(error: error);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return GoogleAuthResult(error: 'Google sign-in failed. Please try again.');
    }
  }

  /// Step 2 (new Google users only): create the same documents email sign-up
  /// creates, for the chosen role ('customer' or 'owner').
  Future<bool> completeGoogleSignup(String role) async {
    final u = _auth.currentUser;
    if (u == null || (role != 'customer' && role != 'owner')) return false;
    try {
      await _firestore.collection('users').doc(u.uid).set({
        'name': (u.displayName ?? '').trim().isEmpty ? (role == 'owner' ? 'Owner' : 'Customer') : u.displayName!.trim(),
        'email': (u.email ?? '').toLowerCase(),
        'role': role,
        'status': 'active',
        if (role == 'customer') 'profileSetupDone': false,
        'signInMethod': 'google',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': GetPlatform.isAndroid ? 'android' : GetPlatform.isIOS ? 'ios' : 'web',
          'appVersion': '1.0.0',
        },
      });

      if (role == 'owner') {
        await _firestore.collection('owners').doc(u.uid).set({
          'status': 'pending',
          'isActive': false,
          'showOnMap': false,
          'createdAt': FieldValue.serverTimestamp(),
          'registrationStep': 1,
        });
      } else {
        await _firestore.collection('wallets').doc(u.uid).set({
          'balance': 0.0,
          'commissionOwed': 0.0,
          'totalSpent': 0.0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _firestore.collection('audit_logs').add({
        'action': 'USER_REGISTERED',
        'userId': u.uid,
        'role': role,
        'method': 'google',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _userRole = role;
      return true;
    } catch (e) {
      debugPrint('completeGoogleSignup failed: $e');
      return false;
    }
  }

  // ==================== ACCOUNT DELETION ====================
  /// True when the signed-in user logs in with email + password.
  bool get usesPasswordLogin =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;

  /// Firebase only lets a RECENTLY signed-in user delete their account, so the
  /// app re-confirms identity first. Returns an error message, or null on success.
  Future<String?> reauthenticateWithPassword(String password) async {
    final u = _auth.currentUser;
    if (u == null || u.email == null) return 'Please sign in again.';
    try {
      await u.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: u.email!, password: password),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') return 'Incorrect password';
      if (e.code == 'too-many-requests') return 'Too many attempts. Try again later.';
      return 'Could not confirm your identity. Please try again.';
    } catch (_) {
      return 'Could not confirm your identity. Please try again.';
    }
  }

  Future<String?> reauthenticateWithGoogle() async {
    final u = _auth.currentUser;
    if (u == null) return 'Please sign in again.';
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Cancelled';
      final googleAuth = await googleUser.authentication;
      await u.reauthenticateWithCredential(GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ));
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-mismatch') return 'Please choose the same Google account you signed in with.';
      return 'Could not confirm your identity. Please try again.';
    } catch (_) {
      return 'Could not confirm your identity. Please try again.';
    }
  }

  /// Removes the sign-in itself from Firebase Authentication (the "Users" tab).
  /// Call AFTER the Firestore data is deleted and after re-authentication.
  Future<void> deleteAuthAccount() async {
    await _auth.currentUser?.delete();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    _userRole = null;
    _lastAttempts.clear();
  }

  // ==================== LOGOUT ====================
  Future<void> logout() async {
    _userRole = null;
    _lastAttempts.clear();
    try {
      await GoogleSignIn().signOut(); // so the account picker shows next time
    } catch (_) {}
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

class GoogleAuthResult {
  final bool success;
  final bool cancelled;
  final bool isNewUser;
  final String? error;
  GoogleAuthResult({
    this.success = false,
    this.cancelled = false,
    this.isNewUser = false,
    this.error,
  });
}