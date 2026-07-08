import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/auth_service.dart';

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
      Get.snackbar('Limit Reached', 'Maximum 10 photos allowed');
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
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  // Upload image - REPLACE THIS with your Cloudinary upload when you find it
  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      // ==========================================
      // TODO: Replace this with your Cloudinary upload
      // For now, we'll save the local file path as placeholder
      // You need to find your Cloudinary upload code and put it here
      // ==========================================

      // TEMPORARY: Just add a placeholder URL
      // In production, replace this with actual Cloudinary upload
      final downloadUrl = imageFile.path; // THIS IS TEMPORARY - REPLACE WITH CLOUDINARY URL

      // UPDATE FIRESTORE
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

      Get.snackbar('Success', 'Image uploaded successfully');
    } catch (e) {
      setState(() => _isUploading = false);
      Get.snackbar('Error', 'Failed to upload image: $e');
    }
  }

  // Delete image
  Future<void> _deleteImage(int index) async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'Delete Image',
      middleText: 'Are you sure you want to delete this image?',
      confirm: ElevatedButton(
        onPressed: () => Get.back(result: true),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
        child: const Text('Delete', style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(result: false),
        child: const Text('Cancel'),
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
      Get.snackbar('Success', 'Image deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('Salon Gallery', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
                  Text('Photos', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                  const SizedBox(height: 8),
                  Text('Showcase your best work and salon interior',
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
                          '${_images.length} photo${_images.length != 1 ? 's' : ''}',
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
                                Text('Add Photo',
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

                      return Stack(
                        children: [
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
                                  : Image.file(
                                File(imageUrl),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Uploading image...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}