import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_otp_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

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
        title: Text('Salon Registration', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
              const ProgressStepBar(totalSteps: 6, currentStep: 1),
              const SizedBox(height: 30),

              Text('Owner Phone 📱',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('Register your salon and grow your business',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 40),

              // Phone Input
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
                      width: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: theme.borderColor, width: 1.5)),
                      ),
                      child: Center(
                        child: Text('+92', style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                      ),
                    ),
                    Expanded(
                      child: TextField(
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

              AppButton(
                label: 'Send Verification Code',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerOTPScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
