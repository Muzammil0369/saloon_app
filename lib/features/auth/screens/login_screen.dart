import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/features/owner/owner_main_wrapper.dart';
import 'package:saloon_app/features/owner/registration/owner_pending_screen.dart';
import 'package:saloon_app/features/customer/customer_main_wrapper.dart';
import 'package:saloon_app/features/auth/auth_gate.dart';
import 'package:saloon_app/features/customer/registration/customer_profile_setup_screen.dart';
import 'package:saloon_app/features/owner/registration/owner_basic_info_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_email_password'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Get.find<AuthService>();
    final result = await authService.signInWithEmail(email: email, password: password);

    if (!result.success) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'login_failed'.tr,
        result.error ?? 'please_try_again'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // AuthGate decides: email verification, unfinished registration, role, approval.
    Get.offAll(() => const AuthGate());
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authService = Get.find<AuthService>();
    final result = await authService.signInWithGoogle();

    if (result.cancelled) {
      setState(() => _isLoading = false);
      return;
    }
    if (!result.success) {
      setState(() => _isLoading = false);
      Get.snackbar('error'.tr, result.error ?? 'google_sign_in_failed'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (!result.isNewUser) {
      // Existing Salonify account: AuthGate routes by role / owner approval.
      Get.offAll(() => const AuthGate());
      return;
    }

    // First time with Google: ask what kind of account to create.
    setState(() => _isLoading = false);
    final role = await _askRole();
    if (role == null) {
      await authService.logout(); // backed out: leave no half-created account
      return;
    }

    setState(() => _isLoading = true);
    final ok = await authService.completeGoogleSignup(role);
    if (!ok) {
      setState(() => _isLoading = false);
      await authService.logout();
      Get.snackbar('error'.tr, 'google_sign_in_failed'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (role == 'customer') {
      Get.offAll(() => const CustomerProfileSetupScreen());
    } else {
      Get.offAll(() => const OwnerBasicInfoScreen());
    }
  }

  Future<String?> _askRole() {
    final theme = ThemeHelper(context);
    Widget option(String role, IconData icon, String title, String subtitle) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(role),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(icon, color: AppColors.primaryPink, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: theme.textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: theme.mutedTextColor)),
              ]),
            ),
          ]),
        ),
      );
    }

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('google_choose_account_type'.tr,
                style: AppTextStyles.headingMedium.copyWith(color: theme.textColor)),
            const SizedBox(height: 16),
            option('customer', Icons.person_rounded, 'customer'.tr, 'customer_desc'.tr),
            const SizedBox(height: 12),
            option('owner', Icons.storefront_rounded, 'salon_owner'.tr, 'owner_desc'.tr),
          ]),
        ),
      ),
    );
  }

  // ───────────────────────── UI ─────────────────────────

  InputDecoration _fieldDecoration(ThemeHelper theme, String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.mutedTextColor),
      prefixIcon: Icon(icon, color: theme.mutedTextColor, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(theme.borderColor),
      enabledBorder: border(theme.borderColor),
      focusedBorder: border(AppColors.primaryPink, 1.5),
    );
  }

  Widget _header() {
    return Container(
      height: 270,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryPink, AppColors.darkPink],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/app_icon.png',
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.content_cut_rounded, color: AppColors.primaryPink, size: 36),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Salonify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'sign_in_to_continue'.tr,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primaryPink, AppColors.darkPink]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
                  : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleButton(ThemeHelper theme) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          backgroundColor: theme.cardColor,
          side: BorderSide(color: theme.borderColor, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/google.png',
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => const Text('G',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
            ),
            const SizedBox(width: 12),
            Text(
              'continue_with_google'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                _header(),
                Padding(
                  padding: const EdgeInsets.only(top: 215),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: theme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'welcome_back'.tr} 👋',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 22),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: theme.textColor),
                          decoration: _fieldDecoration(theme, 'email'.tr, Icons.mail_outline_rounded),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: TextStyle(color: theme.textColor),
                          decoration: _fieldDecoration(
                            theme,
                            'password'.tr,
                            Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.mutedTextColor,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _primaryButton('sign_in'.tr, _isLoading ? null : _handleLogin),

                        const SizedBox(height: 22),
                        Row(children: [
                          Expanded(child: Divider(color: theme.borderColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('or'.tr,
                                style: TextStyle(color: theme.mutedTextColor, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: theme.borderColor)),
                        ]),
                        const SizedBox(height: 22),

                        _googleButton(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Registration link
            Text(
              'no_account'.tr,
              style: TextStyle(color: theme.mutedTextColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Get.toNamed('/role-select'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: theme.lightPinkColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${'create_account'.tr} 🚀',
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}