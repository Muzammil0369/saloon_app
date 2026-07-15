// lib/features/auth/screens/email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/features/customer/registration/customer_profile_setup_screen.dart';
import 'package:saloon_app/features/owner/registration/owner_basic_info_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';

import '../../../shared/widgets/progress_step_bar.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String role;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isVerified = false;
  bool _isResending = false;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    _startCheckingVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    final authService = Get.find<AuthService>();
    final sent = await authService.sendEmailVerification();

    if (!sent && mounted) {
      Get.snackbar(
        'already_verified'.tr,
        'email_already_verified'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _navigateToNext();
    }
  }

  void _startCheckingVerification() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isVerified = true);
        Get.snackbar(
          'email_verified'.tr,
          'email_verified_success'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _navigateToNext();
        });
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final authService = Get.find<AuthService>();
      await authService.reloadUser();
      if (authService.isEmailVerified && mounted) {
        timer.cancel();
        setState(() => _isVerified = true);
        _navigateToNext();
      }
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && mounted) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _navigateToNext() {
    if (widget.role == 'customer') {
      Get.offAll(() => const CustomerProfileSetupScreen());
    } else if (widget.role == 'owner') {
      Get.offAll(() => const OwnerBasicInfoScreen());
    }
  }

  Future<void> _resendEmail() async {
    if (_secondsRemaining > 0) return;

    setState(() {
      _isResending = true;
      _secondsRemaining = 60;
    });

    final authService = Get.find<AuthService>();
    final sent = await authService.sendEmailVerification();

    setState(() => _isResending = false);

    if (sent) {
      Get.snackbar(
        'email_sent'.tr,
        'verification_email_resent'.tr + ' ${widget.email}',
        backgroundColor: AppColors.primaryPink,
        colorText: Colors.white,
      );
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
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProgressStepBar(totalSteps: widget.role == 'owner' ? 7 : 2, currentStep: 2),
                // Animated Email Icon
                _isVerified
                    ? const Icon(Icons.check_circle, size: 100, color: Colors.green)
                    : Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.email_outlined, size: 100, color: AppColors.primaryPink),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  _isVerified ? 'email_verified'.tr : 'verify_email'.tr,
                  style: AppTextStyles.displayMedium?.copyWith(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'verification_sent'.tr,
                  style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lightPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.email,
                    style: AppTextStyles.bodyLarge?.copyWith(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Column(
                    children: [
                      _instructionStep('1', 'instruction_1'.tr),
                      const SizedBox(height: 12),
                      _instructionStep('2', 'instruction_2'.tr),
                      const SizedBox(height: 12),
                      _instructionStep('3', 'instruction_3'.tr),
                      const SizedBox(height: 12),
                      _instructionStep('4', 'instruction_4'.tr),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Auto-checking indicator
                if (!_isVerified)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'waiting_verification'.tr,
                        style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Resend button
                if (!_isVerified)
                  Column(
                    children: [
                      _isResending
                          ? const CircularProgressIndicator(color: AppColors.primaryPink)
                          : AppButton(
                        label: _secondsRemaining > 0
                            ? 'resend_in'.tr + ' ${_secondsRemaining}s'
                            : 'resend_email'.tr,
                        onTap: _secondsRemaining > 0 ? () {} : _resendEmail,
                        isOutline: _secondsRemaining > 0,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Get.find<AuthService>().logout(),
                        child: Text('use_different_email'.tr),
                      ),
                    ],
                  ),

                // Continue button (shown when verified)
                if (_isVerified)
                  AppButton(
                    label: 'continue'.tr,
                    onTap: _navigateToNext,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _instructionStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.lightPink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}