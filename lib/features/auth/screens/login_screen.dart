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
    final dbService = Get.find<DatabaseService>();

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

    final userId = authService.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userDoc = await dbService.getUserProfile(userId);

    if (!userDoc.exists) {
      Get.snackbar('error'.tr, 'account_not_found'.tr);
      setState(() => _isLoading = false);
      return;
    }

    final data = userDoc.data() as Map<String, dynamic>;
    final role = data['role'] as String?;

    if (role == 'customer') {
      Get.offAll(() => const CustomerMainWrapper());
    } else if (role == 'owner') {
      final ownerDoc = await FirebaseFirestore.instance.collection('owners').doc(userId).get();
      final ownerStatus = ownerDoc.data()?['status'] as String?;

      if (ownerStatus == 'approved') {
        Get.offAll(() => const OwnerMainWrapper());
      } else {
        Get.offAll(() => const OwnerPendingScreen());
      }
    } else {
      Get.snackbar('access_denied'.tr, 'invalid_user_role'.tr);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome_back'.tr + ' 👋',
                  style: AppTextStyles.headingLarge.copyWith(
                    fontSize: 32,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'sign_in_to_continue'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(color: theme.mutedTextColor),
                ),
                const SizedBox(height: 48),

                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'email'.tr,
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'password'.tr,
                    filled: true,
                    fillColor: theme.cardColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: theme.mutedTextColor,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
                    : AppButton(
                  label: 'sign_in'.tr,
                  onTap: _handleLogin,
                ),

                const SizedBox(height: 48),

                // Registration link
                Center(
                  child: Column(
                    children: [
                      Text(
                        'no_account'.tr,
                        style: AppTextStyles.bodySmall.copyWith(color: theme.mutedTextColor),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Get.toNamed('/role-select'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.lightPink,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'create_account'.tr + ' 🚀',
                            style: AppTextStyles.linkText.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}