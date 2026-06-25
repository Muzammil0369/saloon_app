import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';
import 'package:saloon_app/features/admin/controllers/admin_controller.dart';
import 'package:saloon_app/features/admin/widgets/admin_scaffold.dart';

class WithdrawalManagementScreen extends StatelessWidget {
  const WithdrawalManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();

    return AdminScaffold(
      title: "Withdrawal Management",
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('withdrawal_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) return const Center(child: Text('No pending withdrawals'));

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              return _buildWithdrawalCard(context, adminController, requests[index].id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildWithdrawalCard(BuildContext context, AdminController controller, String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: const CircleAvatar(backgroundColor: AdminColors.success, child: Icon(Icons.account_balance_wallet, color: Colors.white)),
        title: Text('PKR ${data['amount'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Owner: ${data['ownerName'] ?? 'Unknown'}'),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.accent),
          child: const Text("Process"),
        ),
      ),
    );
  }
}
