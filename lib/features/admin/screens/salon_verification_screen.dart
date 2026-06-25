import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';
import 'package:saloon_app/features/admin/controllers/admin_controller.dart';
import 'package:saloon_app/features/admin/widgets/admin_scaffold.dart';
import 'package:saloon_app/features/admin/widgets/admin_common_widgets.dart';

class SalonVerificationScreen extends StatelessWidget {
  const SalonVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();

    return AdminScaffold(
      title: "Salon Verification",
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('owners')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final pendingOwners = snapshot.data!.docs;
          if (pendingOwners.isEmpty) return const Center(child: Text('No pending verifications'));

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: pendingOwners.length,
            itemBuilder: (context, index) {
              final data = pendingOwners[index].data() as Map<String, dynamic>;
              return _buildVerificationCard(context, adminController, pendingOwners[index].id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildVerificationCard(BuildContext context, AdminController controller, String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: const CircleAvatar(backgroundColor: AdminColors.primary, child: Icon(Icons.store, color: Colors.white)),
        title: Text(data['salonName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['fullName'] ?? 'Unknown'),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.accent),
          child: const Text("Review"),
        ),
      ),
    );
  }
}
