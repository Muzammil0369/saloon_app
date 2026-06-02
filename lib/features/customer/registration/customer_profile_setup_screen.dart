import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/features/customer/customer_main_wrapper.dart';
import 'package:saloon_app/core/controllers/user_controller.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class CustomerProfileSetupScreen extends StatefulWidget {
  const CustomerProfileSetupScreen({super.key});

  @override
  State<CustomerProfileSetupScreen> createState() => _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState extends State<CustomerProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  void _finishSetup() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar('Name Required', 'Please enter your full name', 
        backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoading = true);
    
    final authService = Get.find<AuthService>();
    final dbService = Get.find<DatabaseService>();

    try {
      await dbService.saveUserProfile(authService.uid!, {
        'name': _nameController.text.trim(),
        'role': 'customer',
        'createdAt': DateTime.now(),
      });
      
      Get.put(UserController());
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save profile. Please try again.', 
        backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile Setup', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressStepBar(totalSteps: 2, currentStep: 2),
              const SizedBox(height: 30),


              Text('Complete Your Profile ✨',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 24, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('Just a few more details to get started',
                style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
              ),
              
              const SizedBox(height: 40),
              
              Center(
                child: Stack(
                  children: [
                    Container(
                      height: 120, width: 120,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryPink, width: 2),
                      ),
                      child: Icon(Icons.person_rounded, size: 60, color: theme.mutedTextColor),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text('Full Name', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.borderColor),
                ),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(color: theme.mutedTextColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
              : AppButton(
                label: 'Finish Setup',
                onTap: _finishSetup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
