import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

import '../../auth/screens/email_verification_screen.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerRegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;

  // Password strength checks
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _passwordsMatch => _passwordController.text == _confirmPasswordController.text;

  bool get _isPasswordStrong => _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber && _hasSpecialChar;

  bool get _canRegister =>
      _emailController.text.trim().isNotEmpty &&
          _isPasswordStrong &&
          _passwordsMatch &&
          _agreedToTerms;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    final email = _emailController.text.trim();

    // Validate email
    if (!AuthService.isValidEmail(email)) {
      Get.snackbar('invalid_email'.tr, 'please_enter_valid_email'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Validate password
    if (!_isPasswordStrong) {
      Get.snackbar('weak_password'.tr, 'password_requirements_message'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Check passwords match
    if (!_passwordsMatch) {
      Get.snackbar('password_mismatch'.tr, 'passwords_do_not_match'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Check terms
    if (!_agreedToTerms) {
      Get.snackbar('terms_required'.tr, 'please_agree_to_terms'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoading = true);

    final authService = Get.find<AuthService>();
    final result = await authService.signUpWithEmail(
      email: email,
      password: _passwordController.text,
      name: 'Customer',
      role: 'customer',
    );

    setState(() => _isLoading = false);

    if (result.success) {
      await Get.find<AuthService>().sendEmailVerification();
      Get.to(() => EmailVerificationScreen(
        email: email,
        role: 'customer',
      ));
    } else {
      Get.snackbar('registration_failed'.tr, result.error ?? 'please_try_again'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('sign_up'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressStepBar(totalSteps: 2, currentStep: 1),
              const SizedBox(height: 30),

              Text('create_account'.tr + ' ✨',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 26, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('sign_up_customer_desc'.tr,
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),

              const SizedBox(height: 32),

              // Email Input
              _buildLabel('email'.tr),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'email_placeholder'.tr,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              // Password Input
              _buildLabel('password'.tr),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: 'enter_password'.tr,
                obscureText: !_isPasswordVisible,
                prefixIcon: Icons.lock_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: theme.mutedTextColor,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                onChanged: (value) => setState(() {}),
              ),

              // Password Requirements
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('password_must_contain'.tr,
                        style: TextStyle(fontSize: 12, color: theme.mutedTextColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildPasswordRule('password_min_8_chars'.tr, _hasMinLength),
                    _buildPasswordRule('password_uppercase'.tr, _hasUppercase),
                    _buildPasswordRule('password_lowercase'.tr, _hasLowercase),
                    _buildPasswordRule('password_number'.tr, _hasNumber),
                    _buildPasswordRule('password_special_char'.tr, _hasSpecialChar),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Password
              _buildLabel('Confirm Password'.tr),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Re-Enter Password'.tr,
                obscureText: !_isConfirmPasswordVisible,
                prefixIcon: Icons.lock_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: theme.mutedTextColor,
                  ),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
                onChanged: (value) => setState(() {}),
              ),

              // Password match indicator
              if (_confirmPasswordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _passwordsMatch ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: _passwordsMatch ? AppColors.success : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _passwordsMatch ? 'passwords_match'.tr : 'passwords_do_not_match'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: _passwordsMatch ? AppColors.success : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Terms & Conditions
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                      activeColor: AppColors.primaryPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'i_agree_to'.tr, style: TextStyle(fontSize: 13, color: theme.mutedTextColor)),
                            TextSpan(text: 'terms_conditions'.tr, style: TextStyle(fontSize: 13, color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                            TextSpan(text: ' and '.tr, style: TextStyle(fontSize: 13, color: theme.mutedTextColor)),
                            TextSpan(text: 'privacy_policy'.tr, style: TextStyle(fontSize: 13, color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Register Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
                  : AppButton(
                label: 'continue'.tr,
                onTap: _canRegister ? _register : () {},
                isOutline: !_canRegister,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.headingSmall?.copyWith(color: ThemeHelper(context).textColor));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    final theme = ThemeHelper(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: theme.textColor),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: theme.mutedTextColor),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: theme.mutedTextColor, size: 20) : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordRule(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isValid ? AppColors.success : Colors.grey.shade400,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isValid ? AppColors.success : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}