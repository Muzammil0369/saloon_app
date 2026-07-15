import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/controllers/language_controller.dart';
import 'package:saloon_app/features/customer/registration/customer_registration_screen.dart';
import 'package:saloon_app/features/owner/registration/owner_registration_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String _selectedRole = 'customer';
  final languageController = Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Language Toggle ──
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _langBtn('english'.tr, 'en'),
                      _langBtn('urdu'.tr, 'ur'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Obx(() => Text(
                languageController.languageCode == 'ur'
                    ? 'گلیم بک میں خوش آمدید! ✨'
                    : 'welcome_glambook'.tr,
                style: AppTextStyles.displayLarge?.copyWith(color: theme.textColor),
              )),
              const SizedBox(height: 12),
              Obx(() => Text(
                languageController.languageCode == 'ur'
                    ? 'منتخب کریں کہ آپ ایپ کو کیسے استعمال کرنا چاہتے ہیں'
                    : 'choose_app_usage'.tr,
                style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
              )),

              const SizedBox(height: 50),

              // ── Role Selection ──
              _roleCard(
                'customer',
                'customer_desc'.tr,
                'customer'.tr,
                Icons.person_rounded,
                theme,
              ),
              const SizedBox(height: 20),
              _roleCard(
                'owner',
                'owner_desc'.tr,
                'salon_owner'.tr,
                Icons.storefront_rounded,
                theme,
              ),

              const Spacer(),

              // ── Continue Button ──
              GestureDetector(
                onTap: () {
                  if (_selectedRole == 'customer') {
                    Get.to(() => const CustomerRegistrationScreen());
                  } else {
                    Get.to(() => const OwnerRegistrationScreen());
                  }
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPink.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'continue'.tr,
                      style: AppTextStyles.buttonText?.copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Get.toNamed('/login'),
                  child: Obx(() => RichText(
                    text: TextSpan(
                      text: languageController.languageCode == 'ur'
                          ? 'پہلے سے اکاؤنٹ ہے؟ '
                          : 'already_have_account'.tr + ' ',
                      style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
                      children: [
                        TextSpan(
                          text: languageController.languageCode == 'ur'
                              ? 'لاگ ان کریں'
                              : 'sign_in'.tr,
                          style: AppTextStyles.linkText,
                        ),
                      ],
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langBtn(String label, String code) {
    final isSelected = languageController.languageCode == code;
    return GestureDetector(
      onTap: () => languageController.switchLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.white : AppColors.mutedText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String id, String title, String subtitle, IconData icon, ThemeHelper theme) {
    final isSelected = _selectedRole == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink.withOpacity(0.05) : theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : theme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.lightPinkColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primaryPink, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle, style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor)),
                  const SizedBox(height: 4),
                  Text(title, style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryPink),
          ],
        ),
      ),
    );
  }
}