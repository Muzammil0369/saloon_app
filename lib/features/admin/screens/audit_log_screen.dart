// lib/features/admin/screens/audit_log_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';
import 'package:saloon_app/features/admin/widgets/admin_scaffold.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      setState(() {
        _logs = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _logs = [];
      });
    }
  }

  // Get action icon and color
  Map<String, dynamic> _getActionInfo(String action) {
    switch (action) {
      case 'APPROVE_SALON':
        return {'icon': Icons.check_circle, 'color': Colors.green, 'label': 'Approved Salon'};
      case 'REJECT_SALON':
        return {'icon': Icons.cancel, 'color': Colors.red, 'label': 'Rejected Salon'};
      case 'APPROVE_WITHDRAWAL':
        return {'icon': Icons.money, 'color': Colors.green, 'label': 'Approved Withdrawal'};
      case 'REJECT_WITHDRAWAL':
        return {'icon': Icons.money_off, 'color': Colors.red, 'label': 'Rejected Withdrawal'};
      case 'RESET_DATABASE':
        return {'icon': Icons.restart_alt, 'color': Colors.orange, 'label': 'Database Reset'};
      case 'suspended':
        return {'icon': Icons.block, 'color': Colors.orange, 'label': 'Suspended Shop'};
      case 'reactivated':
        return {'icon': Icons.check_circle, 'color': Colors.green, 'label': 'Reactivated Shop'};
      case 'deleted':
        return {'icon': Icons.delete_forever, 'color': Colors.red, 'label': 'Deleted Shop'};
      default:
        return {'icon': Icons.history, 'color': Colors.grey, 'label': action};
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Audit Logs",
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchLogs,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        )
            : _logs.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No audit logs yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
              SizedBox(height: 4),
              Text('Admin actions will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            return _buildLogCard(_logs[index]);
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> data) {
    final action = data['action'] ?? 'UNKNOWN';
    final actionInfo = _getActionInfo(action);
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final adminName = data['adminName'] ?? data['actorName'] ?? 'Unknown Admin';
    final adminEmail = data['adminEmail'] ?? '';
    final adminId = data['adminId'] ?? '';
    final targetId = data['targetId'] ?? '';
    final details = data['details'] ?? '';
    final stats = data['stats'] as Map<String, dynamic>?;
    final reason = data['reason'] ?? '';
    final shopName = data['shopName'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: actionInfo['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(actionInfo['icon'], color: actionInfo['color'], size: 22),
        ),
        title: Text(
          actionInfo['label'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: actionInfo['color'],
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          timestamp != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
              : 'Unknown time',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // Admin Info (Who did it)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👤 ACTION BY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                _infoRow('Name', adminName),
                if (adminEmail.isNotEmpty) _infoRow('Email', adminEmail),
                _infoRow('Admin ID', adminId),
              ],
            ),
          ),

          // Target Info (Who/what was affected)
          if (shopName.isNotEmpty || targetId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯 TARGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 8),
                  if (shopName.isNotEmpty) _infoRow('Shop', shopName),
                  if (targetId.isNotEmpty) _infoRow('Target ID', targetId),
                ],
              ),
            ),
          ],

          // Reason
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 REASON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Text(reason, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],

          // Stats (for reset actions)
          if (stats != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 STATISTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 8),
                  if (stats['usersBefore'] != null)
                    _infoRow('Users', '${stats['usersBefore']} → ${stats['after']?['usersAfter'] ?? 'N/A'}'),
                  if (stats['ownersBefore'] != null)
                    _infoRow('Owners', '${stats['ownersBefore']} → ${stats['after']?['ownersAfter'] ?? 'N/A'}'),
                  if (stats['bookingsBefore'] != null)
                    _infoRow('Bookings', '${stats['bookingsBefore']} → ${stats['after']?['bookingsAfter'] ?? 'N/A'}'),
                  if (stats['transactionsBefore'] != null)
                    _infoRow('Transactions', '${stats['transactionsBefore']} → ${stats['after']?['transactionsAfter'] ?? 'N/A'}'),
                ],
              ),
            ),
          ],

          // Timestamp
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  timestamp != null
                      ? DateFormat('dd MMMM yyyy, hh:mm:ss a').format(timestamp)
                      : 'Unknown',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}