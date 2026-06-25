import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saloon_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:saloon_app/features/admin/screens/salon_verification_screen.dart';
import 'package:saloon_app/features/admin/screens/withdrawal_management_screen.dart';
import 'package:saloon_app/features/admin/screens/transaction_monitoring_screen.dart';
import 'package:saloon_app/features/admin/screens/user_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyD5boyAKlClcBuLrCir0BWD_prHoI2q8N8',
      authDomain: 'saloon-app-d8686.firebaseapp.com',
      projectId: 'saloon-app-d8686',
      storageBucket: 'saloon-app-d8686.firebasestorage.app',
      messagingSenderId: '324975557388',
      appId: '1:324975557388:web:568eda2683964f86a42729',
      measurementId: 'G-S9F35JN4HF',
    ),
  );
  runApp(const AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saloon Admin Dashboard',
      theme: ThemeData(primarySwatch: Colors.pink),
      initialRoute: '/admin-dashboard',
      getPages: [
        GetPage(name: '/admin-dashboard', page: () => const AdminDashboardScreen()),
        GetPage(name: '/admin-verification', page: () => const SalonVerificationScreen()),
        GetPage(name: '/admin-withdrawals', page: () => const WithdrawalManagementScreen()),
        GetPage(name: '/admin-transactions', page: () => const TransactionMonitoringScreen()),
        GetPage(name: '/admin-users', page: () => const UserManagementScreen()),
      ],
    );
  }
}
