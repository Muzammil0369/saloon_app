import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_basic_info_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerOTPScreen extends StatefulWidget {
  const OwnerOTPScreen({super.key});

  @override
  State<OwnerOTPScreen> createState() => _OwnerOTPScreenState();
}

class _OwnerOTPScreenState extends State<OwnerOTPScreen> {
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressStepBar(totalSteps: 6, currentStep: 2),
              const SizedBox(height: 30),

              Text('Enter OTP 🛡️',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('We sent a 6-digit code to your phone',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 40),

              Center(
                child: Pinput(
                  length: 6,
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

              AppButton(
                label: 'Verify & Continue',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerBasicInfoScreen()));
                },
              ),

              const SizedBox(height: 24),
              
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text('Resend Code', style: AppTextStyles.linkText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
