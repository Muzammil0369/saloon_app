// lib/features/customer/screens/customer_profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:saloon_app/features/customer/screens/saved_addresses_screen.dart';
import 'package:saloon_app/core/controllers/user_controller.dart';
import '../../../core/controllers/language_controller.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_helper.dart';
import 'favourite_salons_screen.dart';
import 'help_support_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isSwitchingLanguage = false;
  final userController = Get.find<UserController>();
  final ImagePicker _picker = ImagePicker();
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _darkModeOn = Get.find<ThemeController>().isDarkMode.value;
    // Refresh profile when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userController.refreshProfile();
    });
  }

  String get _userId => Get.find<AuthService>().uid ?? '';

  // Pick profile image
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
            Text('change_photo'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_userId).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                if (data?['profileImage'] != null) {
                  return ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text('remove_photo'.tr, style: const TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  );
                }
                return const SizedBox();
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
        await _uploadToCloudinary(File(image.path));
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_pick_image'.tr);
    }
  }

  Future<void> _uploadToCloudinary(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      final cloudinary = CloudinaryPublic(
        'dz6j2cdqu',
        'salon_photos',
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'profile_images',
          publicId: 'user_$_userId',
        ),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({
        'profileImage': response.secureUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isUploading = false);
      userController.refreshProfile();
      Get.snackbar('success'.tr, 'profile_updated'.tr,
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      setState(() => _isUploading = false);
      try {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update({'profileImage': 'data:image/jpeg;base64,$base64Image'});
        userController.refreshProfile();
        Get.snackbar('success'.tr, 'profile_updated'.tr);
      } catch (e2) {
        Get.snackbar('error'.tr, 'failed_save_profile'.tr);
      }
    }
  }

  Future<void> _removeProfileImage() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .update({'profileImage': FieldValue.delete()});
    userController.refreshProfile();
    Get.snackbar('success'.tr, 'photo_removed'.tr);
  }

  void _showEditProfile() {
    final TextEditingController nameCtrl = TextEditingController(text: userController.userName.value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = ThemeHelper(context);
        return Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('edit_profile'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
              const SizedBox(height: 24),
              Text('full_name'.tr, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.lightPinkColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: theme.textColor),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final newName = nameCtrl.text.trim();
                    if (newName.isNotEmpty && _userId.isNotEmpty) {
                      await Get.find<DatabaseService>().saveUserProfile(_userId, {
                        'name': newName,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      userController.refreshProfile();
                    }
                    Navigator.pop(context);
                    Get.snackbar('success'.tr, 'profile_updated'.tr,
                        backgroundColor: AppColors.success, colorText: Colors.white);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('save_changes'.tr, style: AppTextStyles.buttonText),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteAccount() async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'delete_account'.tr,
      middleText: 'delete_account_desc'.tr,
      confirm: ElevatedButton(
        onPressed: () => Get.back(result: true),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: Text('delete_account'.tr, style: const TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(result: false),
        child: Text('cancel'.tr),
      ),
    );

    if (confirm != true) return;

    try {
      final authService = Get.find<AuthService>();
      final userId = authService.uid!;

      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      final bookings = await FirebaseFirestore.instance.collection('bookings').where('customerId', isEqualTo: userId).get();
      for (var doc in bookings.docs) { await doc.reference.delete(); }
      await FirebaseFirestore.instance.collection('wallets').doc(userId).delete();
      final transactions = await FirebaseFirestore.instance.collection('transactions').where('userId', isEqualTo: userId).get();
      for (var doc in transactions.docs) { await doc.reference.delete(); }

      await authService.logout();
      Get.offAllNamed('/auth-gate');
      Get.snackbar('success'.tr, 'account_deleted'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_delete_account'.tr);
    }
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('logout'.tr, style: TextStyle(color: ThemeHelper(context).textColor)),
        content: Text('logout_confirmation'.tr, style: TextStyle(color: ThemeHelper(context).mutedTextColor)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () async {
              await Get.find<AuthService>().logout();
              Get.offAllNamed('/auth-gate');
            },
            child: Text('logout'.tr, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AssetImage('assets/default_avatar.png');
    }

    // ✅ Handle Cloudinary URL
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }

    // ✅ Handle base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        return MemoryImage(bytes);
      } catch (e) {
        print('Failed to decode base64 image: $e');
      }
    }

    // ✅ Handle local file (try to load)
    if (imageUrl.startsWith('/data/')) {
      try {
        return FileImage(File(imageUrl));
      } catch (e) {
        print('Failed to load local image: $e');
      }
    }

    return const AssetImage('assets/default_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final languageController = Get.find<LanguageController>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('profile'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await userController.refreshProfile();
          },
          color: AppColors.primaryPink,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Card with Clickable Avatar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [theme.softShadow],
                  ),
                  child: Row(
                    children: [
                      // Clickable Avatar
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(_userId).snapshots(),
                              builder: (context, snapshot) {
                                final data = snapshot.data?.data() as Map<String, dynamic>?;
                                final profileImage = data?['profileImage'] as String?;

                                return Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    gradient: profileImage == null ? AppGradients.primary : null,
                                    shape: BoxShape.circle,
                                    image: profileImage != null && profileImage.isNotEmpty
                                        ? DecorationImage(
                                      image: _getProfileImage(profileImage),
                                      fit: BoxFit.cover,
                                    )
                                        : null,
                                  ),
                                  child: _isUploading
                                      ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : (profileImage == null || profileImage.isEmpty
                                      ? const Icon(Icons.person_rounded, color: Colors.white, size: 30)
                                      : null),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPink,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.cardColor, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Show user name with loading state
                            Obx(() {
                              if (userController.isLoading.value) {
                                return const SizedBox(
                                  height: 20,
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    color: AppColors.primaryPink,
                                    backgroundColor: Colors.transparent,
                                  ),
                                );
                              }
                              return Text(
                                languageController.languageCode == 'ur'
                                    ? (userController.userNameUr.value.isNotEmpty
                                    ? userController.userNameUr.value
                                    : userController.userName.value)
                                    : userController.userName.value,
                                style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor),
                              );
                            }),
                            const SizedBox(height: 2),
                            Obx(() => Text(
                              userController.userEmail.value,
                              style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor),
                            )),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showEditProfile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('update'.tr, style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [theme.softShadow],
                  ),
                  child: Column(
                    children: [
                      _buildToggle(
                        icon: Icons.notifications_rounded,
                        iconColor: AppColors.primaryPink,
                        title: 'notifications'.tr,
                        value: _notificationsOn,
                        onToggle: () => setState(() => _notificationsOn = !_notificationsOn),
                        theme: theme,
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      _buildToggle(
                        icon: Icons.dark_mode_rounded,
                        iconColor: Colors.purple,
                        title: 'dark_mode'.tr,
                        value: _darkModeOn,
                        onToggle: () {
                          setState(() => _darkModeOn = !_darkModeOn);
                          Get.find<ThemeController>().toggleTheme(_darkModeOn);
                        },
                        theme: theme,
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      // ✅ Language Switch - Inline Obx
                      // ✅ Language Switch - Matching App Theme
                      Obx(() => Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.lightPinkColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.language, color: AppColors.primaryPink, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'language'.tr,
                              style: AppTextStyles.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          // Language Toggle Buttons
                          Container(
                            decoration: BoxDecoration(
                              color: theme.lightPinkColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _langButton('en', 'english'.tr, languageController.languageCode == 'en'),
                                _langButton('ur', 'urdu'.tr, languageController.languageCode == 'ur'),
                              ],
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu Items
                _menuTile(Icons.favorite_rounded, 'favourite_salons'.tr, 'favourite_salons_subtitle'.tr, Colors.pinkAccent, theme, () {
                  Get.to(() => const FavouriteSalonsScreen());
                }),
                _menuTile(Icons.account_balance_wallet_rounded, 'wallet'.tr, 'wallet_subtitle'.tr, AppColors.success, theme, () {
                  Get.toNamed('/wallet');
                }),
                _menuTile(Icons.location_on_rounded, 'saved_addresses'.tr, 'saved_addresses_subtitle'.tr, Colors.blue, theme, () {
                  Get.to(() => const SavedAddressesScreen());
                }),
                _menuTile(Icons.help_rounded, 'help'.tr, 'help_subtitle'.tr, Colors.orange, theme, () {
                  Get.to(() => const HelpSupportScreen());
                }),

                const SizedBox(height: 24),

                // Delete Account
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [theme.softShadow],
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    onTap: _deleteAccount,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                    ),
                    title: Text('delete_account'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    subtitle: Text('delete_account_desc'.tr, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.mutedTextColor),
                  ),
                ),

                const SizedBox(height: 24),

                // Logout Button
                GestureDetector(
                  onTap: _handleLogout,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Text('logout'.tr, style: AppTextStyles.buttonText?.copyWith(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({required IconData icon, required Color iconColor, required String title, required bool value, required VoidCallback onToggle, required ThemeHelper theme}) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor))),
        Switch(value: value, onChanged: (_) => onToggle(), activeColor: AppColors.primaryPink),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, Color color, ThemeHelper theme, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.softShadow],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Text(title, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
        subtitle: Text(subtitle, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.mutedTextColor),
      ),
    );
  }

// In both customer_profile_screen.dart and owner_profile_screen.dart

  Widget _langButton(String code, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected && !_isSwitchingLanguage) {
          setState(() => _isSwitchingLanguage = true);
          final languageController = Get.find<LanguageController>();
          languageController.switchLanguage(code);
          // Reset loading state after a delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _isSwitchingLanguage = false);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isSwitchingLanguage
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.white : AppColors.mutedText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
