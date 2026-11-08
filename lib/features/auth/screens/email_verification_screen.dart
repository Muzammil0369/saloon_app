// lib/features/auth/screens/email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/features/auth/auth_gate.dart';
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
  static const int _cooldownSeconds = 60;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  bool _isVerified = false;
  bool _isResending = false;
  bool _isChecking = false;
  int _secondsRemaining = _cooldownSeconds;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail(showSuccess: false);
    _startCooldown();
    // Poll Firebase every 3 seconds: the moment the user taps the link in the
    // email, this screen notices and moves on.
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerified(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsRemaining = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  Future<bool> _sendVerificationEmail({required bool showSuccess}) async {
    final authService = Get.find<AuthService>();
    final sent = await authService.sendEmailVerification();
    if (!mounted) return sent;
    if (!sent) {
      Get.snackbar(
        'error'.tr,
        authService.lastVerificationError ?? 'please_try_again'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (showSuccess) {
      Get.snackbar(
        'email_sent'.tr,
        '${'verification_email_resent'.tr} ${widget.email}',
        backgroundColor: AppColors.primaryPink,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return sent;
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (_isVerified || _isChecking) return;
    _isChecking = true;
    if (!silent && mounted) setState(() {});
    try {
      final authService = Get.find<AuthService>();
      await authService.reloadUser();
      if (authService.isEmailVerified) {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() => _isVerified = true);
        Get.snackbar(
          'email_verified'.tr,
          'email_verified_success'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) _navigateToNext();
      } else if (!silent && mounted) {
        Get.snackbar(
          'verify_email'.tr,
          'not_verified_yet'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      // network hiccup: the next poll tries again
    } finally {
      _isChecking = false;
      if (mounted) setState(() {});
    }
  }

  // AuthGate sends the user to the right next step: customer profile setup,
  // owner registration, or the app itself.
  void _navigateToNext() {
    Get.offAll(() => const AuthGate());
  }

  Future<void> _resendEmail() async {
    if (_secondsRemaining > 0 || _isResending) return;
    setState(() => _isResending = true);
    final sent = await _sendVerificationEmail(showSuccess: true);
    if (mounted) setState(() => _isResending = false);
    if (sent) _startCooldown();
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
                  style: AppTextStyles.displayMedium.copyWith(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'verification_sent'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(color: theme.mutedTextColor),
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
                    style: AppTextStyles.bodyLarge.copyWith(
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
                        style: AppTextStyles.bodySmall.copyWith(color: theme.mutedTextColor),
                      ),
                    ],
                  ),

                if (!_isVerified) ...[
                  const SizedBox(height: 12),
                  Text(
                    'check_spam_folder'.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(color: theme.mutedTextColor),
                  ),
                ],

                const SizedBox(height: 24),

                // Resend button
                if (!_isVerified)
                  Column(
                    children: [
                      AppButton(
                        label: _isChecking ? '...' : 'i_have_verified'.tr,
                        onTap: () => _checkVerified(),
                      ),
                      const SizedBox(height: 12),
                      _isResending
                          ? const CircularProgressIndicator(color: AppColors.primaryPink)
                          : AppButton(
                        label: _secondsRemaining > 0
                            ? '${'resend_in'.tr} ${_secondsRemaining}s'
                            : 'resend_email'.tr,
                        onTap: _secondsRemaining > 0 ? () {} : _resendEmail,
                        isOutline: _secondsRemaining > 0,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          await Get.find<AuthService>().logout();
                          Get.offAllNamed('/login');
                        },
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