import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/core/services/auth_service.dart';

class OwnerPendingScreen extends StatelessWidget {
  const OwnerPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  size: 80,
                  color: AppColors.primaryPink,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Awaiting Approval",
                style: AppTextStyles.displayMedium?.copyWith(
                  color: theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Your salon documents are being verified by our team. This usually takes 24-48 hours. You'll be notified as soon as you're approved.",
                style: AppTextStyles.bodyLarge?.copyWith(
                  color: theme.mutedTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppButton(
                label: "Logout",
                onTap: () {
                  Get.find<AuthService>().logout();
                  Get.offAllNamed('/auth-gate');
                },
                isOutline: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
