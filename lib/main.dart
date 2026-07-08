import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/auth_service.dart';
import 'core/services/database_service.dart';
import 'core/controllers/user_controller.dart';
import 'features/admin/admin_main_wrapper.dart';
import 'features/admin/screens/salon_verification_screen.dart';
import 'features/admin/screens/transaction_monitoring_screen.dart';
import 'features/admin/screens/user_management_screen.dart';
import 'features/admin/screens/withdrawal_management_screen.dart';
import 'features/admin/screens/admin_login_screen.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/customer/customer_main_wrapper.dart';
import 'features/customer/registration/customer_registration_screen.dart';
import 'features/customer/registration/customer_profile_setup_screen.dart';
import 'features/owner/owner_main_wrapper.dart';
import 'features/owner/registration/owner_registration_screen.dart';
import 'features/owner/registration/owner_basic_info_screen.dart';
import 'features/owner/registration/owner_services_screen.dart';
import 'features/owner/registration/owner_documents_screen.dart';
import 'features/owner/registration/owner_review_screen.dart';
import 'features/owner/registration/owner_pending_screen.dart';
import 'features/owner/screens/owner_services_management_screen.dart';
import 'features/owner/screens/owner_gallery_management_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'shared/screens/wallet_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  Get.put(ThemeController());
  
  // Initialize Auth Service and wait for it to restore state
  final authService = Get.put(AuthService());
  await authService.initializeAuth(); 
  
  Get.put(DatabaseService());
  Get.put(UserController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() =>
        GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Glambook',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.themeMode.value,
          initialRoute: '/auth-gate',
          getPages: [
            GetPage(name: '/auth-gate', page: () => const AuthGate()),
            GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
            GetPage(name: '/role-select', page: () => const RoleSelectScreen()),
            GetPage(name: '/login', page: () => const LoginScreen()),

            // Customer Flow
            GetPage(name: '/customer-registration',
                page: () => const CustomerRegistrationScreen()),
            GetPage(name: '/customer-setup',
                page: () => const CustomerProfileSetupScreen()),
            GetPage(name: '/customer-home',
                page: () => const CustomerMainWrapper()),

            // Owner Flow
            GetPage(name: '/owner-registration',
                page: () => const OwnerRegistrationScreen()),
            GetPage(
                name: '/owner-pending', page: () => const OwnerPendingScreen()),
            GetPage(name: '/owner-home', page: () => const OwnerMainWrapper()),

            // Owner Management
            GetPage(name: '/owner-services-mgmt',
                page: () => const OwnerServicesManagementScreen()),
            GetPage(name: '/owner-gallery-mgmt',
                page: () => const OwnerGalleryManagementScreen()),

            // Admin Portal Flow
            GetPage(name: '/admin-login', page: () => const AdminLoginScreen()),
            GetPage(name: '/admin-main', page: () => const AdminMainWrapper()),
            GetPage(name: '/admin-dashboard',
                page: () => const AdminDashboardScreen()),
            GetPage(name: '/admin-verification',
                page: () => const SalonVerificationScreen()),
            GetPage(name: '/admin-withdrawals',
                page: () => const WithdrawalManagementScreen()),
            GetPage(name: '/admin-transactions',
                page: () => const TransactionMonitoringScreen()),
            GetPage(
                name: '/admin-users', page: () => const UserManagementScreen()),

            // Generic
            GetPage(name: '/wallet', page: () => const WalletScreen()),
          ],
          defaultTransition: Transition.cupertino,
        ));
  }
}