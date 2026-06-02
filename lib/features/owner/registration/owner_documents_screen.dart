import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_review_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';
import 'package:saloon_app/shared/widgets/upload_box.dart';

class OwnerDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> salonData;
  const OwnerDocumentsScreen({super.key, required this.salonData});

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
        title: Text('Documents', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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

              Text('Legal Documents 📄',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('Upload your verification documents',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 40),
              
              UploadBox(title: 'CNIC Front', subtitle: 'Upload clear photo'),
              const SizedBox(height: 16),
              UploadBox(title: 'CNIC Back', subtitle: 'Upload clear photo'),
              const SizedBox(height: 16),
              UploadBox(title: 'Salon Photos', subtitle: 'Upload at least 3 photos'),
              
              const SizedBox(height: 40),

              AppButton(
                label: 'Save & Next',
                onTap: () {
                  final updatedSalonData = {
                    ...widget.salonData,
                    'cnicVerified': false, // Placeholder
                  };
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerReviewScreen(salonData: updatedSalonData)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}