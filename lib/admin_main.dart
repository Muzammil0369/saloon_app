import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saloon_app/features/admin/screens/admin_login_screen.dart';
import 'package:saloon_app/features/admin/admin_main_wrapper.dart';
import 'package:saloon_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:saloon_app/features/admin/screens/salon_verification_screen.dart';
import 'package:saloon_app/features/admin/screens/withdrawal_management_screen.dart';
import 'package:saloon_app/features/admin/screens/transaction_monitoring_screen.dart';
import 'package:saloon_app/features/admin/screens/user_management_screen.dart';
import 'package:saloon_app/features/admin/screens/audit_log_screen.dart';
import 'package:saloon_app/features/admin/screens/admin_settings_screen.dart';
import 'package:saloon_app/features/admin/controllers/admin_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Initialize AdminController globally
    Get.put(AdminController(), permanent: true);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saloon Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      initialRoute: '/admin-login',
      getPages: [
        GetPage(name: '/admin-login', page: () => const AdminLoginScreen()),
        GetPage(name: '/admin-main', page: () => const AdminMainWrapper()),
        GetPage(name: '/admin-dashboard', page: () => const AdminDashboardScreen()),
        GetPage(name: '/admin-verification', page: () => const SalonVerificationScreen()),
        GetPage(name: '/admin-withdrawals', page: () => const WithdrawalManagementScreen()),
        GetPage(name: '/admin-transactions', page: () => const TransactionMonitoringScreen()),
        GetPage(name: '/admin-users', page: () => const UserManagementScreen()),
        GetPage(name: '/admin-audit', page: () => const AuditLogScreen()),
        GetPage(name: '/admin-settings', page: () => const AdminSettingsScreen()),
      ],
    );
  }
}