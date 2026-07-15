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
    debugPrint('AuthGate: Building AuthGate widget');
    return FutureBuilder<Widget>(
      future: _determineInitialScreen(),
      builder: (context, snapshot) {
        debugPrint('AuthGate: FutureBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data ?? const OnboardingScreen();
      },
    );
  }

  Future<Widget> _determineInitialScreen() async {
    debugPrint('AuthGate: Starting determination...');
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    debugPrint('AuthGate: Seen onboarding: $seenOnboarding');

    if (!seenOnboarding) {
      debugPrint('AuthGate: Redirecting to OnboardingScreen');
      return const OnboardingScreen();
    }

    final authService = Get.find<AuthService>();
    debugPrint('AuthGate: Is logged in: ${authService.isLoggedIn}');
    if (!authService.isLoggedIn) {
      debugPrint('AuthGate: Redirecting to LoginScreen');
      return const LoginScreen();
    }

    final dbService = Get.find<DatabaseService>();
    final uid = authService.uid;
    debugPrint('AuthGate: UID: $uid');
    if (uid == null) {
      debugPrint('AuthGate: UID is null, redirecting to LoginScreen');
      return const LoginScreen();
    }

    // Check users collection first for role
    debugPrint('AuthGate: Fetching user profile for UID: $uid');
    final userDoc = await dbService.getUserProfile(uid);
    if (!userDoc.exists) {
      debugPrint('AuthGate: User profile does not exist, redirecting to RoleSelectScreen');
      return const RoleSelectScreen();
    }

    final data = userDoc.data() as Map<String, dynamic>;
    final role = data['role'] as String?;
    final userStatus = data['status'] as String?;
    debugPrint('AuthGate: User role: $role, User status: $userStatus');

    if (role == 'customer') {
      debugPrint('AuthGate: Redirecting to CustomerMainWrapper');
      return const CustomerMainWrapper();
    } else if (role == 'owner') {
      // ✅ Check BOTH users and owners collections
      debugPrint('AuthGate: Checking owner approval for UID: $uid');
      try {
        final ownerDoc = await FirebaseFirestore.instance.collection('owners').doc(uid).get();
        final ownerStatus = ownerDoc.data()?['status'] as String?;

        debugPrint('AuthGate: Owner doc status: "$ownerStatus", User doc status: "$userStatus"');

        // ✅ Check either collection for approved/active status
        final isApproved = (ownerStatus != null && ownerStatus.trim().toLowerCase() == 'approved') ||
            (userStatus != null && userStatus.trim().toLowerCase() == 'active');

        if (isApproved) {
          debugPrint('AuthGate: ✅ Owner is APPROVED - Redirecting to OwnerMainWrapper');

          // Sync status if mismatched
          if (ownerStatus != 'approved' && userStatus == 'active') {
            await FirebaseFirestore.instance.collection('owners').doc(uid).update({
              'status': 'approved',
              'isActive': true,
              'showOnMap': true,
            });
          }
          if (userStatus != 'active' && ownerStatus == 'approved') {
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'status': 'active',
            });
          }

          return const OwnerMainWrapper();
        } else if (ownerStatus == 'rejected' || userStatus == 'rejected') {
          debugPrint('AuthGate: ❌ Owner was REJECTED');
          return const OwnerPendingScreen();
        } else {
          debugPrint('AuthGate: ⏳ Owner still PENDING');
          return const OwnerPendingScreen();
        }
      } catch (e) {
        debugPrint('AuthGate: Error fetching owner doc: $e');
        return const LoginScreen();
      }
    }

    debugPrint('AuthGate: Role unknown, redirecting to RoleSelectScreen');
    return const RoleSelectScreen();
  }
}