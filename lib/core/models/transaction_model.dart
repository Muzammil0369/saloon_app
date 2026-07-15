// lib/core/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  topup,           // Customer adds money to wallet
  wallet_payment,  // Customer pays via in-app wallet
  cash_payment,    // Customer pays cash at salon
  digital_payment, // Customer pays via EasyPaisa/JazzCash at salon
  commission,      // Platform commission deducted
  withdrawal,      // Owner withdraws earnings
  refund,          // Refund to customer
  bonus,           // Referral bonus, loyalty rewards
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  reversed,
}

class TransactionModel {
  final String? id;
  final String userId;
  final String userType; // 'customer', 'owner', 'platform'
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String description;
  final String? referenceId; // bookingId, withdrawalId, etc.
  final String? paymentMethod; // 'easypaisa', 'jazzcash', 'wallet', 'cash'
  final double? commissionRate;
  final double? commissionAmount;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransactionModel({
    this.id,
    required this.userId,
    required this.userType,
    required this.type,
    this.status = TransactionStatus.pending,
    required this.amount,
    required this.description,
    this.referenceId,
    this.paymentMethod,
    this.commissionRate,
    this.commissionAmount,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userType': userType,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'description': description,
      'referenceId': referenceId,
      'paymentMethod': paymentMethod,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'metadata': metadata,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userType: data['userType'] ?? 'customer',
      type: _parseTransactionType(data['type']),
      status: _parseTransactionStatus(data['status']),
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      referenceId: data['referenceId'],
      paymentMethod: data['paymentMethod'],
      commissionRate: data['commissionRate']?.toDouble(),
      commissionAmount: data['commissionAmount']?.toDouble(),
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static TransactionType _parseTransactionType(String? type) {
    return TransactionType.values.firstWhere(
          (e) => e.name == type,
      orElse: () => TransactionType.cash_payment,
    );
  }

  static TransactionStatus _parseTransactionStatus(String? status) {
    return TransactionStatus.values.firstWhere(
          (e) => e.name == status,
      orElse: () => TransactionStatus.pending,
    );
  }

  // Helper: Create a topup transaction
  factory TransactionModel.topup({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) {
    return TransactionModel(
      userId: userId,
      userType: 'customer',
      type: TransactionType.topup,
      status: TransactionStatus.pending,
      amount: amount,
      description: 'Wallet top-up via $paymentMethod',
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );
  }

  // Helper: Create cash payment transaction
  factory TransactionModel.cashPayment({
    required String customerId,
    required String ownerId,
    required double amount,
    required String bookingId,
    double commissionRate = 15.0,
  }) {
    final commissionAmount = amount * (commissionRate / 100);
    return TransactionModel(
      userId: customerId,
      userType: 'customer',
      type: TransactionType.cash_payment,
      status: TransactionStatus.completed,
      amount: amount,
      description: 'Cash payment at salon',
      referenceId: bookingId,
      paymentMethod: 'cash',
      commissionRate: commissionRate,
      commissionAmount: commissionAmount,
      metadata: {'ownerId': ownerId},
      createdAt: DateTime.now(),
    );
  }

  // Helper: Create digital payment transaction
  factory TransactionModel.digitalPayment({
    required String customerId,
    required String ownerId,
    required double amount,
    required String bookingId,
    required String paymentMethod, // 'easypaisa', 'jazzcash'
    double commissionRate = 15.0,
  }) {
    final commissionAmount = amount * (commissionRate / 100);
    return TransactionModel(
      userId: customerId,
      userType: 'customer',
      type: TransactionType.digital_payment,
      status: TransactionStatus.completed,
      amount: amount,
      description: 'Digital payment via $paymentMethod at salon',
      referenceId: bookingId,
      paymentMethod: paymentMethod,
      commissionRate: commissionRate,
      commissionAmount: commissionAmount,
      metadata: {'ownerId': ownerId},
      createdAt: DateTime.now(),
    );
  }

  // Helper: Create wallet payment transaction
  factory TransactionModel.walletPayment({
    required String customerId,
    required String ownerId,
    required double amount,
    required String bookingId,
    double commissionRate = 15.0,
  }) {
    final commissionAmount = amount * (commissionRate / 100);
    final ownerGets = amount - commissionAmount;
    return TransactionModel(
      userId: customerId,
      userType: 'customer',
      type: TransactionType.wallet_payment,
      status: TransactionStatus.completed,
      amount: amount,
      description: 'Wallet payment at salon',
      referenceId: bookingId,
      paymentMethod: 'wallet',
      commissionRate: commissionRate,
      commissionAmount: commissionAmount,
      metadata: {'ownerId': ownerId, 'ownerGets': ownerGets},
      createdAt: DateTime.now(),
    );
  }

  // Helper: Create commission transaction
  factory TransactionModel.commission({
    required double amount,
    required String ownerId,
    required String bookingId,
    double rate = 15.0,
  }) {
    return TransactionModel(
      userId: 'platform',
      userType: 'platform',
      type: TransactionType.commission,
      status: TransactionStatus.completed,
      amount: amount,
      description: 'Platform commission (${rate}%)',
      referenceId: bookingId,
      commissionRate: rate,
      metadata: {'ownerId': ownerId},
      createdAt: DateTime.now(),
    );
  }

  // Helper: Create withdrawal transaction
  factory TransactionModel.withdrawal({
    required String ownerId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      userId: ownerId,
      userType: 'owner',
      type: TransactionType.withdrawal,
      status: TransactionStatus.pending,
      amount: amount,
      description: 'Withdrawal via $paymentMethod',
      paymentMethod: paymentMethod,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
  }

  // Helper: Create refund transaction
  factory TransactionModel.refund({
    required String customerId,
    required double amount,
    required String bookingId,
    String reason = 'Booking cancelled',
  }) {
    return TransactionModel(
      userId: customerId,
      userType: 'customer',
      type: TransactionType.refund,
      status: TransactionStatus.completed,
      amount: amount,
      description: reason,
      referenceId: bookingId,
      paymentMethod: 'wallet',
      createdAt: DateTime.now(),
    );
  }
}