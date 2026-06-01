import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';

class QRScreen extends StatelessWidget {
  const QRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('My QR Code', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Show this QR at the salon to check-in',
                style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // ── QR Container ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: 'customer_12345_muzammil',
                  version: QrVersions.auto,
                  size: 200.0,
                  foregroundColor: AppColors.darkText,
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'Muzammil Khan',
                style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.lightPinkColor,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  'ID: #SB-12345',
                  style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 60),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionIcon(Icons.share_rounded, 'Share', theme),
                  const SizedBox(width: 40),
                  _actionIcon(Icons.download_rounded, 'Save', theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, String label, ThemeHelper theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.borderColor),
          ),
          child: Icon(icon, color: AppColors.primaryPink),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
      ],
    );
  }
}
