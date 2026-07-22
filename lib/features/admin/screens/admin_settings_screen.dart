// lib/features/admin/screens/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../controllers/admin_controller.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isResetting = false;
  String _statusMessage = '';

  Future<int> _countCollection(String collection) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.docs.length;
  }

  Future<Map<String, String>> _getCurrentAdminInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'unknown';
    final userEmail = user?.email ?? 'unknown';

    String userName = 'Unknown Admin';
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        userName = doc.data()?['name'] ?? doc.data()?['fullName'] ?? userEmail;
      }
    } catch (_) {}

    return {'id': userId, 'name': userName, 'email': userEmail};
  }

  void _refreshDashboardStats() {
    try {
      final controller = Get.find<AdminController>();
      controller.refreshStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard stats refreshed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing stats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetEverything() async {
    final confirmCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canReset = confirmCtrl.text.trim() == 'RESET EVERYTHING';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text('RESET DATABASE', style: TextStyle(fontSize: 18, color: Colors.red)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚠️ THIS WILL DELETE:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                        SizedBox(height: 8),
                        Text('• All customers', style: TextStyle(fontSize: 12)),
                        Text('• All shops & owners', style: TextStyle(fontSize: 12)),
                        Text('• All services', style: TextStyle(fontSize: 12)),
                        Text('• All bookings', style: TextStyle(fontSize: 12)),
                        Text('• All wallets & transactions', style: TextStyle(fontSize: 12)),
                        SizedBox(height: 8),
                        Text('✅ Admin accounts preserved', style: TextStyle(fontSize: 12, color: Colors.green)),
                        Text('⚠️ REMOVE BEFORE PUBLISHING', style: TextStyle(fontSize: 12, color: Colors.orange)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Type RESET EVERYTHING to confirm:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type RESET EVERYTHING here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                ElevatedButton.icon(
                  onPressed: canReset ? () => Navigator.pop(dialogContext, true) : null,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('RESET DATABASE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canReset ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isResetting = true;
      _statusMessage = 'Getting admin info...';
    });

    try {
      final adminInfo = await _getCurrentAdminInfo();

      setState(() => _statusMessage = 'Counting documents...');
      final usersBefore = await _countCollection('users');
      final ownersBefore = await _countCollection('owners');
      final bookingsBefore = await _countCollection('bookings');
      final transactionsBefore = await _countCollection('transactions');

      // ✅ LOG THE RESET ACTION
      final logRef = await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': 'RESET_DATABASE',
        'actionType': 'system_reset',
        'adminId': adminInfo['id'],
        'adminName': adminInfo['name'],
        'adminEmail': adminInfo['email'],
        'details': 'Full database reset performed',
        'stats': {
          'usersBefore': usersBefore,
          'ownersBefore': ownersBefore,
          'bookingsBefore': bookingsBefore,
          'transactionsBefore': transactionsBefore,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() => _statusMessage = 'Deleting customers...');
      final customers = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').get();
      for (var doc in customers.docs) {
        await _deleteUserData(doc.id, 'customer');
      }

      setState(() => _statusMessage = 'Deleting owners & shops...');
      final owners = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'owner').get();
      for (var doc in owners.docs) {
        await _deleteUserData(doc.id, 'owner');
      }

      setState(() => _statusMessage = 'Cleaning up remaining data...');
      try { final services = await FirebaseFirestore.instance.collection('services').get(); for (var doc in services.docs) { await doc.reference.delete(); } } catch (_) {}
      try { final bookings = await FirebaseFirestore.instance.collection('bookings').get(); for (var doc in bookings.docs) { await doc.reference.delete(); } } catch (_) {}
      try { final wallets = await FirebaseFirestore.instance.collection('wallets').get(); for (var doc in wallets.docs) { await doc.reference.delete(); } } catch (_) {}
      try { final transactions = await FirebaseFirestore.instance.collection('transactions').get(); for (var doc in transactions.docs) { await doc.reference.delete(); } } catch (_) {}
      try { final qrTokens = await FirebaseFirestore.instance.collection('qr_tokens').get(); for (var doc in qrTokens.docs) { await doc.reference.delete(); } } catch (_) {}
      try { final logs = await FirebaseFirestore.instance.collection('moderation_logs').get(); for (var doc in logs.docs) { await doc.reference.delete(); } } catch (_) {}
      try { final logs = await FirebaseFirestore.instance.collection('security_logs').get(); for (var doc in logs.docs) { await doc.reference.delete(); } } catch (_) {}

      // Count after
      final usersAfter = await _countCollection('users');
      final ownersAfter = await _countCollection('owners');
      final bookingsAfter = await _countCollection('bookings');
      final transactionsAfter = await _countCollection('transactions');

      // ✅ Update audit log with after stats
      await logRef.update({
        'stats.after': {
          'usersAfter': usersAfter,
          'ownersAfter': ownersAfter,
          'bookingsAfter': bookingsAfter,
          'transactionsAfter': transactionsAfter,
        }
      });

      setState(() {
        _isResetting = false;
        _statusMessage = 'Reset complete!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database reset! Users: $usersBefore→$usersAfter, Owners: $ownersBefore→$ownersAfter, Bookings: $bookingsBefore→$bookingsAfter'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() { _isResetting = false; _statusMessage = 'Error: $e'; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUserData(String userId, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    if (role == 'owner') {
      try { await FirebaseFirestore.instance.collection('owners').doc(userId).delete(); } catch (_) {}
      try { final services = await FirebaseFirestore.instance.collection('services').where('ownerId', isEqualTo: userId).get(); for (var doc in services.docs) { await doc.reference.delete(); } } catch (_) {}
    }
    try { final bookings = await FirebaseFirestore.instance.collection('bookings').where(role == 'owner' ? 'ownerId' : 'customerId', isEqualTo: userId).get(); for (var doc in bookings.docs) { await doc.reference.delete(); } } catch (_) {}
    try { await FirebaseFirestore.instance.collection('wallets').doc(userId).delete(); } catch (_) {}
    try { final transactions = await FirebaseFirestore.instance.collection('transactions').where('userId', isEqualTo: userId).get(); for (var doc in transactions.docs) { await doc.reference.delete(); } } catch (_) {}
  }

  Future<Map<String, int>> _getCounts() async {
    return {
      'customers': await _countCollection('users'),
      'owners': await _countCollection('owners'),
      'bookings': await _countCollection('bookings'),
      'transactions': await _countCollection('transactions'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      body: _isResetting
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 24), Text(_statusMessage, style: const TextStyle(fontSize: 16))]))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FutureBuilder<Map<String, int>>(
            future: _getCounts(),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? {};
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Database Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dashboard Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _refreshDashboardStats,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('Refresh Dashboard Stats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(children: [
                    _countCard('Users', '${counts['customers'] ?? 0}', Colors.blue, Icons.people),
                    const SizedBox(width: 12),
                    _countCard('Owners', '${counts['owners'] ?? 0}', Colors.orange, Icons.store),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _countCard('Bookings', '${counts['bookings'] ?? 0}', Colors.green, Icons.calendar_today),
                    const SizedBox(width: 12),
                    _countCard('Transactions', '${counts['transactions'] ?? 0}', Colors.purple, Icons.receipt),
                  ]),
                ]),
              );
            },
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade300)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.warning, color: Colors.red.shade700), const SizedBox(width: 8), const Text('⚠️ TESTING ONLY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red))]),
              const SizedBox(height: 8),
              const Text('Remove before publishing!', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetEverything,
                  icon: const Icon(Icons.restart_alt, color: Colors.white),
                  label: const Text('RESET ENTIRE DATABASE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Admin Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Logged in as: ${FirebaseAuth.instance.currentUser?.email ?? "Admin"}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text('UID: ${FirebaseAuth.instance.currentUser?.uid ?? "N/A"}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _countCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}