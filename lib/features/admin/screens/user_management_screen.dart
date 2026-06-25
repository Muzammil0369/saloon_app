import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';
import 'package:saloon_app/features/admin/widgets/admin_common_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const TabBar(
            labelColor: AdminColors.primary,
            unselectedLabelColor: AdminColors.textSecondary,
            tabs: [
              Tab(text: "Customers"),
              Tab(text: "Owners"),
              Tab(text: "Admins"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUserTable('customer'),
                _buildUserTable('owner'),
                _buildUserTable('admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTable(String role) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.border),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: role).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final users = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['name'] as String? ?? '').toLowerCase().contains(_searchQuery);
            }).toList();
            
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 0,
                    horizontalMargin: 24,
                    // Force the table to take full width
                    dataRowMinHeight: 50,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(label: SizedBox(width: constraints.maxWidth * 0.5, child: Text('Full Name', style: AppTextStyles.headingMedium,))),
                      DataColumn(label: SizedBox(width: constraints.maxWidth * 0.25, child: Text('Status', style: AppTextStyles.headingMedium,))),
                      DataColumn(label: SizedBox(width: constraints.maxWidth * 0.25, child: Text('Action', style: AppTextStyles.headingMedium,))),
                    ],
                    rows: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(Text(data['name'] ?? 'Unknown User')),
                        DataCell(AdminWidgets.statusChip(data['status'] ?? 'active')),
                        DataCell(Switch(
                          value: data['status'] != 'suspended',
                          onChanged: (value) => _toggleUserStatus(doc.id, value ? 'active' : 'suspended'),
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              }
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(String userId, String newStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'status': newStatus});
  }
}
