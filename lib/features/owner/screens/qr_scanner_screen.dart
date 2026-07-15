// lib/features/owner/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/services/security_service.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:get/get.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? _controller;
  bool _isVerifying = false;
  bool _hasScanned = false;

  String get _ownerId => Get.find<AuthService>().uid ?? '';

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onQRDetected(String scannedData) async {
    if (_hasScanned || _isVerifying) return;

    setState(() {
      _hasScanned = true;
      _isVerifying = true;
    });

    // Vibrate on detection
    // HapticFeedback.heavyImpact();

    // Verify the secure QR
    final result = await SecurityService.verifySecureQR(scannedData, _ownerId);

    if (!mounted) return;

    setState(() => _isVerifying = false);

    // Show result
    _showVerificationResult(result);
  }

  void _showVerificationResult(VerificationResult result) {
    final isSuccess = result.success;

    Get.defaultDialog(
      title: isSuccess ? 'verified'.tr : 'failed'.tr,
      titleStyle: TextStyle(
        color: isSuccess ? Colors.green : Colors.red,
        fontWeight: FontWeight.bold,
      ),
      content: Column(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.cancel,
            size: 64,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(result.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          if (result.code == 'ALREADY_USED')
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('security_alert'.tr, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          if (isSuccess) {
            Get.back(); // Go back to schedule
          } else {
            // Allow re-scan
            setState(() => _hasScanned = false);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSuccess ? Colors.green : AppColors.primaryPink,
        ),
        child: Text(isSuccess ? 'done'.tr : 'scan_again'.tr),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('scan_customer_qr'.tr, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty && !_hasScanned) {
                final scannedData = capture.barcodes.first.rawValue ?? '';
                if (scannedData.isNotEmpty) {
                  _onQRDetected(scannedData);
                }
              }
            },
          ),

          // Scanner overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryPink, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'align_qr_frame'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
            ),
          ),

          // Verification indicator
          if (_isVerifying)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryPink),
                    SizedBox(height: 16),
                    Text('verifying'.tr, style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}