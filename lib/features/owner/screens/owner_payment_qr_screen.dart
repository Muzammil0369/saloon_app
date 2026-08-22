import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

const String _imgbbApiKey = '854c22d480dce931a496682c8cdbb164';

class OwnerPaymentQrScreen extends StatefulWidget {
  const OwnerPaymentQrScreen({super.key});

  @override
  State<OwnerPaymentQrScreen> createState() => _OwnerPaymentQrScreenState();
}

class _OwnerPaymentQrScreenState extends State<OwnerPaymentQrScreen> {
  String get _ownerId => Get.find<AuthService>().uid ?? '';
  bool _isUploading = false;

  ImageProvider? _resolveImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    if (url.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(url.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {'image': base64Image},
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        await FirebaseFirestore.instance.collection('owners').doc(_ownerId).update({
          'paymentQrUrl': decoded['data']['url'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Get.snackbar('success'.tr, 'payment_qr_updated'.tr);
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_upload_image'.tr);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removeQr() async {
    await FirebaseFirestore.instance.collection('owners').doc(_ownerId).update({
      'paymentQrUrl': FieldValue.delete(),
    });
    Get.snackbar('success'.tr, 'payment_qr_removed'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('payment_qr'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('owners').doc(_ownerId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final qrUrl = data?['paymentQrUrl'] as String?;
          final image = _resolveImage(qrUrl);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'payment_qr_explainer'.tr,
                  style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.borderColor),
                      image: image != null ? DecorationImage(image: image, fit: BoxFit.contain) : null,
                    ),
                    child: image == null
                        ? Center(
                      child: Icon(Icons.qr_code_2_rounded, size: 64, color: theme.mutedTextColor),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUpload,
                    icon: _isUploading
                        ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Icon(Icons.upload_rounded, color: Colors.white, size: 18),
                    label: Text(
                      qrUrl == null ? 'upload_payment_qr'.tr : 'replace_payment_qr'.tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                if (qrUrl != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _removeQr,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('remove'.tr, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}