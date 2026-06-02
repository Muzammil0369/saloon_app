import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerReviewScreen extends StatefulWidget {
  final Map<String, dynamic> salonData;
  const OwnerReviewScreen({super.key, required this.salonData});

  @override
  State<OwnerReviewScreen> createState() => _OwnerReviewScreenState();
}

class _OwnerReviewScreenState extends State<OwnerReviewScreen> {
  bool _isLoading = false;

  void _submitVerification() async {
    setState(() => _isLoading = true);
    
    final authService = Get.find<AuthService>();
    final dbService = Get.find<DatabaseService>();
    final uid = authService.uid;

    if (uid != null) {
      try {
        final location = GeoPoint(widget.salonData['lat'], widget.salonData['lng']);
        await dbService.registerSalon(uid, widget.salonData, location);
        
        setState(() => _isLoading = false);
        
        Get.dialog(
          AlertDialog(
            title: const Text('Request Submitted'),
            content: const Text('Your shop registration request is under verification. It may take 24 to 48 hours to complete. You will be notified via SMS/App when approved.'),
            actions: [
              TextButton(
                onPressed: () => Get.offAllNamed('/login'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        Get.snackbar('Error', 'Failed to submit registration: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    // Prepare list for UI
    final List<Map<String, String>> items = [
      {'label': 'Salon Name', 'value': widget.salonData['salonName']},
      {'label': 'Address', 'value': widget.salonData['address']},
      {'label': 'Services Count', 'value': (widget.salonData['services'] as List).length.toString()},
    ];

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

              Text('Review Details 📝',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 30),
              
              ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['label']!, style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor)),
                    Text(item['value']!, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                  ],
                ),
              )),
              
              const SizedBox(height: 40),

              _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
              : AppButton(
                label: 'Verify',
                onTap: _submitVerification,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
