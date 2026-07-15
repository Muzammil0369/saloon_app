// lib/features/admin/screens/user_management_screen.dart
// Replace the entire file with this complete version

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ==================== CUSTOMER DELETE ====================

  Future<void> _deleteCustomer(String userId, String userName) async {
    final confirmCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = confirmCtrl.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text('Delete Customer', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: Text(userName[0].toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('This will delete:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('• Customer account', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Text('• Booking history', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Text('• Wallet & transactions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  const Text('Shop data & stats will NOT be affected.', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  const Text('Type DELETE to confirm:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type DELETE here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (value) {
                      setDialogState(() {}); // This properly updates the dialog
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: canDelete ? () => Navigator.pop(dialogContext, true) : null,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Delete Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canDelete ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    try {
      _showLoading('Deleting customer...');
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      try {
        final bookings = await FirebaseFirestore.instance.collection('bookings').where('customerId', isEqualTo: userId).get();
        for (var doc in bookings.docs) { await doc.reference.delete(); }
      } catch (_) {}
      try { await FirebaseFirestore.instance.collection('wallets').doc(userId).delete(); } catch (_) {}
      try {
        final transactions = await FirebaseFirestore.instance.collection('transactions').where('userId', isEqualTo: userId).get();
        for (var doc in transactions.docs) { await doc.reference.delete(); }
      } catch (_) {}
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  // ==================== SHOP SUSPEND/REACTIVATE ====================

  Future<void> _toggleShopStatus(String userId, String shopName, bool isActive) async {
    final action = isActive ? 'Suspend' : 'Reactivate';

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final reasonCtrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isActive ? Icons.block : Icons.check_circle,
                color: isActive ? Colors.orange : Colors.green,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text('$action Shop', style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, size: 20, color: isActive ? Colors.orange : Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(shopName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isActive
                    ? 'This will temporarily disable:\n- Map visibility\n- Search results\n- New bookings'
                    : 'This will restore:\n- Map visibility\n- Search results\n- Booking capability',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, reasonCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    try {
      await FirebaseFirestore.instance.collection('owners').doc(userId).update({
        'isActive': !isActive,
        'showOnMap': !isActive,
        'suspendedReason': reason.isNotEmpty ? reason : null,
        'suspendedAt': isActive ? FieldValue.serverTimestamp() : null,
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': isActive ? 'suspended' : 'active',
      });

      await FirebaseFirestore.instance.collection('moderation_logs').add({
        'userId': userId,
        'shopName': shopName,
        'action': isActive ? 'suspended' : 'reactivated',
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$shopName ${isActive ? 'suspended' : 'reactivated'}'),
            backgroundColor: isActive ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== SHOP DELETE (PERMANENT) ====================

  Future<void> _deleteShop(String userId, String shopName) async {
    final confirmCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = confirmCtrl.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text('DELETE SHOP', style: TextStyle(fontSize: 18, color: Colors.red)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 18, backgroundColor: Colors.red, child: Icon(Icons.store, color: Colors.white, size: 18)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(shopName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('⚠️ THIS IS PERMANENT AND CANNOT BE UNDONE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
                  const SizedBox(height: 12),
                  const Text('This will permanently delete:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('• Shop profile & all photos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Text('• All services & pricing', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Text('• All booking history', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Text('• Owner account & wallet', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text('Type DELETE to confirm:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type DELETE here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (value) {
                      setDialogState(() {}); // This properly updates the dialog
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: canDelete ? () => Navigator.pop(dialogContext, true) : null,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('DELETE PERMANENTLY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canDelete ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    try {
      _showLoading('Deleting shop...');
      await FirebaseFirestore.instance.collection('moderation_logs').add({
        'userId': userId, 'shopName': shopName, 'action': 'deleted',
        'timestamp': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('owners').doc(userId).delete();
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      try {
        final services = await FirebaseFirestore.instance.collection('services').where('ownerId', isEqualTo: userId).get();
        for (var doc in services.docs) { await doc.reference.delete(); }
      } catch (_) {}
      try {
        final bookings = await FirebaseFirestore.instance.collection('bookings').where('ownerId', isEqualTo: userId).get();
        for (var doc in bookings.docs) { await doc.reference.delete(); }
      } catch (_) {}
      try { await FirebaseFirestore.instance.collection('wallets').doc(userId).delete(); } catch (_) {}
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$shopName permanently deleted'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }


  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: TabBar(
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "Customers"),
                Tab(text: "Shops"),
                Tab(text: "Admins"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildCustomerTable(),
                _buildOwnerTable(),
                _buildSimpleTable('admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOMER TABLE ====================

  Widget _buildCustomerTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = _filterUsers(snapshot.data!.docs);
        if (users.isEmpty) return _emptyState('customers');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final name = data['name'] ?? data['fullName'] ?? 'Unknown';
            final email = data['email'] ?? 'N/A';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(name[0].toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ]),
                  ),
                  // DELETE BUTTON ONLY
                  InkWell(
                    onTap: () => _deleteCustomer(userId, name),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_forever, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================== OWNER/SHOP TABLE ====================

  Widget _buildOwnerTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('owners').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final owners = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['salonName'] ?? '').toString().toLowerCase();
          final ownerName = (data['fullName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || ownerName.contains(_searchQuery);
        }).toList();

        if (owners.isEmpty) return _emptyState('shops');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: owners.length,
          itemBuilder: (context, index) {
            final data = owners[index].data() as Map<String, dynamic>;
            final userId = owners[index].id;
            final shopName = data['salonName'] ?? 'Unknown Shop';
            final ownerName = data['fullName'] ?? 'Unknown Owner';
            final isActive = data['isActive'] ?? true;
            final totalBookings = data['totalBookings'] ?? 0;
            final suspendedReason = data['suspendedReason'];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? Colors.grey.shade200 : Colors.orange.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: isActive ? [Colors.blue.shade400, Colors.blue.shade600] : [Colors.orange.shade400, Colors.orange.shade600]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.store, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(shopName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                            Text('Owner: $ownerName', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isActive ? Colors.green.shade200 : Colors.orange.shade200),
                                ),
                                child: Text(isActive ? '● Active' : '● Suspended',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.green.shade700 : Colors.orange.shade700)),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('$totalBookings bookings', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ]),
                          ]),
                        ),
                      ],
                    ),
                    if (!isActive && suspendedReason != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                        child: Row(children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Reason: $suspendedReason', style: TextStyle(fontSize: 12, color: Colors.orange.shade700))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    // MODERATION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            onTap: () => _toggleShopStatus(userId, shopName, isActive),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isActive ? Colors.orange.shade50 : Colors.green.shade50,
                                border: Border.all(color: isActive ? Colors.orange.shade400 : Colors.green.shade400, width: 2),
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(isActive ? Icons.block : Icons.check_circle, size: 20, color: isActive ? Colors.orange.shade700 : Colors.green.shade700),
                                const SizedBox(width: 8),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(isActive ? 'SUSPEND SHOP' : 'REACTIVATE SHOP',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isActive ? Colors.orange.shade700 : Colors.green.shade700)),
                                  Text(isActive ? 'Temporarily disable' : 'Restore shop',
                                      style: TextStyle(fontSize: 10, color: isActive ? Colors.orange.shade500 : Colors.green.shade500)),
                                ]),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () => _deleteShop(userId, shopName),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.red.shade600,
                                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.delete_forever, size: 20, color: Colors.white),
                                SizedBox(width: 6),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('DELETE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                                  Text('Permanent', style: TextStyle(fontSize: 10, color: Colors.white70)),
                                ]),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== SIMPLE TABLE (ADMINS) ====================

  Widget _buildSimpleTable(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: role).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = _filterUsers(snapshot.data!.docs);
        if (users.isEmpty) return _emptyState(role + 's');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? data['fullName'] ?? 'Unknown';
            final email = data['email'] ?? 'N/A';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(name[0].toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();
  }

  Widget _emptyState(String type) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No $type found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ]),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}