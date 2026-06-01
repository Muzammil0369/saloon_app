import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_documents_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerServicesScreen extends StatefulWidget {
  const OwnerServicesScreen({super.key});

  @override
  State<OwnerServicesScreen> createState() => _OwnerServicesScreenState();
}

class _OwnerServicesScreenState extends State<OwnerServicesScreen> {
  final List<Map<String, String>> services = [
    {'name': 'Haircut', 'price': '500', 'duration': '30'},
    {'name': 'Beard Trim', 'price': '300', 'duration': '20'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Services', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
              const ProgressStepBar(totalSteps: 6, currentStep: 4),
              const SizedBox(height: 30),

              Text('Your Menu ✂️',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('List the services you offer',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 30),

              ...services.map((s) => _serviceCard(s, theme)),
              
              const SizedBox(height: 20),
              
              GestureDetector(
                onTap: () {
                  setState(() {
                    services.add({'name': 'New Service', 'price': '0', 'duration': '0'});
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryPink, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryPink),
                      const SizedBox(width: 8),
                      Text('Add New Service', style: AppTextStyles.buttonText?.copyWith(color: AppColors.primaryPink)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              AppButton(
                label: 'Save & Next',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerDocumentsScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(Map<String, String> service, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service['name']!, style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                const SizedBox(height: 4),
                Text('Rs. ${service['price']} · ${service['duration']} min', 
                  style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryPink),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
            onPressed: () {
              setState(() => services.remove(service));
            },
          ),
        ],
      ),
    );
  }
}
