import 'package:flutter/material.dart';
import 'package:saloon_app/features/owner/registration/owner_otp_screen.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class OwnerPhoneScreen extends StatefulWidget {
  const OwnerPhoneScreen({super.key});

  @override
  State<OwnerPhoneScreen> createState() => _OwnerPhoneScreenState();
}

class _OwnerPhoneScreenState extends State<OwnerPhoneScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Owner Registration', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor,fontSize: 16)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressStepBar(totalSteps: 5, currentStep: 1),
              const SizedBox(height: 30),
              Text('Phone Number 📱', style: AppTextStyles.displayLarge?.copyWith(color: theme.textColor)),
              Text('We\'ll verify your identity via OTP', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              const SizedBox(height: 30),
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: theme.borderColor, width: 1.5)),
                      ),
                      child: Text('PK +92', style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.textColor)),
                    ),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          hintText: '3XX XXXXXXX',
                          hintStyle: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
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
              Text('Standard SMS rates may apply', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              const SizedBox(height: 30),
              AppButton(label: 'Send OTP', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerOTPScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }
}