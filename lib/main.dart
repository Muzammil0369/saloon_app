import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/auth_service.dart';
import 'core/services/database_service.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/customer/customer_main_wrapper.dart';
import 'features/customer/registration/customer_phone_screen.dart';
import 'features/customer/registration/customer_otp_screen.dart';
import 'features/customer/registration/customer_profile_setup_screen.dart';
import 'features/owner/owner_main_wrapper.dart';
import 'features/owner/registration/owner_phone_screen.dart';
import 'features/owner/registration/owner_otp_screen.dart';
import 'features/owner/registration/owner_basic_info_screen.dart';
import 'features/owner/registration/owner_services_screen.dart';
import 'features/owner/registration/owner_documents_screen.dart';
import 'features/owner/registration/owner_review_screen.dart';
import 'features/owner/screens/owner_services_management_screen.dart';
import 'features/owner/screens/owner_gallery_management_screen.dart';
import 'shared/screens/wallet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: This requires google-services.json on Android 
  // and GoogleService-Info.plist on iOS.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  // Initialize Services
  Get.put(ThemeController());
  Get.put(AuthService());
  Get.put(DatabaseService());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glambook',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.themeMode.value,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const OnboardingScreen()),
        GetPage(name: '/role-select', page: () => const RoleSelectScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        
        // Customer Flow
        GetPage(name: '/customer-phone', page: () => const CustomerPhoneScreen()),
        GetPage(name: '/customer-otp', page: () => const CustomerOTPScreen()),
        GetPage(name: '/customer-setup', page: () => const CustomerProfileSetupScreen()),
        GetPage(name: '/customer-home', page: () => const CustomerMainWrapper()),
        
        // Owner Flow
        GetPage(name: '/owner-phone', page: () => const OwnerPhoneScreen()),
        GetPage(name: '/owner-otp', page: () => const OwnerOTPScreen()),
        GetPage(name: '/owner-basic-info', page: () => const OwnerBasicInfoScreen()),
        GetPage(name: '/owner-services', page: () => const OwnerServicesScreen()),
        GetPage(name: '/owner-docs', page: () => const OwnerDocumentsScreen()),
        GetPage(name: '/owner-review', page: () => const OwnerReviewScreen()),
        GetPage(name: '/owner-home', page: () => const OwnerMainWrapper()),
        
        // Owner Management
        GetPage(name: '/owner-services-mgmt', page: () => const OwnerServicesManagementScreen()),
        GetPage(name: '/owner-gallery-mgmt', page: () => const OwnerGalleryManagementScreen()),

        // Generic
        GetPage(name: '/wallet', page: () => const WalletScreen()),
      ],
      defaultTransition: Transition.cupertino,
    ));
  }
}
