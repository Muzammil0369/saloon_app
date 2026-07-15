// lib/features/owner/screens/owner_earnings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';

class OwnerEarningsScreen extends StatefulWidget {
  const OwnerEarningsScreen({super.key});

  @override
  State<OwnerEarningsScreen> createState() => _OwnerEarningsScreenState();
}

class _OwnerEarningsScreenState extends State<OwnerEarningsScreen> {
  String get _ownerId => Get.find<AuthService>().uid ?? '';

  // Stream transactions for this owner
  Stream<List<Map<String, dynamic>>> _getTransactions() {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('metadata.ownerId', isEqualTo: _ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  // Stream wallet balance
  Stream<Map<String, dynamic>?> _getWallet() {
    return FirebaseFirestore.instance
        .collection('wallets')
        .doc(_ownerId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // Stream completed bookings count
  Stream<int> _getCompletedBookings() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: _ownerId)
        .where('status', whereIn: ['completed', 'paid'])
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('earnings'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _getWallet(),
        builder: (context, walletSnapshot) {
          final walletData = walletSnapshot.data;
          final balance = (walletData?['balance'] ?? 0.0).toDouble();
          final commissionOwed = (walletData?['commissionOwed'] ?? 0.0).toDouble();
          final totalEarned = (walletData?['totalEarned'] ?? 0.0).toDouble();
          final totalWithdrawn = (walletData?['totalWithdrawn'] ?? 0.0).toDouble();

          return StreamBuilder<int>(
            stream: _getCompletedBookings(),
            builder: (context, bookingSnapshot) {
              final completedBookings = bookingSnapshot.data ?? 0;

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getTransactions(),
                builder: (context, transactionSnapshot) {
                  final transactions = transactionSnapshot.data ?? [];

                  // Calculate totals from transactions
                  double totalRevenue = 0;
                  double totalCommission = 0;

                  for (var txn in transactions) {
                    final type = txn['type'] as String? ?? '';
                    final amount = (txn['amount'] ?? 0.0).toDouble();
                    if (type == 'commission') {
                      totalCommission += amount;
                    } else if (type == 'cash_payment' || type == 'digital_payment' || type == 'wallet_payment') {
                      totalRevenue += amount;
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                'available_balance'.tr,
                                'Rs. ${balance.toStringAsFixed(0)}',
                                Icons.account_balance_wallet,
                                AppColors.primaryPink,
                                theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                'total_earned'.tr,
                                'Rs. ${totalEarned.toStringAsFixed(0)}',
                                Icons.trending_up,
                                Colors.green,
                                theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                'commission_owed'.tr,
                                'Rs. ${commissionOwed.toStringAsFixed(0)}',
                                Icons.money_off,
                                Colors.orange,
                                theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                'bookings'.tr,
                                '$completedBookings',
                                Icons.check_circle,
                                Colors.blue,
                                theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Withdrawn
                        SizedBox(
                          width: double.infinity,
                          child: _summaryCard(
                            'total_withdrawn'.tr,
                            'Rs. ${totalWithdrawn.toStringAsFixed(0)}',
                            Icons.arrow_upward,
                            Colors.purple,
                            theme,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Revenue Summary
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryPink, Color(0xFFA0204A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('total_revenue'.tr, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Rs. ${totalRevenue.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('${'commission'.tr}: Rs. ${totalCommission.toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Transactions Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('recent_transactions'.tr, style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                            Text('${transactions.length} ${'total'.tr}', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Transactions List
                        if (transactions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long, size: 48, color: theme.mutedTextColor),
                                  const SizedBox(height: 8),
                                  Text('no_transactions'.tr, style: TextStyle(color: theme.mutedTextColor)),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final txn = transactions[index];
                              return _transactionTile(txn, theme);
                            },
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color, ThemeHelper theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.softShadow],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(color: theme.mutedTextColor, fontSize: 11))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _transactionTile(Map<String, dynamic> data, ThemeHelper theme) {
    final type = data['type'] as String? ?? '';
    final amount = (data['amount'] ?? 0.0).toDouble();
    final description = data['description'] as String? ?? '';
    final date = (data['createdAt'] as Timestamp?)?.toDate();
    final isCredit = type != 'commission';

    IconData icon;
    Color color;
    String prefix;

    switch (type) {
      case 'cash_payment':
        icon = Icons.money;
        color = Colors.green;
        prefix = '+';
        break;
      case 'digital_payment':
        icon = Icons.phone_android;
        color = Colors.green;
        prefix = '+';
        break;
      case 'wallet_payment':
        icon = Icons.account_balance_wallet;
        color = Colors.green;
        prefix = '+';
        break;
      case 'commission':
        icon = Icons.money_off;
        color = Colors.red;
        prefix = '-';
        break;
      case 'withdrawal':
        icon = Icons.arrow_upward;
        color = Colors.orange;
        prefix = '-';
        break;
      default:
        icon = Icons.receipt;
        color = Colors.grey;
        prefix = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [theme.softShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date) : '',
                  style: TextStyle(color: theme.mutedTextColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$prefix Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}