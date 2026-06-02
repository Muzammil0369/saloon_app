import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';
import 'package:saloon_app/features/customer/customer_main_wrapper.dart';

class SuccessScreen extends StatelessWidget {
  final String bookingId;
  final String dateTime;

  const SuccessScreen({super.key, required this.bookingId, required this.dateTime});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // ── Success Icon ──
              Container(
                height: 120, width: 120,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: AppColors.success,
                ),
              ),

              const SizedBox(height: 40),

              // ── Message ──
              Text(
                'Booking Confirmed! 🎉',
                style: AppTextStyles.displayMedium?.copyWith(
                  color: theme.textColor,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your appointment has been successfully booked.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: theme.mutedTextColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ── Info Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.confirmation_num_outlined, 'Booking ID', '#${bookingId.substring(0, 8)}', theme),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                    _infoRow(Icons.calendar_today_rounded, 'Date & Time', dateTime, theme),
                  ],
                ),
              ),

              const Spacer(),

              // ── Buttons ──
              GestureDetector(
                onTap: () {
                  Get.offAll(() => const CustomerMainWrapper());
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(AppRadius.button),
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
                      'Go to Home',
                      style: AppTextStyles.buttonText?.copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ThemeHelper theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPink),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor)),
        const Spacer(),
        Text(value, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
      ],
    );
  }
}
