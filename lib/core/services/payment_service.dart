// lib/core/services/payment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

// Supabase Edge Function endpoints — the ONLY place money-moving writes
// happen now. The client no longer writes wallet balances or payment
// confirmations directly; every one of these goes through a trusted
// server function first.
const String _walletPaymentFunctionUrl =
    'https://rzypfwjhngpwlxfbxtcg.supabase.co/functions/v1/wallet-payment';
const String _walletWithdrawalFunctionUrl =
    'https://rzypfwjhngpwlxfbxtcg.supabase.co/functions/v1/wallet-withdrawal';
const String _confirmSalonPaymentFunctionUrl =
    'https://rzypfwjhngpwlxfbxtcg.supabase.co/functions/v1/confirm-salon-payment';
const String _supabasePublishableKey =
    'sb_publishable_iO6I9436lSKFoeq_9bDXgQ_p8hXXD2L';

// Every Edge Function call gets a hard timeout — without this, if a
// function isn't deployed yet or the network hangs, the app would show
// a loading spinner forever instead of a clear error.
const Duration _functionTimeout = Duration(seconds: 15);

class PaymentService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get walletsCollection => _firestore.collection('wallets');
  CollectionReference get transactionsCollection => _firestore.collection('transactions');
  CollectionReference get bookingsCollection => _firestore.collection('bookings');

  static const double defaultCommissionRate = 0;

  // ==================== WALLET OPERATIONS ====================

  Future<WalletModel> getOrCreateWallet(String userId, String userType) async {
    final doc = await walletsCollection.doc(userId).get();

    if (doc.exists) {
      return WalletModel.fromFirestore(doc);
    }

    final wallet = WalletModel.create(userId: userId, userType: userType);
    await walletsCollection.doc(userId).set(wallet.toMap());
    return wallet;
  }

  Stream<WalletModel?> streamWallet(String userId) {
    return walletsCollection.doc(userId).snapshots().map(
          (doc) => doc.exists ? WalletModel.fromFirestore(doc) : null,
    );
  }

  Future<double> getBalance(String userId) async {
    final doc = await walletsCollection.doc(userId).get();
    if (doc.exists) {
      final wallet = WalletModel.fromFirestore(doc);
      return wallet.balance;
    }
    return 0.0;
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Stream<List<TransactionModel>> streamUserTransactions(String userId) {
    return transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList());
  }

  // ==================== TOP-UP (Disabled) ====================

  // DISABLED: there is no real payment gateway wired in yet. This used to
  // hardcode "paymentSuccessful = true" and credit the wallet with fake
  // money — anyone could top up any amount for free. Rather than pretend
  // that's secure, this is switched off until a real gateway (EasyPaisa/
  // JazzCash merchant API) is integrated behind its own Edge Function.
  Future<bool> topUpWallet({
    required String customerId,
    required double amount,
    required String paymentMethod,
  }) async {
    print('Top-up is temporarily disabled — no payment gateway is integrated yet.');
    return false;
  }

  // ==================== PAY AT SALON METHODS ====================
  // Cash and digital (EasyPaisa/JazzCash) payments are OWNER-confirmed —
  // the owner has already physically verified cash in hand or money in
  // their account before tapping this. Both go through the same Edge
  // Function since the trust model and the resulting write are identical.

  Future<bool> processCashPayment({
    required String customerId,
    required String ownerId,
    required String bookingId,
    required double totalAmount,
    double commissionRate = defaultCommissionRate,
  }) async {
    return _confirmSalonPayment(
      bookingId: bookingId,
      customerId: customerId,
      totalAmount: totalAmount,
      paymentMethod: 'cash',
    );
  }

  Future<bool> processDigitalPayment({
    required String customerId,
    required String ownerId,
    required String bookingId,
    required double totalAmount,
    required String paymentMethod,
    double commissionRate = defaultCommissionRate,
  }) async {
    return _confirmSalonPayment(
      bookingId: bookingId,
      customerId: customerId,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
    );
  }

  Future<bool> _confirmSalonPayment({
    required String bookingId,
    required String customerId,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('Payment confirmation failed: not logged in');
        return false;
      }

      final idToken = await currentUser.getIdToken();

      final response = await http.post(
        Uri.parse(_confirmSalonPaymentFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'apikey': _supabasePublishableKey,
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'customerId': customerId,
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod,
        }),
      ).timeout(_functionTimeout);

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return true;
      }

      print('Payment confirmation rejected: ${decoded['error']}');
      return false;
    } on TimeoutException {
      print('Payment confirmation timed out — check that confirm-salon-payment is deployed on Supabase.');
      return false;
    } catch (e) {
      print('Payment confirmation failed: $e');
      return false;
    }
  }

  // Process wallet payment at salon.
  // SECURITY: this no longer writes wallet balances directly from the client.
  // It calls the Supabase Edge Function, which verifies the request server-side
  // (real logged-in user, booking ownership, no double-payment) before touching
  // any balance.
  Future<bool> processWalletPayment({
    required String customerId,
    required String ownerId,
    required String bookingId,
    required double totalAmount,
    double commissionRate = defaultCommissionRate,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('Wallet payment failed: not logged in');
        return false;
      }

      final idToken = await currentUser.getIdToken();

      final response = await http.post(
        Uri.parse(_walletPaymentFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'apikey': _supabasePublishableKey,
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'ownerId': ownerId,
          'totalAmount': totalAmount,
        }),
      ).timeout(_functionTimeout);

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return true;
      }

      print('Wallet payment rejected: ${decoded['error']}');
      return false;
    } on TimeoutException {
      print('Wallet payment timed out — check that wallet-payment is deployed on Supabase.');
      return false;
    } catch (e) {
      print('Wallet payment failed: $e');
      return false;
    }
  }

  // ==================== WITHDRAWAL ====================

  Future<bool> processWithdrawal({
    required String ownerId,
    required double amount,
    required String paymentMethod,
    required String accountDetails,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('Withdrawal failed: not logged in');
        return false;
      }

      final idToken = await currentUser.getIdToken();

      final response = await http.post(
        Uri.parse(_walletWithdrawalFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'apikey': _supabasePublishableKey,
        },
        body: jsonEncode({
          'amount': amount,
          'paymentMethod': paymentMethod,
          'accountDetails': accountDetails,
        }),
      ).timeout(_functionTimeout);

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return true;
      }

      print('Withdrawal rejected: ${decoded['error']}');
      return false;
    } on TimeoutException {
      print('Withdrawal timed out — check that wallet-withdrawal is deployed on Supabase.');
      return false;
    } catch (e) {
      print('Withdrawal failed: $e');
      return false;
    }
  }

  // ==================== OWNER COMMISSION SUMMARY ====================

  Future<Map<String, double>> getOwnerCommissionSummary(String ownerId) async {
    final wallet = await getOrCreateWallet(ownerId, 'owner');
    return {
      'commissionOwed': wallet.commissionOwed,
      'totalEarned': wallet.totalEarned,
      'availableBalance': wallet.availableBalance,
    };
  }

  // ==================== STREAMS FOR UI ====================

  Stream<List<TransactionModel>> streamOwnerEarnings(String ownerId) {
    return transactionsCollection
        .where('metadata.ownerId', isEqualTo: ownerId)
        .where('type', whereIn: ['cash_payment', 'digital_payment', 'wallet_payment'])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList());
  }

  Stream<double> streamPlatformRevenue() {
    return transactionsCollection
        .where('type', isEqualTo: 'commission')
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0.0).toDouble();
      }
      return total;
    });
  }

  Stream<List<TransactionModel>> streamAllTransactions({int limit = 50}) {
    return transactionsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList());
  }
}