import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';
import 'package:saloon_app/features/admin/widgets/admin_scaffold.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Audit Logs",
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('audit_logs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final logs = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Action')),
                    DataColumn(label: Text('Actor')),
                    DataColumn(label: Text('Target ID')),
                    DataColumn(label: Text('Timestamp')),
                  ],
                  rows: logs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    return DataRow(cells: [
                      DataCell(Text(data['action'] ?? 'N/A')),
                      DataCell(Text(data['actorName'] ?? data['adminId'] ?? 'N/A')),
                      DataCell(Text(data['targetId'] ?? 'N/A')),
                      DataCell(Text(timestamp != null ? timestamp.toString() : 'N/A')),
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
