import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_review_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> salonData;
  const OwnerDocumentsScreen({super.key, required this.salonData});

  @override
  State<OwnerDocumentsScreen> createState() => _OwnerDocumentsScreenState();
}

class _OwnerDocumentsScreenState extends State<OwnerDocumentsScreen> {
  final ImagePicker _picker = ImagePicker();

  // Document files
  File? _cnicFront;
  File? _cnicBack;
  File? _shopLicense;
  File? _shopOutsidePhoto;
  List<File> _salonPhotos = [];

  bool _isUploading = false;

  void _saveAndNext() {
    // Validate required documents
    if (_cnicFront == null || _cnicBack == null) {
      Get.snackbar('required'.tr, 'upload_cnic_both'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (_salonPhotos.length < 3) {
      Get.snackbar('required'.tr, 'upload_min_photos'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    final updatedSalonData = {
      ...widget.salonData,
      'cnicFront': _cnicFront?.path,
      'cnicBack': _cnicBack?.path,
      'shopLicense': _shopLicense?.path,
      'shopOutsidePhoto': _shopOutsidePhoto?.path,
      'salonPhotos': _salonPhotos.map((f) => f.path).toList(),
      'cnicVerified': false,
    };

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => OwnerReviewScreen(salonData: updatedSalonData),
    ));
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
        title: Text('documents'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressStepBar(totalSteps: 7, currentStep: 6),
              const SizedBox(height: 30),

              Text('legal_documents'.tr + ' 📄',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('upload_documents_desc'.tr,
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),

              const SizedBox(height: 32),

              // ⚠️ IMPORTANT NOTE
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'CNIC and legal documents cannot be changed after submission. Please upload clear, valid documents.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── IDENTITY DOCUMENTS ──
              _sectionTitle('identity_documents'.tr, Icons.badge, Colors.blue),
              const SizedBox(height: 12),

              // CNIC Front
              _buildDocumentUpload(
                title: 'cnic_front'.tr,
                subtitle: 'upload_clear_photo'.tr,
                file: _cnicFront,
                onPick: () => _pickSingleImage((file) => setState(() => _cnicFront = file)),
                onRemove: () => setState(() => _cnicFront = null),
                isRequired: true,
                isLocked: true, // Cannot be changed later
              ),
              const SizedBox(height: 16),

              // CNIC Back
              _buildDocumentUpload(
                title: 'cnic_back'.tr,
                subtitle: 'upload_clear_photo'.tr,
                file: _cnicBack,
                onPick: () => _pickSingleImage((file) => setState(() => _cnicBack = file)),
                onRemove: () => setState(() => _cnicBack = null),
                isRequired: true,
                isLocked: true,
              ),

              const SizedBox(height: 28),

              // ── BUSINESS DOCUMENTS ──
              _sectionTitle('business_documents'.tr, Icons.store, Colors.green),
              const SizedBox(height: 12),

              // Shop License / Ownership Document
              _buildDocumentUpload(
                title: 'shop_license'.tr,
                subtitle: 'Rent agreement, ownership proof, or shop license',
                file: _shopLicense,
                onPick: () => _pickSingleImage((file) => setState(() => _shopLicense = file)),
                onRemove: () => setState(() => _shopLicense = null),
                isRequired: false,
                isLocked: true,
              ),
              const SizedBox(height: 16),

              // Shop Outside Photo
              _buildDocumentUpload(
                title: 'shop_outside'.tr,
                subtitle: 'upload_clear_photo'.tr,
                file: _shopOutsidePhoto,
                onPick: () => _pickSingleImage((file) => setState(() => _shopOutsidePhoto = file)),
                onRemove: () => setState(() => _shopOutsidePhoto = null),
                isRequired: false,
                isLocked: false, // Can be changed
              ),

              const SizedBox(height: 28),

              // ── SALON PHOTOS ──
              _sectionTitle('salon_interior'.tr, Icons.photo_library, Colors.purple),
              const SizedBox(height: 12),

              // Salon Photos Grid
              _buildSalonPhotosGrid(),

              const SizedBox(height: 40),

              // Save & Next Button
              AppButton(
                label: _isUploading ? 'uploading'.tr : 'save_next'.tr,
                onTap: _isUploading ? () {} : _saveAndNext,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION TITLE ──
  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── SINGLE DOCUMENT UPLOAD ──
  Widget _buildDocumentUpload({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    bool isRequired = false,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: file != null ? Colors.green : (isRequired ? AppColors.primaryPink : Colors.grey.shade300),
          width: file != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (isRequired) ...[
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: Colors.red, fontSize: 14)),
                        ],
                        if (isLocked) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.lock, size: 14, color: Colors.orange.shade700),
                          Text('locked'.tr, style: TextStyle(fontSize: 10, color: Colors.orange)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (file != null)
          // Show uploaded image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    file,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            )
          else
          // Upload button
            GestureDetector(
              onTap: onPick,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.primaryPink),
                    const SizedBox(height: 8),
                    Text('tap_to_upload'.tr, style: TextStyle(fontSize: 13, color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                    Text(isRequired ? 'required'.tr : 'optional'.tr, style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── SALON PHOTOS GRID ──
  Widget _buildSalonPhotosGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _salonPhotos.length >= 3 ? Colors.green : AppColors.primaryPink, width: _salonPhotos.length >= 3 ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('salon_interior'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red, fontSize: 14)),
              const SizedBox(width: 8),
              Text('${_salonPhotos.length}/10', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('upload_salon_desc'.tr,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Show uploaded photos
              ..._salonPhotos.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        entry.value,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _salonPhotos.removeAt(entry.key)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // Add photo button
              if (_salonPhotos.length < 10)
                GestureDetector(
                  onTap: () => _pickMultipleImages(),
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 28, color: AppColors.primaryPink),
                        const SizedBox(height: 4),
                        Text('add_photo'.tr, style: TextStyle(fontSize: 10, color: AppColors.primaryPink)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          if (_salonPhotos.length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('photos_required'.tr, style: TextStyle(fontSize: 11, color: Colors.red.shade600)),
            ),
        ],
      ),
    );
  }

  // ── IMAGE PICKER METHODS ──
  Future<void> _pickSingleImage(Function(File) onPicked) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image != null) {
        onPicked(File(image.path));
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_pick_image'.tr);
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if (_salonPhotos.length < 10) {
              _salonPhotos.add(File(image.path));
            }
          }
        });
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_pick_images'.tr);
    }
  }
}