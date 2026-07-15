// lib/features/customer/registration/customer_profile_setup_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/core/services/translation_service.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class CustomerProfileSetupScreen extends StatefulWidget {
  const CustomerProfileSetupScreen({super.key});

  @override
  State<CustomerProfileSetupScreen> createState() => _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState extends State<CustomerProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isLoading = false;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('add_profile_photo'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryPink),
              title: Text('take_photo'.tr),
              onTap: () {
                Navigator.pop(context);
                _captureImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryPink),
              title: Text('choose_gallery'.tr),
              onTap: () {
                Navigator.pop(context);
                _captureImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (image != null) {
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_pick_image'.tr);
    }
  }

// lib/features/customer/registration/customer_profile_setup_screen.dart

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;

    setState(() => _isUploading = true);

    try {
      // ✅ FIRST: Try Cloudinary upload
      final cloudinary = CloudinaryPublic(
        'dz6j2cdqu',
        'salon_photos',
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _profileImage!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'profile_images',
          publicId: 'user_$userId',
        ),
      );

      setState(() => _isUploading = false);

      // ✅ Return Cloudinary URL
      return response.secureUrl;

    } catch (e) {
      print('Cloudinary upload failed: $e');
      setState(() => _isUploading = false);

      // ✅ FALLBACK: Convert to base64 and save
      try {
        final bytes = await _profileImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        final base64String = 'data:image/jpeg;base64,$base64Image';

        Get.snackbar(
          'warning'.tr,
          'image_saved_locally'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        return base64String; // ✅ Return base64 string

      } catch (e2) {
        print('Base64 conversion failed: $e2');
        return null;
      }
    }
  }

  void _finishSetup() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar('name_required'.tr, 'please_enter_full_name'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoading = true);

    final authService = Get.find<AuthService>();
    final dbService = Get.find<DatabaseService>();
    final transService = Get.find<TranslationService>();
    final userId = authService.uid!;

    try {
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(userId);
      }

      final englishName = _nameController.text.trim();
      final urduName = await transService.translateEnToUr(englishName);

      await dbService.saveUserProfile(userId, {
        'name': englishName,
        'name_ur': urduName,
        'role': 'customer',
        'profileImage': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.offAllNamed('/customer-home');
      Get.snackbar('welcome'.tr, 'profile_setup_success'.tr,
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_save_profile'.tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
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
        title: Text('profile_setup'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressStepBar(totalSteps: 2, currentStep: 2),
              const SizedBox(height: 30),

              Text('complete_profile'.tr,
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 24, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('add_photo_name_start'.tr,
                style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
              ),

              const SizedBox(height: 40),

              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryPink, width: 3),
                          image: _profileImage != null
                              ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _profileImage == null
                            ? (_isUploading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
                            : Icon(Icons.person_rounded, size: 60, color: theme.mutedTextColor))
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 22, color: Colors.white),
                        ),
                      )],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              Text('fullName'.tr, style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.borderColor),
                ),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'enter_full_name'.tr,
                    hintStyle: TextStyle(color: theme.mutedTextColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              _isLoading || _isUploading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
                  : AppButton(
                label: 'finish_setup'.tr,
                onTap: _finishSetup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}