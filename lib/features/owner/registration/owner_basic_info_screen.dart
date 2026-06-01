import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_services_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerBasicInfoScreen extends StatefulWidget {
  const OwnerBasicInfoScreen({super.key});

  @override
  State<OwnerBasicInfoScreen> createState() => _OwnerBasicInfoScreenState();
}

class _OwnerBasicInfoScreenState extends State<OwnerBasicInfoScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Salon Info', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
              const ProgressStepBar(totalSteps: 6, currentStep: 3),
              const SizedBox(height: 30),

              Text('Basic Details 🏪',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('Tell us about your salon',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 40),

              _buildField('Salon Name', 'e.g. Royal Cuts Studio', theme),
              const SizedBox(height: 20),
              _buildField('Full Address', 'Street, Area, City', theme),
              const SizedBox(height: 20),
              
              Text('Location', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
              const SizedBox(height: 12),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 40, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text('Tap to select on Map', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              AppButton(
                label: 'Save & Next',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerServicesScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, ThemeHelper theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.borderColor),
          ),
          child: TextField(
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.mutedTextColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
