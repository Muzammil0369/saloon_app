import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_review_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerDocumentsScreen extends StatefulWidget {
  const OwnerDocumentsScreen({super.key});

  @override
  State<OwnerDocumentsScreen> createState() => _OwnerDocumentsScreenState();
}

class _OwnerDocumentsScreenState extends State<OwnerDocumentsScreen> {
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
              const ProgressStepBar(totalSteps: 6, currentStep: 5),
              const SizedBox(height: 30),

              Text('Documents 📄',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('Upload your business license and salon photos',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 40),

              _uploadTile('CNIC Front/Back', Icons.badge_outlined, theme),
              const SizedBox(height: 16),
              _uploadTile('Salon Interior Photo', Icons.storefront_outlined, theme),
              const SizedBox(height: 16),
              _uploadTile('Business License (Optional)', Icons.description_outlined, theme),
              
              const SizedBox(height: 40),

              AppButton(
                label: 'Save & Next',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerReviewScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadTile(String label, IconData icon, ThemeHelper theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.lightPinkColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryPink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                Text('Max size 5MB', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              ],
            ),
          ),
          const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryPink),
        ],
      ),
    );
  }
}
