import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class CustomerOTPScreen extends StatefulWidget {
  const CustomerOTPScreen({super.key});

  @override
  State<CustomerOTPScreen> createState() => _CustomerOTPScreenState();
}

class _CustomerOTPScreenState extends State<CustomerOTPScreen> {
  bool _isLoading = false;
  final String phone = Get.arguments?['phone'] ?? '';

  void _verifyOtp(String code) async {
    setState(() => _isLoading = true);
    
    bool success = await Get.find<AuthService>().verifyOTP(code);
    
    setState(() => _isLoading = false);
    
    if (success) {
      Get.toNamed('/customer-setup');
    } else {
      Get.snackbar('Invalid OTP', 'The code you entered is incorrect', 
        backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Verification', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
              const ProgressStepBar(totalSteps: 3, currentStep: 2),
              const SizedBox(height: 30),

              Text('Enter OTP 🔐', style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor)),
              const SizedBox(height: 8),
              Text('Verification code sent to $phone', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 40),

              Center(
                child: Pinput(
                  length: 6,
                  onCompleted: _verifyOtp,
                  defaultPinTheme: PinTheme(
                    width: 50, height: 56,
                    textStyle: AppTextStyles.headingMedium?.copyWith(color: theme.textColor),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.borderColor),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 50, height: 56,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryPink, width: 2),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
              else
                AppButton(
                  label: 'Verify & Continue',
                  onTap: () {}, // Handled by onCompleted in Pinput
                ),

              const SizedBox(height: 32),
              
              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text('Change Phone Number', style: AppTextStyles.linkText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
