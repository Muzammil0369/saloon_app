import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/features/auth/screens/onboarding_screen.dart';
import 'package:saloon_app/features/auth/screens/role_select_screen.dart';
import 'package:saloon_app/features/auth/screens/login_screen.dart';
import 'package:saloon_app/features/customer/customer_main_wrapper.dart';
import 'package:saloon_app/features/owner/owner_main_wrapper.dart';
import 'package:saloon_app/features/owner/registration/owner_pending_screen.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/database_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
        return snapshot.data ?? const OnboardingScreen();
      },
    );
  }

  Future<Widget> _determineInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    if (!seenOnboarding) {
      return const OnboardingScreen();
    }

    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn) {
      return const LoginScreen();
    }

    // User is logged in, check role
    final dbService = Get.find<DatabaseService>();
    final uid = authService.uid;
    if (uid == null) return const LoginScreen();

    // Check users collection first for role
    final userDoc = await dbService.getUserProfile(uid);
    if (!userDoc.exists) return const RoleSelectScreen();

    final data = userDoc.data() as Map<String, dynamic>;
    final role = data['role'] as String?;

    if (role == 'customer') {
      return const CustomerMainWrapper();
    } else if (role == 'owner') {
      // Check owners collection for status
      debugPrint('AuthGate: Checking owner approval for UID: $uid');
      final ownerDoc = await FirebaseFirestore.instance.collection('owners').doc(uid).get();

      if (!ownerDoc.exists) {
        debugPrint('AuthGate: Owner document does not exist for UID: $uid');
        return const OwnerPendingScreen();
      }

      final ownerData = ownerDoc.data();
      debugPrint('AuthGate: Owner doc content: $ownerData');
      final status = ownerData?['status'] as String?;

      debugPrint('AuthGate: Owner status found: "$status"');

      if (status == 'approved') {
        return const OwnerMainWrapper();
      } else {
        return const OwnerPendingScreen();
      }
    }
    return const RoleSelectScreen();
  }
}