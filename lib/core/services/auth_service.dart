import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Observable user state
  Rxn<User> user = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    // Bind current user to observable
    user.bindStream(_auth.userChanges());
  }

  // ── Phone Authentication ──
  
  String? _verificationId;
  int? _resendToken;

  Future<void> sendOTP(String phone, {
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (mostly Android)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String vid, int? token) {
          _verificationId = vid;
          _resendToken = token;
          onCodeSent(vid);
        },
        codeAutoRetrievalTimeout: (String vid) {
          _verificationId = vid;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<bool> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null) return false;
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Generic Logic ──

  Future<void> logout() async {
    await _auth.signOut();
  }

  bool get isLoggedIn => _auth.currentUser != null;
  String? get uid => _auth.currentUser?.uid;
}
