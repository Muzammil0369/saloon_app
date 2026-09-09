import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';
import 'package:saloon_app/features/admin/widgets/admin_scaffold.dart';
import 'package:saloon_app/features/admin/widgets/admin_common_widgets.dart';

class TransactionMonitoringScreen extends StatelessWidget {
  const TransactionMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Transaction Monitoring",
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final transactions = snapshot.data!.docs;

            if (transactions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No transactions found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Transactions will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final data = transactions[index].data() as Map<String, dynamic>;
                final bookingId = data['bookingId'] ?? 'N/A';
                final type = data['type'] ?? 'N/A';
                final amount = data['amount'] ?? 0;
                final status = data['status'] ?? 'unknown';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final dateStr = createdAt != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
                    : 'N/A';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getTypeColor(type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getTypeIcon(type),
                          color: _getTypeColor(type),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Rs. $amount',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AdminWidgets.statusChip(status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Booking: $bookingId',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              'Type: $type',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Icons.payment;
      case 'commission':
        return Icons.percent;
      case 'withdrawal':
        return Icons.account_balance_wallet;
      case 'refund':
        return Icons.money_off;
      default:
        return Icons.receipt;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Colors.green;
      case 'commission':
        return Colors.blue;
      case 'withdrawal':
        return Colors.orange;
      case 'refund':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}