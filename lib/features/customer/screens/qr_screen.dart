// lib/features/customer/screens/qr_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/security_service.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:get/get.dart';

class QRScreen extends StatefulWidget {
  final String bookingId;
  final String ownerId;

  const QRScreen({
    super.key,
    required this.bookingId,
    required this.ownerId,
  });

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  String _qrData = '';
  bool _isLoading = true;
  int _secondsRemaining = 120;

  @override
  void initState() {
    super.initState();
    _generateQR();
    _startExpiryTimer();
  }

  Future<void> _generateQR() async {
    final customerId = Get.find<AuthService>().uid!;

    final secureQR = await SecurityService.generateSecureQRPayload(
      bookingId: widget.bookingId,
      customerId: customerId,
      ownerId: widget.ownerId,
    );

    setState(() {
      _qrData = secureQR;
      _isLoading = false;
    });
  }

  void _startExpiryTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        _startExpiryTimer();
      } else if (mounted) {
        _secondsRemaining = 120;
        _generateQR();
        _startExpiryTimer();
      }
    });
  }

  void _refreshQR() {
    setState(() {
      _isLoading = true;
      _secondsRemaining = 120;
    });
    _generateQR();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('secure_qr'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQR,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Security badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text('encrypted'.tr, style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'show_qr_at_salon'.tr,
                style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Expiry timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _secondsRemaining < 30 ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${'expires'.tr} ${_secondsRemaining}s',
                  style: TextStyle(
                    color: _secondsRemaining < 30 ? Colors.red : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // QR Container with security animation
              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primaryPink)
                  : Container(
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
                child: Column(
                  children: [
                    QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 220.0,
                      foregroundColor: AppColors.darkText,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                    const SizedBox(height: 12),
                    // Security indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _securityBadge('aes_256'.tr, Icons.enhanced_encryption),
                        const SizedBox(width: 12),
                        _securityBadge('hmac'.tr, Icons.fingerprint),
                        const SizedBox(width: 12),
                        _securityBadge('totp'.tr, Icons.timer),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Warning
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'do_not_share'.tr,
                        style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _securityBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.green),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}