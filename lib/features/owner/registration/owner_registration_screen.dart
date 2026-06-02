import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/features/owner/registration/owner_basic_info_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerRegistrationScreen extends StatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  State<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  bool get _hasMinLength => _passwordController.text.length >= 6;
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _isPasswordValid => _hasMinLength && _hasNumber;

  @override
  void initState() {
    super.initState();
  }

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !_isPasswordValid) {
      Get.snackbar('Invalid Input', 'Please enter a valid email and strong password', 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);
    
    final authService = Get.find<AuthService>();
    final userCredential = await authService.signUpWithEmail(email, password);
    
    setState(() => _isLoading = false);
    
    if (userCredential != null) {
      Get.to(() => const OwnerBasicInfoScreen());
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
        title: Text('Owner Sign Up', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
              const ProgressStepBar(totalSteps: 6, currentStep: 1),
              const SizedBox(height: 30),

              Text('Register Salon 🏪',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 26, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('Create an account to manage your business',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 40),

              // Email Input
              Text('Email Address', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              // Password Input
              Text('Password', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                onChanged: (value) => setState(() {}),
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  filled: true,
                  fillColor: theme.cardColor,
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: theme.mutedTextColor),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              
              const SizedBox(height: 16),
              _buildValidationRule('At least 6 characters', _hasMinLength, theme),
              _buildValidationRule('At least one number', _hasNumber, theme),
              
              const SizedBox(height: 40),

              _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
              : AppButton(
                label: 'Register & Continue',
                onTap: _isPasswordValid ? _register : () {},
                isOutline: !_isPasswordValid,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildValidationRule(String text, bool isValid, ThemeHelper theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle_rounded : Icons.circle_outlined, 
               color: isValid ? AppColors.success : theme.mutedTextColor, size: 16),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.bodySmall?.copyWith(color: isValid ? AppColors.success : theme.mutedTextColor)),
        ],
      ),
    );
  }
}
