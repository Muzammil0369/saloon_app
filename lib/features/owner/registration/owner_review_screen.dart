import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/owner_main_wrapper.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerReviewScreen extends StatefulWidget {
  const OwnerReviewScreen({super.key});

  @override
  State<OwnerReviewScreen> createState() => _OwnerReviewScreenState();
}

class _OwnerReviewScreenState extends State<OwnerReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Review', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
              const ProgressStepBar(totalSteps: 6, currentStep: 6),
              const SizedBox(height: 30),

              Text('Final Review 🧐',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('Double check your information before going live',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 30),

              _reviewSection('Salon Profile', [
                {'label': 'Name', 'value': 'Royal Cuts Studio'},
                {'label': 'Address', 'value': 'Peshawar Cantt'},
              ], theme),
              
              const SizedBox(height: 16),
              
              _reviewSection('Services', [
                {'label': 'Haircut', 'value': 'Rs. 500'},
                {'label': 'Beard Trim', 'value': 'Rs. 300'},
              ], theme),
              
              const SizedBox(height: 16),
              
              _reviewSection('Documents', [
                {'label': 'CNIC', 'value': 'Uploaded'},
                {'label': 'Interior Photo', 'value': 'Uploaded'},
              ], theme),
              
              const SizedBox(height: 40),

              AppButton(
                label: 'Confirm & Go Live',
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const OwnerMainWrapper()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewSection(String title, List<Map<String, String>> items, ThemeHelper theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.headingSmall?.copyWith(color: AppColors.primaryPink)),
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['label']!, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                Text(item['value']!, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
