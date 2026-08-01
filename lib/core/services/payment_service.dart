// lib/core/services/payment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

// Supabase Edge Function endpoint — this is the ONLY place wallet-to-wallet
// payments should happen now. The client no longer writes wallet balances
// directly; this function verifies everything server-side first.
const String _walletPaymentFunctionUrl =
    'https://rzypfwjhngpwlxfbxtcg.supabase.co/functions/v1/wallet-payment';
const String _walletWithdrawalFunctionUrl =
    'https://rzypfwjhngpwlxfbxtcg.supabase.co/functions/v1/wallet-withdrawal';
const String _supabasePublishableKey =
    'sb_publishable_iO6I9436lSKFoeq_9bDXgQ_p8hXXD2L';

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

  Future<void> _updateBalance(String userId, double amount, {bool isCredit = true}) async {
    final balanceChange = isCredit ? amount : -amount;
    await walletsCollection.doc(userId).update({
      'balance': FieldValue.increment(balanceChange),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<String> createTransaction(TransactionModel transaction) async {
    final docRef = await transactionsCollection.add(transaction.toMap());
    return docRef.id;
  }

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

  // ==================== TOP-UP (Optional - Customer loads wallet) ====================

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

  // Process cash payment at salon (with idempotency check + transaction)
  Future<bool> processCashPayment({
    required String customerId,
    required String ownerId,
    required String bookingId,
    required double totalAmount,
    double commissionRate = defaultCommissionRate,
  }) async {
    try {
      final commissionAmount = totalAmount * (commissionRate / 100);

      // ✅ FIX 1 & 2: Use transaction + idempotency check
      final success = await _firestore.runTransaction((transaction) async {
        final bookingRef = bookingsCollection.doc(bookingId);
        final bookingSnapshot = await transaction.get(bookingRef);

        if (!bookingSnapshot.exists) return false;

        // ✅ Prevent double payment
        final bookingData = bookingSnapshot.data() as Map<String, dynamic>;
        if (bookingData['paymentStatus'] == 'paid') {
          print('Booking $bookingId already paid - preventing duplicate');
          return false;
        }

        // Update booking atomically
        transaction.update(bookingRef, {
          'paymentMethod': 'cash',
          'paymentStatus': 'paid',
          'totalAmount': totalAmount,
          'commissionRate': commissionRate,
          'commissionAmount': commissionAmount,
          'status': 'paid',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Track commission owed by owner — only touch the wallets collection
        // if there's actually commission to track. Commission is 0 today
        // (no-commission launch decision), and wallets writes are now locked
        // to Admin-SDK-only, so skipping this when there's nothing to record
        // keeps cash payments working without needing an Edge Function yet.
        if (commissionAmount > 0) {
          transaction.update(walletsCollection.doc(ownerId), {
            'commissionOwed': FieldValue.increment(commissionAmount),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        return true;
      });

      if (!success) return false;

      // Create transaction records (after successful atomic update)
      await createTransaction(TransactionModel.cashPayment(
        customerId: customerId,
        ownerId: ownerId,
        amount: totalAmount,
        bookingId: bookingId,
        commissionRate: commissionRate,
      ));

      await createTransaction(TransactionModel.commission(
        amount: commissionAmount,
        ownerId: ownerId,
        bookingId: bookingId,
        rate: commissionRate,
      ));

      return true;
    } catch (e) {
      print('Cash payment failed: $e');
      return false;
    }
  }

  // Process digital payment at salon (with idempotency check + transaction)
  Future<bool> processDigitalPayment({
    required String customerId,
    required String ownerId,
    required String bookingId,
    required double totalAmount,
    required String paymentMethod,
    double commissionRate = defaultCommissionRate,
  }) async {
    try {
      final commissionAmount = totalAmount * (commissionRate / 100);

      // ✅ FIX 1 & 2: Use transaction + idempotency check
      final success = await _firestore.runTransaction((transaction) async {
        final bookingRef = bookingsCollection.doc(bookingId);
        final bookingSnapshot = await transaction.get(bookingRef);

        if (!bookingSnapshot.exists) return false;

        // ✅ Prevent double payment
        final bookingData = bookingSnapshot.data() as Map<String, dynamic>;
        if (bookingData['paymentStatus'] == 'paid') {
          print('Booking $bookingId already paid - preventing duplicate');
          return false;
        }

        // Update booking atomically
        transaction.update(bookingRef, {
          'paymentMethod': paymentMethod,
          'paymentStatus': 'paid',
          'totalAmount': totalAmount,
          'commissionRate': commissionRate,
          'commissionAmount': commissionAmount,
          'status': 'paid',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Track commission owed by owner — only touch the wallets collection
        // if there's actually commission to track (see cash payment for why).
        if (commissionAmount > 0) {
          transaction.update(walletsCollection.doc(ownerId), {
            'commissionOwed': FieldValue.increment(commissionAmount),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        return true;
      });

      if (!success) return false;

      // Create transaction records
      await createTransaction(TransactionModel.digitalPayment(
        customerId: customerId,
        ownerId: ownerId,
        amount: totalAmount,
        bookingId: bookingId,
        paymentMethod: paymentMethod,
        commissionRate: commissionRate,
      ));

      await createTransaction(TransactionModel.commission(
        amount: commissionAmount,
        ownerId: ownerId,
        bookingId: bookingId,
        rate: commissionRate,
      ));

      return true;
    } catch (e) {
      print('Digital payment failed: $e');
      return false;
    }
  }

  // Process wallet payment at salon.
  // SECURITY: this no longer writes wallet balances directly from the client.
  // It calls the Supabase Edge Function, which verifies the request server-side
  // (real logged-in user, booking ownership, no double-payment) before touching
  // any balance. Same signature/behavior as before, so nothing else needs to change.
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

      // Firebase ID token — proves to the Edge Function who is really calling
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
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return true;
      }

      print('Wallet payment rejected: ${decoded['error']}');
      return false;
    } catch (e) {
      print('Wallet payment failed: $e');
      return false;
    }
  }

  // ==================== WITHDRAWAL ====================

  // Process withdrawal request. SECURITY: no longer deducts the wallet
  // balance directly from the client — calls the Edge Function, which
  // verifies the caller owns the wallet and has sufficient balance before
  // deducting anything. Actual payout (bank transfer) is still manual until
  // a real payment gateway is integrated — this only secures the balance
  // change and the withdrawal request record.
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
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return true;
      }

      print('Withdrawal rejected: ${decoded['error']}');
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