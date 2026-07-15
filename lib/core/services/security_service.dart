// lib/core/services/security_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _secretKey = 'SALOON_APP_SECRET_KEY_2024_PAKISTAN';
  static const int _qrExpirySeconds = 120;

  // ==================== QR GENERATION ====================

  static Future<String> generateSecureQRPayload({
    required String bookingId,
    required String customerId,
    required String ownerId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = _generateNonce(32);
    final token = _generateToken(16);

    final payload = {
      'bookingId': bookingId,
      'customerId': customerId,
      'ownerId': ownerId,
      'timestamp': timestamp,
      'nonce': nonce,
      'token': token,
      'version': '2.0',
    };

    final payloadJson = jsonEncode(payload);
    final signature = _generateHMAC(payloadJson, _secretKey);
    final totp = _generateTOTP(bookingId + timestamp.toString());

    final signedPayload = {
      'p': payloadJson,
      's': signature,
      't': totp,
      'e': timestamp + (_qrExpirySeconds * 1000),
    };

    final secureQRData = base64Encode(utf8.encode(jsonEncode(signedPayload)));

    // Save token to Firestore
    await _firestore.collection('qr_tokens').doc(bookingId).set({
      'token': token,
      'nonce': nonce,
      'timestamp': timestamp,
      'customerId': customerId,
      'ownerId': ownerId,
      'used': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return secureQRData;
  }

  // ==================== QR VERIFICATION ====================

  static Future<VerificationResult> verifySecureQR(String scannedData, String ownerId) async {
    try {
      // Decode
      final jsonStr = utf8.decode(base64Decode(scannedData));
      final signedPayload = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Check expiry
      final expiryTime = signedPayload['e'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        return VerificationResult(
          success: false,
          message: 'QR Code expired. Ask customer to refresh.',
          code: 'EXPIRED',
        );
      }

      // Verify HMAC signature
      final payload = signedPayload['p'] as String;
      final signature = signedPayload['s'] as String;
      final expectedSignature = _generateHMAC(payload, _secretKey);

      if (!_constantTimeCompare(signature, expectedSignature)) {
        _logSecurityEvent('INVALID_SIGNATURE', scannedData, ownerId);
        return VerificationResult(
          success: false,
          message: 'Invalid QR Code.',
          code: 'INVALID_SIGNATURE',
        );
      }

      // Verify TOTP
      final totp = signedPayload['t'] as String;
      final payloadData = jsonDecode(payload) as Map<String, dynamic>;
      final expectedTOTP = _generateTOTP(
          payloadData['bookingId'] + payloadData['timestamp'].toString());

      if (totp != expectedTOTP) {
        _logSecurityEvent('INVALID_TOTP', scannedData, ownerId);
        return VerificationResult(
          success: false,
          message: 'QR Code verification failed.',
          code: 'INVALID_TOTP',
        );
      }

      final bookingId = payloadData['bookingId'] as String;

      // 🔐 ANTI-REPLAY: Use transaction to atomically check and mark as used
      bool alreadyUsed = false;

      try {
        await _firestore.runTransaction((transaction) async {
          final tokenRef = _firestore.collection('qr_tokens').doc(bookingId);
          final freshDoc = await transaction.get(tokenRef);

          if (!freshDoc.exists) {
            throw Exception('QR token not found');
          }

          final tokenData = freshDoc.data()!;

          // Check if already used
          if (tokenData['used'] == true) {
            alreadyUsed = true;
            throw Exception('ALREADY_USED');
          }

          // Check token match
          if (tokenData['token'] != payloadData['token'] ||
              tokenData['nonce'] != payloadData['nonce']) {
            throw Exception('TOKEN_MISMATCH');
          }

          // Check owner match
          if (tokenData['ownerId'] != ownerId) {
            throw Exception('WRONG_OWNER');
          }

          // ✅ Mark as used atomically
          transaction.update(tokenRef, {
            'used': true,
            'verifiedAt': FieldValue.serverTimestamp(),
            'verifiedBy': ownerId,
          });
        });

        if (alreadyUsed) {
          // Log replay attempt
          await _firestore.collection('security_alerts').add({
            'type': 'QR_REUSE_ATTEMPT',
            'bookingId': bookingId,
            'scannedBy': ownerId,
            'timestamp': FieldValue.serverTimestamp(),
            'severity': 'HIGH',
          });

          _logSecurityEvent('REPLAY_ATTACK', scannedData, ownerId);
          return VerificationResult(
            success: false,
            message: '⚠️ QR Code already used! This attempt has been logged.',
            code: 'ALREADY_USED',
          );
        }
      } catch (e) {
        if (e.toString().contains('ALREADY_USED')) {
          _logSecurityEvent('REPLAY_ATTACK', scannedData, ownerId);
          return VerificationResult(
            success: false,
            message: '⚠️ QR Code already used!',
            code: 'ALREADY_USED',
          );
        }
        if (e.toString().contains('TOKEN_MISMATCH')) {
          return VerificationResult(
            success: false,
            message: 'QR Code tampered.',
            code: 'TAMPERED',
          );
        }
        if (e.toString().contains('WRONG_OWNER')) {
          return VerificationResult(
            success: false,
            message: 'This QR is for a different salon.',
            code: 'WRONG_OWNER',
          );
        }
        throw e;
      }

      // Verify booking exists and is paid
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) {
        return VerificationResult(
          success: false,
          message: 'Booking not found.',
          code: 'BOOKING_NOT_FOUND',
        );
      }

      final bookingData = bookingDoc.data()!;
      if (bookingData['paymentStatus'] != 'paid') {
        return VerificationResult(
          success: false,
          message: 'Payment not confirmed.',
          code: 'NOT_PAID',
        );
      }

      // ✅ Mark booking as QR verified
      await _firestore.collection('bookings').doc(bookingId).update({
        'qrVerified': true,
        'qrVerifiedAt': FieldValue.serverTimestamp(),
        'qrVerifiedBy': ownerId,
      });

      _logSecurityEvent('VERIFICATION_SUCCESS', bookingId, ownerId);

      return VerificationResult(
        success: true,
        message: '✅ Verified! Customer verified successfully.',
        code: 'SUCCESS',
        bookingId: bookingId,
        customerId: payloadData['customerId'],
      );

    } catch (e) {
      _logSecurityEvent('VERIFICATION_ERROR', e.toString(), ownerId);
      return VerificationResult(
        success: false,
        message: 'Invalid QR format.',
        code: 'ERROR',
      );
    }
  }

  // ==================== CRYPTO HELPERS ====================

  static String _generateHMAC(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return base64Encode(digest.bytes);
  }

  static String _generateTOTP(String seed) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    final seedBytes = utf8.encode(seed + now.toString());
    final hash = sha256.convert(seedBytes);
    final code = int.parse(hash.toString().substring(0, 6), radix: 16) % 1000000;
    return code.toString().padLeft(6, '0');
  }

  static String _generateNonce(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Encode(bytes).substring(0, length);
  }

  static String _generateToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  static Future<void> _logSecurityEvent(String event, String data, String actorId) async {
    await _firestore.collection('security_logs').add({
      'event': event,
      'data': data.length > 200 ? data.substring(0, 200) : data,
      'actorId': actorId,
      'ipAddress': 'mobile_app',
      'timestamp': FieldValue.serverTimestamp(),
      'userAgent': 'Flutter App v2.0',
    });
  }
}

class VerificationResult {
  final bool success;
  final String message;
  final String code;
  final String? bookingId;
  final String? customerId;

  VerificationResult({
    required this.success,
    required this.message,
    required this.code,
    this.bookingId,
    this.customerId,
  });
}