import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

import '../../../core/services/translation_service.dart';

class OwnerReviewScreen extends StatefulWidget {
  final Map<String, dynamic> salonData;
  const OwnerReviewScreen({super.key, required this.salonData});

  @override
  State<OwnerReviewScreen> createState() => _OwnerReviewScreenState();
}

class _OwnerReviewScreenState extends State<OwnerReviewScreen> {
  bool _isLoading = false;
  String _uploadStatus = '';


// Add this helper method inside the class:
  Future<String> _fileToBase64(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return '';
    try {
      final file = File(filePath);
      if (!await file.exists()) return filePath;
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64';
    } catch (e) {
      debugPrint('Base64 conversion failed: $e');
      return filePath;
    }
  }

  void _submitVerification() async {
    setState(() {
      _isLoading = true;
      _uploadStatus = 'Processing images...';
    });

    final authService = Get.find<AuthService>();
    final dbService = Get.find<DatabaseService>();
    final uid = authService.uid;

    if (uid == null) {
      Get.snackbar('error'.tr, 'please_login_again'.tr);
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Convert all images to base64 (NO Cloudinary)
      final cnicFrontFinal = await _fileToBase64(widget.salonData['cnicFront']);
      final cnicBackFinal = await _fileToBase64(widget.salonData['cnicBack']);
      final shopLicenseFinal = await _fileToBase64(widget.salonData['shopLicense']);
      final shopOutsideFinal = await _fileToBase64(widget.salonData['shopOutsidePhoto']);
      final ownerProfileFinal = await _fileToBase64(widget.salonData['ownerProfileImage']);

      // Convert salon photos
      List<String> salonPhotosFinal = [];
      if (widget.salonData['salonPhotos'] != null) {
        setState(() => _uploadStatus = 'Processing salon photos...');
        for (var path in (widget.salonData['salonPhotos'] as List)) {
          salonPhotosFinal.add(await _fileToBase64(path.toString()));
        }
      }

      // Convert worker photos
      List<Map<String, dynamic>> workersFinal = [];
      if (widget.salonData['workers'] != null) {
        setState(() => _uploadStatus = 'Processing worker photos...');
        for (var worker in (widget.salonData['workers'] as List)) {
          if (worker is Map) {
            final w = Map<String, dynamic>.from(worker);
            if (w['profileImage'] != null) {
              w['profileImage'] = await _fileToBase64(w['profileImage'].toString());
            }
            workersFinal.add(w);
          }
        }
      }

      setState(() => _uploadStatus = 'Saving...');

      final location = GeoPoint(widget.salonData['lat'], widget.salonData['lng']);

      // Get translation service
      final translationService = Get.find<TranslationService>();

// Translate if Urdu translations don't exist yet
      String salonNameUr = widget.salonData['salonName_ur'] ?? '';
      String addressUr = widget.salonData['address_ur'] ?? '';

// If translations are empty, translate them now
      if (salonNameUr.isEmpty && widget.salonData['salonName'] != null) {
        salonNameUr = await translationService.translateEnToUr(widget.salonData['salonName']);
      }
      if (addressUr.isEmpty && widget.salonData['address'] != null) {
        addressUr = await translationService.translateEnToUr(widget.salonData['address']);
      }

      await dbService.registerSalon(uid, {
        'ownerName': widget.salonData['ownerName'] ?? '',
        'salonName': widget.salonData['salonName'] ?? '',
        'salonName_ur': salonNameUr, // ✅ Add Urdu translation
        'phoneNumber': widget.salonData['phoneNumber'] ?? '',
        'address': widget.salonData['address'] ?? '',
        'address_ur': addressUr, // ✅ Add Urdu translation
        'fullName': widget.salonData['ownerName'] ?? '',
        'location': location,
        'lat': widget.salonData['lat'],
        'lng': widget.salonData['lng'],
        'services': widget.salonData['services'] ?? [],
        'workers': workersFinal.isNotEmpty ? workersFinal : (widget.salonData['workers'] ?? []),
        'hasCoworkers': widget.salonData['hasCoworkers'] ?? false,
        'cnicFront': cnicFrontFinal,
        'cnicBack': cnicBackFinal,
        'shopLicense': shopLicenseFinal,
        'shopOutsidePhoto': shopOutsideFinal,
        'salonPhotos': salonPhotosFinal,
        'ownerProfileImage': ownerProfileFinal,
        'thumbnail': salonPhotosFinal.isNotEmpty ? salonPhotosFinal.first : null,
        'status': 'pending',
        'isActive': false,
        'showOnMap': false,
        'isOpenNow': false,
        'cnicVerified': false,
        'isCompleted': true, // ✅ Add completion flag
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, location);

      await dbService.saveUserProfile(uid, {
        'role': 'owner',
        'status': 'pending',
        'name': widget.salonData['ownerName'] ?? '',
      });

      setState(() => _isLoading = false);

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 12),
              Text('submitted'.tr, textAlign: TextAlign.center),
            ],
          ),
          content: Text('registration_sent_verification'.tr),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.offAllNamed('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('ok'.tr, style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Registration error: $e');
      Get.snackbar('error'.tr, 'failed'.tr + ': $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final data = widget.salonData;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('review'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ProgressStepBar(totalSteps: 7, currentStep: 7),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryPink, Color(0xFFA0204A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.fact_check, color: Colors.white, size: 40),
                          const SizedBox(height: 12),
                          Text('review_details'.tr,
                            style: AppTextStyles.displayMedium?.copyWith(color: Colors.white, fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          Text('verify_before_submit'.tr,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 👤 Owner Section
                    _sectionHeader('owner_info'.tr, Icons.person),
                    const SizedBox(height: 12),
                    _buildCard([
                      _infoTile('full_name'.tr, data['ownerName'] ?? 'N/A', Icons.badge),
                      _infoTile('phone'.tr, data['phoneNumber'] ?? 'N/A', Icons.phone),
                    ]),

                    const SizedBox(height: 20),

                    // 🏪 Salon Section
                    _sectionHeader('salon_info'.tr, Icons.store),
                    const SizedBox(height: 12),
                    _buildCard([
                      _infoTile('salon_name'.tr, data['salonName'] ?? 'N/A', Icons.storefront),
                      _infoTile('address'.tr, data['address'] ?? 'N/A', Icons.location_on),
                      _infoTile('location'.tr, 'pinned_on_map'.tr, Icons.map, valueColor: Colors.green),
                    ]),

                    const SizedBox(height: 20),

                    // 💇 Services Section
                    _sectionHeader('services'.tr, Icons.content_cut),
                    const SizedBox(height: 12),
                    _buildCard([
                      _infoTile('total_services'.tr, '${(data['services'] as List?)?.length ?? 0} services', Icons.spa),
                      if ((data['services'] as List?)?.isNotEmpty == true)
                        ...(data['services'] as List).take(3).map((s) {
                          final name = s is Map ? (s['name'] ?? '') : '';
                          final price = s is Map ? (s['price'] ?? '') : '';
                          return _infoTile(name.toString(), 'Rs. $price', Icons.circle, valueColor: AppColors.primaryPink);
                        }),
                      if ((data['services'] as List?)?.length != null && (data['services'] as List).length > 3)
                        _infoTile('more'.tr, '+${(data['services'] as List).length - 3} services', Icons.more_horiz),
                    ]),

                    const SizedBox(height: 20),

                    // 👥 Workers Section
                    _sectionHeader('team'.tr, Icons.group),
                    const SizedBox(height: 12),
                    _buildCard([
                      _infoTile(
                        'workers'.tr,
                        data['hasCoworkers'] == true ? '${(data['workers'] as List?)?.length ?? 0} ${'coworkers'.tr}' : 'working_alone'.tr,
                        Icons.people,
                        valueColor: data['hasCoworkers'] == true ? AppColors.primaryPink : Colors.grey,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // 📄 Documents Section
                    _sectionHeader('documents'.tr, Icons.description),
                    const SizedBox(height: 12),
                    _buildCard([
                      _infoTile('cnic_front'.tr, data['cnicFront'] != null ? 'uploaded'.tr : 'missing'.tr,
                          Icons.credit_card, valueColor: data['cnicFront'] != null ? Colors.green : Colors.red),
                      _infoTile('cnic_back'.tr, data['cnicBack'] != null ? '✅ Uploaded' : '❌ Missing',
                          Icons.credit_card, valueColor: data['cnicBack'] != null ? Colors.green : Colors.red),
                      _infoTile('shop_license'.tr, data['shopLicense'] != null ? 'uploaded'.tr : 'not_provided'.tr,
                          Icons.description, valueColor: data['shopLicense'] != null ? Colors.green : Colors.grey),
                      _infoTile('salon_photos'.tr, '${(data['salonPhotos'] as List?)?.length ?? 0} ${'photos_uploaded'.tr}',
                          Icons.photo_library, valueColor: (data['salonPhotos'] as List?)?.isNotEmpty == true ? Colors.green : Colors.red),
                    ]),

                    const SizedBox(height: 32),

                    // Submit Button
                    if (_isLoading) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.primaryPink),
                            const SizedBox(height: 16),
                            Text(_uploadStatus, style: TextStyle(color: theme.mutedTextColor)),
                          ],
                        ),
                      ),
                    ] else
                      AppButton(
                        label: 'submit_verification'.tr,
                        onTap: _submitVerification,
                      ),

                    const SizedBox(height: 16),

                    // Note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.
                        withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Your salon will be reviewed within 24-48 hours. You can login to check status.',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryPink, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headingSmall?.copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    final theme = ThemeHelper(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.softShadow],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, {Color? valueColor}) {
    final theme = ThemeHelper(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.borderColor.withOpacity(0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // ← Align top for long text
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2, // ← Give label less space
            child: Text(label, style: TextStyle(fontSize: 14, color: theme.mutedTextColor)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3, // ← Give value more space, wrap text
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? theme.textColor,
              ),
              textAlign: TextAlign.right,
              maxLines: 2, // ← Allow 2 lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}