import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pinput/pinput.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/features/customer/registration/customer_profile_setup_screen.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class CustomerOTPScreen extends StatefulWidget {
  const CustomerOTPScreen({super.key});

  @override
  State<CustomerOTPScreen> createState() => _CustomerOTPScreenState();
}

class _CustomerOTPScreenState extends State<CustomerOTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = 45;
  bool _canResend = false;
  String _otpCode = '';
  final String _phoneNumber = '+92 300 1234567';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 45;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _resendOtp() {
    if (!_canResend) return;
    _otpController.clear();
    setState(() => _otpCode = '');
    _startTimer();
  }

  void _verifyOtp() {
    if (_otpCode.length == 6) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerProfileSetupScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text(
            'Please enter the complete 6-digit code',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    // pin themes
    final defaultTheme = PinTheme(
      width: 48,
      height: 58,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: theme.textColor,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor, width: 1.5),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.lightPinkColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryPink, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );

    final submittedTheme = defaultTheme.copyWith(
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryPink,
      ),
      decoration: BoxDecoration(
        color: theme.lightPinkColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkPink, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Verify OTP', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.lightPinkColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.primaryPink,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              ProgressStepBar(currentStep: 2, totalSteps: 3),
              const SizedBox(height: 30),
              Text('Enter Code 🔐',
                style: AppTextStyles.displayMedium?.copyWith(color: theme.textColor),
              ),
              const SizedBox(height: 6),
              Text('Sent to $_phoneNumber',
                style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
              ),

              const SizedBox(height: 36),

              // Pinput
              Center(
                child: Pinput(
                  length: 6,
                  controller: _otpController,
                  focusNode: _focusNode,
                  autofocus: true,
                  defaultPinTheme: defaultTheme,
                  focusedPinTheme: focusedTheme,
                  submittedPinTheme: submittedTheme,
                  separatorBuilder: (_) => const SizedBox(width: 10),
                  onChanged: (val) => setState(() => _otpCode = val),
                  onCompleted: (otp) => setState(() => _otpCode = otp),
                ),
              ),

              const SizedBox(height: 28),

              // Resend row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive? ",
                    style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor),
                  ),
                  _canResend
                      ? GestureDetector(
                    onTap: _resendOtp,
                    child: Text(
                      'Resend',
                      style: AppTextStyles.linkText.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                      : Text(
                    'Resend in ${_formatTime(_secondsRemaining)}',
                    style: AppTextStyles.taglineSmall?.copyWith(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              AppButton(label: 'Verify', onTap: _verifyOtp),
            ],
          ),
        ),
      ),
    );
  }
}