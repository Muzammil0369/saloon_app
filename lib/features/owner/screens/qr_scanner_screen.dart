import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

import '../../../core/theme/app_gradients.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                _showBookingDetails(code ?? 'Unknown');
              }
            },
          ),
          
          // ── Overlay UI ──
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 80),
                Text(
                  'Scan Customer QR',
                  style: AppTextStyles.headingLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Align the QR code within the frame',
                  style: AppTextStyles.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.7)),
                ),
                const Spacer(),
                
                // ── Scanner Frame ──
                GestureDetector(
                  onTap: () => _showBookingDetails('customer_12345_muzammil'), // Simulation
                  child: Container(
                    height: 260, width: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryPink, width: 4),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text('Tap to Simulate Scan', 
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // ── Flash Toggle ──
                Container(
                  margin: const EdgeInsets.only(bottom: 60),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          
          // ── Back Button ──
          Positioned(
            top: 50, left: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = ThemeHelper(context);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: theme.borderColor, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryPink,
                child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('Muzammil Khan', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
              Text('ID: #SB-12345', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.lightPinkColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primaryPink),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Haircut + Beard Trim', style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                          Text('Today, 10:00 AM', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                        ],
                      ),
                    ),
                    Text('Rs. 700', style: AppTextStyles.headingSmall?.copyWith(color: AppColors.primaryPink)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('Confirm Check-in', style: AppTextStyles.buttonText),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
