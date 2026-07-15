// lib/features/admin/screens/withdrawal_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';
import 'package:saloon_app/features/admin/controllers/admin_controller.dart';
import 'package:saloon_app/features/admin/widgets/admin_scaffold.dart';

class WithdrawalManagementScreen extends StatefulWidget {
  const WithdrawalManagementScreen({super.key});

  @override
  State<WithdrawalManagementScreen> createState() => _WithdrawalManagementScreenState();
}

class _WithdrawalManagementScreenState extends State<WithdrawalManagementScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('withdrawal_requests')
          .get();

      final allDocs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort: pending first
      allDocs.sort((a, b) {
        if (a['status'] == 'pending' && b['status'] != 'pending') return -1;
        if (a['status'] != 'pending' && b['status'] == 'pending') return 1;
        return 0;
      });

      setState(() {
        _requests = allDocs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _requests = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();

    return AdminScaffold(
      title: "Withdrawal Management",
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No withdrawal data available', style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchRequests, child: const Text('Retry')),
          ],
        ),
      )
          : _requests.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No withdrawal requests', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final data = _requests[index];
          final docId = data['id'] as String;
          return _buildWithdrawalCard(context, adminController, docId, data);
        },
      ),
    );
  }

  Widget _buildWithdrawalCard(BuildContext context, AdminController controller, String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final amount = data['amount'] ?? 0;
    final ownerName = data['ownerName'] ?? 'Unknown Owner';
    final paymentMethod = data['paymentMethod'] ?? 'N/A';
    final accountDetails = data['accountDetails'] ?? '';
    final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'Pending';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(Icons.account_balance_wallet, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PKR $amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(ownerName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Method: $paymentMethod', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (accountDetails.isNotEmpty)
              Text('Account: $accountDetails', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (timestamp != null)
              Text('Requested: ${timestamp.day}/${timestamp.month}/${timestamp.year}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.processWithdrawal(docId, true),
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.processWithdrawal(docId, false),
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}