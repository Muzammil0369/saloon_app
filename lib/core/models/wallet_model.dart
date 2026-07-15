// lib/core/models/wallet_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String userId;
  final String userType; // 'customer' or 'owner'
  final double balance; // Available balance
  final double commissionOwed; // Owner owes to platform (from cash/digital payments)
  final double totalEarned; // Owner: total earned
  final double totalSpent; // Customer: total spent
  final double totalWithdrawn; // Owner: total withdrawn
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WalletModel({
    required this.userId,
    required this.userType,
    this.balance = 0.0,
    this.commissionOwed = 0.0,
    this.totalEarned = 0.0,
    this.totalSpent = 0.0,
    this.totalWithdrawn = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Factory for creating a new wallet
  factory WalletModel.create({
    required String userId,
    required String userType,
  }) {
    return WalletModel(
      userId: userId,
      userType: userType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userType': userType,
      'balance': balance,
      'commissionOwed': commissionOwed,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'totalWithdrawn': totalWithdrawn,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      userId: data['userId'] ?? doc.id,
      userType: data['userType'] ?? 'customer',
      balance: (data['balance'] ?? 0.0).toDouble(),
      commissionOwed: (data['commissionOwed'] ?? 0.0).toDouble(),
      totalEarned: (data['totalEarned'] ?? 0.0).toDouble(),
      totalSpent: (data['totalSpent'] ?? 0.0).toDouble(),
      totalWithdrawn: (data['totalWithdrawn'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  WalletModel copyWith({
    double? balance,
    double? commissionOwed,
    double? totalEarned,
    double? totalSpent,
    double? totalWithdrawn,
    bool? isActive,
  }) {
    return WalletModel(
      userId: userId,
      userType: userType,
      balance: balance ?? this.balance,
      commissionOwed: commissionOwed ?? this.commissionOwed,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Available balance
  double get availableBalance => balance;

  // Check if user can make a payment
  bool canPay(double amount) => availableBalance >= amount;

  // Check if owner can withdraw
  bool canWithdraw(double amount) => availableBalance >= amount;
}