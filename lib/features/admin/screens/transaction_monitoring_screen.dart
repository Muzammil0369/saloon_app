import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        child: Container(
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('transactions').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final transactions = snapshot.data!.docs;
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Booking ID')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Date')),
                  ],
                  rows: transactions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DataRow(cells: [
                      DataCell(Text(data['bookingId'] ?? 'N/A')),
                      DataCell(Text(data['type'] ?? 'N/A')),
                      DataCell(Text('Rs. ${data['amount']}')),
                      DataCell(AdminWidgets.statusChip(data['status'] ?? 'unknown')),
                      DataCell(Text((data['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'N/A')),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
