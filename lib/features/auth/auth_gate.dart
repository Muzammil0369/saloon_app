import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/features/auth/screens/onboarding_screen.dart';
import 'package:saloon_app/features/auth/screens/role_select_screen.dart';
import 'package:saloon_app/features/auth/screens/login_screen.dart';
import 'package:saloon_app/features/auth/screens/email_verification_screen.dart';
import 'package:saloon_app/features/customer/registration/customer_profile_setup_screen.dart';
import 'package:saloon_app/features/owner/registration/owner_basic_info_screen.dart';
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

    // Email/password accounts must verify their email first (Google accounts skip this).
    if ((role == 'customer' || role == 'owner') && authService.needsEmailVerification) {
      debugPrint('AuthGate: Email not verified -> EmailVerificationScreen');
      return EmailVerificationScreen(
        email: authService.user.value?.email ?? (data['email'] as String? ?? ''),
        role: role!,
      );
    }

    if (role == 'customer') {
      // Registered but never finished profile setup -> resume it.
      if (data['profileSetupDone'] == false) {
        debugPrint('AuthGate: Customer profile setup unfinished -> CustomerProfileSetupScreen');
        return const CustomerProfileSetupScreen();
      }
      debugPrint('AuthGate: Redirecting to CustomerMainWrapper');
      return const CustomerMainWrapper();
    } else if (role == 'owner') {
      // ✅ Check BOTH users and owners collections
      debugPrint('AuthGate: Checking owner approval for UID: $uid');
      try {
        final ownerDoc = await FirebaseFirestore.instance.collection('owners').doc(uid).get();
        final ownerStatus = ownerDoc.data()?['status'] as String?;

        debugPrint('AuthGate: Owner doc status: "$ownerStatus", User doc status: "$userStatus"');

        // Only the owners/{uid} document decides approval, and only an admin
        // can set it to 'approved'. (users.status is 'active' for every new
        // account, so it must NOT grant access — it let owners who never
        // finished registration straight into the dashboard.)
        final isApproved =
            ownerStatus != null && ownerStatus.trim().toLowerCase() == 'approved';

        if (isApproved) {
          debugPrint('AuthGate: ✅ Owner is APPROVED - Redirecting to OwnerMainWrapper');

          // (No client-side status syncing: approval fields are admin-only
          // in firestore.rules. Admin approval already updates both docs.)

          return const OwnerMainWrapper();
        } else if (ownerDoc.data()?['isCompleted'] != true && ownerStatus != 'rejected') {
          // Created the account but never submitted the application -> resume it.
          debugPrint('AuthGate: Owner registration unfinished -> OwnerBasicInfoScreen');
          return const OwnerBasicInfoScreen();
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