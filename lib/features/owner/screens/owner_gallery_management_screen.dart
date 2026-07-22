import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';

// ImgBB API key - used to upload gallery/logo images to the cloud.
// Get your own free key at https://api.imgbb.com/ if you ever need to rotate it.
const String _imgbbApiKey = '854c22d480dce931a496682c8cdbb164';

class OwnerGalleryManagementScreen extends StatefulWidget {
  const OwnerGalleryManagementScreen({super.key});

  @override
  State<OwnerGalleryManagementScreen> createState() => _OwnerGalleryManagementScreenState();
}

class _OwnerGalleryManagementScreenState extends State<OwnerGalleryManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isLoading = true;
  List<String> _images = [];

  String get _ownerId => Get.find<AuthService>().uid!;

  @override
  void initState() {
    super.initState();
    _loadImagesFromFirestore();
  }

  // Load images from Firestore
  Future<void> _loadImagesFromFirestore() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('owners')
          .doc(_ownerId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final photos = data['salonPhotos'];
        if (photos != null && photos is List) {
          setState(() {
            _images = List<String>.from(photos.whereType<String>());
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading images: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    if (_images.length >= 10) {
      Get.snackbar('limit_reached'.tr, 'max_photos'.tr);
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_pick_image'.tr);
    }
  }

  // Upload image to ImgBB, then save the returned URL in Firestore
  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      // 1. Read image bytes and base64-encode (ImgBB accepts base64 uploads)
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 2. Upload to ImgBB
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode != 200) {
        throw Exception('ImgBB upload failed (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded['success'] != true) {
        throw Exception('ImgBB upload rejected the image');
      }

      final String downloadUrl = decoded['data']['url'];

      // 3. UPDATE FIRESTORE with the real hosted URL
      final updatedImages = [..._images, downloadUrl];

      await FirebaseFirestore.instance
          .collection('owners')
          .doc(_ownerId)
          .update({
        'salonPhotos': updatedImages,
        'thumbnail': updatedImages.isNotEmpty ? updatedImages.first : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _images = updatedImages;
        _isUploading = false;
      });

      Get.snackbar('success'.tr, 'image_uploaded'.tr);
    } catch (e) {
      setState(() => _isUploading = false);
      Get.snackbar('error'.tr, 'failed_upload_image'.tr + ': $e');
    }
  }

  // Delete image
  Future<void> _deleteImage(int index) async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'delete_image'.tr,
      middleText: 'confirm_delete_image'.tr,
      confirm: ElevatedButton(
        onPressed: () => Get.back(result: true),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
        child: Text('delete'.tr, style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(result: false),
        child: Text('cancel'.tr),
      ),
    );

    if (confirm != true) return;

    try {
      final updatedImages = List<String>.from(_images)..removeAt(index);

      await FirebaseFirestore.instance
          .collection('owners')
          .doc(_ownerId)
          .update({
        'salonPhotos': updatedImages,
        'thumbnail': updatedImages.isNotEmpty ? updatedImages.first : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _images = updatedImages);
      Get.snackbar('success'.tr, 'image_deleted'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_delete_image'.tr);
    }
  }

  Future<void> _setAsLogo(int index) async {
    final imageUrl = _images[index];

    await FirebaseFirestore.instance
        .collection('owners')
        .doc(_ownerId)
        .update({
      'logo': imageUrl,
      'thumbnail': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Also update users collection for customer side
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_ownerId)
        .update({
      'profileImage': imageUrl,
    });

    Get.snackbar('success'.tr, 'logo_updated'.tr,
        backgroundColor: AppColors.success, colorText: Colors.white);
  }


  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('salon_gallery'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryPink),
            onPressed: _loadImagesFromFirestore,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('photos'.tr, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                  const SizedBox(height: 8),
                  Text('showcase_work'.tr,
                      style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.lightPink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_images.length} ${_images.length != 1 ? 'photos'.tr : 'photo'.tr}',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: _images.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GestureDetector(
                          onTap: _isUploading ? null : _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.lightPinkColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryPink,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_rounded, color: AppColors.primaryPink, size: 32),
                                const SizedBox(height: 8),
                                Text('add_photo'.tr,
                                    style: AppTextStyles.label.copyWith(
                                        color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${_images.length}/10',
                                    style: AppTextStyles.caption.copyWith(color: theme.mutedTextColor)),
                              ],
                            ),
                          ),
                        );
                      }

                      final imageIndex = index - 1;
                      final imageUrl = _images[imageIndex];

                      return // Replace the Stack section (the image card) with this complete version:

                        Stack(
                          children: [
                            // Image
                            Hero(
                              tag: 'gallery_image_$imageIndex',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: imageUrl.startsWith('http')
                                    ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                  ),
                                )
                                    : imageUrl.startsWith('data:image')
                                    ? Image.memory(
                                  base64Decode(imageUrl.split(',').last),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                                    : Image.file(
                                  File(imageUrl),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),

                            // ✅ SET AS LOGO BUTTON
                            Positioned(
                              bottom: 8, left: 8,
                              child: GestureDetector(
                                onTap: () => _setAsLogo(imageIndex),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPink.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text('logo'.tr, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // ✅ CURRENT LOGO INDICATOR
                            // Check if this image is currently set as logo
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('owners').doc(_ownerId).snapshots(),
                              builder: (context, snapshot) {
                                final data = snapshot.data?.data() as Map<String, dynamic>?;
                                final currentLogo = data?['logo'];
                                final isLogo = currentLogo == imageUrl;

                                if (isLogo) {
                                  return Positioned(
                                    top: 8, left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.star, color: Colors.white, size: 14),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),

                            // Delete button
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () => _deleteImage(imageIndex),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('uploading_image'.tr, style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}