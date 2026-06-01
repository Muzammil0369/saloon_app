import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class CustomerPhoneScreen extends StatefulWidget {
  const CustomerPhoneScreen({super.key});

  @override
  State<CustomerPhoneScreen> createState() => _CustomerPhoneScreenState();
}

class _CustomerPhoneScreenState extends State<CustomerPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  void _sendOtp() async {
    if (_phoneController.text.trim().length < 10) {
      Get.snackbar('Invalid Phone', 'Please enter a valid 10-digit number', 
        backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final phone = '+92${_phoneController.text.trim()}';
    setState(() => _isLoading = true);
    
    await Get.find<AuthService>().sendOTP(
      phone,
      onCodeSent: (vid) {
        setState(() => _isLoading = false);
        Get.toNamed('/customer-otp', arguments: {'phone': phone});
      },
      onError: (msg) {
        setState(() => _isLoading = false);
        Get.snackbar('Error', msg, backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      },
    );
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
        title: Text('Create Account', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
              const ProgressStepBar(totalSteps: 3, currentStep: 1),
              const SizedBox(height: 30),
              Text('Your Phone 📱', style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor)),
              const SizedBox(height: 8),
              Text('We\'ll send you a verification code', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              const SizedBox(height: 40),

              // Phone Input
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 90,
                      decoration: BoxDecoration(border: Border(right: BorderSide(color: theme.borderColor, width: 1.5))),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇵🇰', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text('+92', style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          hintText: '3XX XXXXXXX',
                          hintStyle: TextStyle(color: theme.mutedTextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
              : AppButton(label: 'Send Verification Code', onTap: _sendOtp),

              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(child: Divider(color: theme.borderColor)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: TextStyle(color: theme.mutedTextColor))),
                  Expanded(child: Divider(color: theme.borderColor)),
                ],
              ),

              const SizedBox(height: 32),

              GestureDetector(
                onTap: () => Get.offAllNamed('/customer-home'),
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/google.png', height: 24),
                      const SizedBox(width: 12),
                      Text('Continue with Google', style: AppTextStyles.buttonText?.copyWith(color: theme.textColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
