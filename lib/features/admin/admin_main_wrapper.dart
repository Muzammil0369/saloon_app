import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/features/admin/screens/admin_settings_screen.dart';
import 'package:saloon_app/features/admin/widgets/admin_top_bar.dart';
import 'package:saloon_app/features/admin/screens/audit_log_screen.dart';
import 'controllers/admin_controller.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/salon_verification_screen.dart';
import 'screens/transaction_monitoring_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/withdrawal_management_screen.dart';
import 'theme/admin_colors.dart';

class AdminMainWrapper extends StatefulWidget {
  const AdminMainWrapper({super.key});

  @override
  State<AdminMainWrapper> createState() => _AdminMainWrapperState();
}

class _AdminMainWrapperState extends State<AdminMainWrapper> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _adminName = 'Super Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final name = data['name'] ?? data['fullName'] ?? user.email ?? 'Super Admin';
        if (mounted) {
          setState(() => _adminName = name);
        }
      }
    } catch (_) {}
  }

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const SalonVerificationScreen(),
    const WithdrawalManagementScreen(),
    const TransactionMonitoringScreen(),
    const UserManagementScreen(),
    const AuditLogScreen(),
    const AdminSettingsScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.verified_user_rounded, 'label': 'Verification'},
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Withdrawals'},
    {'icon': Icons.analytics_rounded, 'label': 'Transactions'},
    {'icon': Icons.people_alt_rounded, 'label': 'Users'},
    {'icon': Icons.history_rounded, 'label': 'Audit Logs'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent()),
      body: Row(
        children: [
          if (isDesktop) Container(width: 280, child: _buildSidebarContent()),
          Expanded(
            child: Column(
              children: [
                // In AdminMainWrapper, update the AdminTopBar:
                AdminTopBar(
                  adminName: _adminName,
                  adminRole: "Administrator", // Or fetch from Firestore too
                  onMenuPressed: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                  onLogout: () => Get.offAllNamed('/admin-login'),
                ),
                Expanded(
                  child: Container(
                    color: AdminColors.background,
                    child: _screens[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(right: BorderSide(color: AdminColors.border)),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: double.infinity,
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AdminColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Text("GLAMBOOK", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.primary, letterSpacing: 1.0)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _navItems.length,
              itemBuilder: (context, index) => _buildNavItem(index),
            ),
          ),

          // Logout Button (Bottom)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AdminColors.border)),
            ),
            child: InkWell(
              onTap: () => Get.offAllNamed('/admin-login'),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: AdminColors.danger, size: 20),
                  SizedBox(width: 12),
                  Text("Logout", style: TextStyle(color: AdminColors.danger, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (MediaQuery.of(context).size.width <= 1024) {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AdminColors.primary.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(_navItems[index]['icon'], color: isSelected ? AdminColors.primary : AdminColors.textSecondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _navItems[index]['label'],
                  style: TextStyle(
                    color: isSelected ? AdminColors.primary : AdminColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(color: AdminColors.primary, borderRadius: BorderRadius.circular(2)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}