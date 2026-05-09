import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_shadows.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/customer_main_wrapper.dart';
import 'package:saloon_app/features/customer/registration/customer_otp_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/progress_step_bar.dart';

class CustomerPhoneScreen extends StatefulWidget {
  const CustomerPhoneScreen({super.key});

  @override
  State<CustomerPhoneScreen> createState() => _CustomerPhoneScreenState();
}

class _CustomerPhoneScreenState extends State<CustomerPhoneScreen> {
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
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.lightPinkColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, color: theme.textColor),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressStepBar(
                  totalSteps: 3,
                  currentStep: 1,
                ),
                const SizedBox(height: 30),

                Text('Your Phone 📱',
                  style: AppTextStyles.displayLarge?.copyWith(
                    fontSize: 25,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text('We\'ll send you a verification code',
                    style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                const SizedBox(height: 30),

                // Phone Input Container
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Country code
                      Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: theme.borderColor, width: 1.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇵🇰', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '+92',
                                style: AppTextStyles.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Phone input
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: theme.textColor),
                          decoration: InputDecoration(
                            hintText: '3XX XXXXXXX',
                            hintStyle: AppTextStyles.bodyMedium?.copyWith(
                              color: theme.mutedTextColor,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Standard SMS rates may apply',
                    style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                const SizedBox(height: 30),

                AppButton(label: 'Send OTP', onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CustomerOTPScreen()));
                }),
                const SizedBox(height: 20),

                // Divider Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: theme.borderColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: TextStyle(color: theme.mutedTextColor)),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: theme.borderColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Google Sign In Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CustomerMainWrapper()));
                  },
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/google.png', height: 26),
                        const SizedBox(width: 4),
                        Text(
                          'Continue with Google',
                          style: AppTextStyles.buttonText?.copyWith(color: theme.textColor),
                        ),
                      ],
                    ),
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