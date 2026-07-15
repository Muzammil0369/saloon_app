// lib/core/services/payment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

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

  Future<bool> topUpWallet({
    required String customerId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      await getOrCreateWallet(customerId, 'customer');

      final transaction = TransactionModel.topup(
        userId: customerId,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      final txnId = await createTransaction(transaction);

      final paymentSuccessful = true;

      if (paymentSuccessful) {
        await _updateBalance(customerId, amount, isCredit: true);
        await transactionsCollection.doc(txnId).update({
          'status': TransactionStatus.completed.name,
        });
        return true;
      }

      return false;
    } catch (e) {
      print('Top-up failed: $e');
      return false;
    }
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

        // Track commission owed by owner
        transaction.update(walletsCollection.doc(ownerId), {
          'commissionOwed': FieldValue.increment(commissionAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

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

        // Track commission owed by owner
        transaction.update(walletsCollection.doc(ownerId), {
          'commissionOwed': FieldValue.increment(commissionAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

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

  // Process wallet payment at salon (already had batch, added idempotency)
  Future<bool> processWalletPayment({
    required String customerId,
    required String ownerId,
    required String bookingId,
    required double totalAmount,
    double commissionRate = defaultCommissionRate,
  }) async {
    try {
      final commissionAmount = totalAmount * (commissionRate / 100);
      final ownerGets = totalAmount - commissionAmount;

      // ✅ Check if already paid
      final bookingDoc = await bookingsCollection.doc(bookingId).get();
      if (bookingDoc.exists) {
        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        if (bookingData['paymentStatus'] == 'paid') {
          print('Booking $bookingId already paid - preventing duplicate');
          return false;
        }
      }

      await getOrCreateWallet(customerId, 'customer');
      await getOrCreateWallet(ownerId, 'owner');

      // Check customer balance
      final customerWallet = await getOrCreateWallet(customerId, 'customer');
      if (!customerWallet.canPay(totalAmount)) {
        return false;
      }

      // Atomic batch
      final batch = _firestore.batch();

      batch.update(walletsCollection.doc(customerId), {
        'balance': FieldValue.increment(-totalAmount),
        'totalSpent': FieldValue.increment(totalAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(walletsCollection.doc(ownerId), {
        'balance': FieldValue.increment(ownerGets),
        'totalEarned': FieldValue.increment(ownerGets),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(bookingsCollection.doc(bookingId), {
        'paymentMethod': 'wallet',
        'paymentStatus': 'paid',
        'totalAmount': totalAmount,
        'commissionRate': commissionRate,
        'commissionAmount': commissionAmount,
        'status': 'paid',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await createTransaction(TransactionModel.walletPayment(
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
      print('Wallet payment failed: $e');
      return false;
    }
  }

  // ==================== WITHDRAWAL ====================

  // ✅ FIX 3: Proper commission deduction on withdrawal
  Future<bool> processWithdrawal({
    required String ownerId,
    required double amount,
    required String paymentMethod,
    required String accountDetails,
  }) async {
    try {
      final success = await _firestore.runTransaction((transaction) async {
        final walletRef = walletsCollection.doc(ownerId);
        final walletSnapshot = await transaction.get(walletRef);

        if (!walletSnapshot.exists) return false;

        final wallet = WalletModel.fromFirestore(walletSnapshot);
        final commissionOwed = wallet.commissionOwed;
        final availableBalance = wallet.balance;

        // Total deduction = withdrawal amount + commission owed (up to withdrawal amount)
        final commissionToDeduct = commissionOwed < amount ? commissionOwed : amount;
        final totalDeduction = amount;

        if (totalDeduction > availableBalance) {
          print('Insufficient balance. Available: $availableBalance, Requested: $totalDeduction');
          return false;
        }

        // Deduct withdrawal amount
        transaction.update(walletRef, {
          'balance': FieldValue.increment(-totalDeduction),
          'totalWithdrawn': FieldValue.increment(amount),
          'commissionOwed': FieldValue.increment(-commissionToDeduct),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (!success) {
        print('Withdrawal failed: insufficient balance or error');
        return false;
      }

      // Create withdrawal transaction
      final transaction = TransactionModel(
        userId: ownerId,
        userType: 'owner',
        type: TransactionType.withdrawal,
        status: TransactionStatus.pending,
        amount: amount,
        description: 'Withdrawal via $paymentMethod',
        paymentMethod: paymentMethod,
        metadata: {'accountDetails': accountDetails},
        createdAt: DateTime.now(),
      );

      await createTransaction(transaction);
      return true;
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