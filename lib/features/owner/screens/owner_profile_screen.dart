import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/app_theme.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/theme/theme_controller.dart';
import 'package:saloon_app/core/controllers/language_controller.dart';
import 'package:saloon_app/features/owner/screens/owner_ad_screen.dart';
import 'owner_gallery_management_screen.dart';
import 'owner_help_support_screen.dart';
import 'owner_services_management_screen.dart';
import 'owner_staff_screen.dart';
import 'owner_reviews_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  late final String ownerId;
  bool _isSwitchingLanguage = false;

  @override
  void initState() {
    super.initState();
    ownerId = Get.find<AuthService>().uid ?? '';
  }

  Stream<Map<String, dynamic>?> _getOwnerData() {
    return FirebaseFirestore.instance
        .collection('owners')
        .doc(ownerId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  Stream<Map<String, dynamic>?> _getWalletData() {
    return FirebaseFirestore.instance
        .collection('wallets')
        .doc(ownerId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  Stream<Map<String, int>> _getBookingStats() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      return {
        'total': docs.length,
        'completed': docs.where((d) {
          final s = d['status'] as String? ?? '';
          return s == 'completed' || s == 'paid' || s == 'verified';
        }).length,
        'pending': docs.where((d) {
          final s = d['status'] as String? ?? '';
          return s == 'pending' || s == 'confirmed';
        }).length,
      };
    });
  }

  ImageProvider? _getProfileImage(Map<String, dynamic>? data) {
    if (data == null) return null;
    final logo = data['logo'];
    if (logo != null && logo.toString().isNotEmpty) {
      if (logo.toString().startsWith('http')) return NetworkImage(logo);
      if (logo.toString().startsWith('data:image')) {
        try {
          final bytes = base64Decode(logo.toString().split(',').last);
          return MemoryImage(bytes);
        } catch (_) {}
      }
    }
    final ownerImage = data['ownerProfileImage'];
    if (ownerImage != null && ownerImage.toString().isNotEmpty) {
      if (ownerImage.toString().startsWith('http')) return NetworkImage(ownerImage);
      if (ownerImage.toString().startsWith('data:image')) {
        try {
          final bytes = base64Decode(ownerImage.toString().split(',').last);
          return MemoryImage(bytes);
        } catch (_) {}
      }
    }
    final salonPhotos = data['salonPhotos'];
    if (salonPhotos != null && salonPhotos is List && salonPhotos.isNotEmpty) {
      final firstPhoto = salonPhotos[0].toString();
      if (firstPhoto.startsWith('http')) return NetworkImage(firstPhoto);
      if (firstPhoto.startsWith('data:image')) {
        try {
          final bytes = base64Decode(firstPhoto.split(',').last);
          return MemoryImage(bytes);
        } catch (_) {}
      }
    }
    return null;
  }

  bool _hasNoImage(Map<String, dynamic>? data) {
    if (data == null) return true;
    final logo = data['logo'];
    final ownerImage = data['ownerProfileImage'];
    final salonPhotos = data['salonPhotos'];
    return (logo == null || logo.toString().isEmpty) &&
        (ownerImage == null || ownerImage.toString().isEmpty) &&
        (salonPhotos == null || salonPhotos is! List || salonPhotos.isEmpty);
  }

  void _editBusinessInfo(Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['salonName']);
    final addressCtrl = TextEditingController(text: data['address']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = ThemeHelper(context);
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
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
              Text(
                'edit_business_info'.tr,
                style: AppTextStyles.headingLarge?.copyWith(
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 24),
              _editField('salonName'.tr, nameCtrl, theme),
              const SizedBox(height: 16),
              _editField('address'.tr, addressCtrl, theme),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('owners')
                        .doc(ownerId)
                        .update({
                      'salonName': nameCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                    Get.snackbar(
                      'success'.tr,
                      'business_info_updated'.tr,
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('save'.tr, style: AppTextStyles.buttonText),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _editField(String label, TextEditingController ctrl, ThemeHelper theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.lightPinkColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: ctrl,
            style: TextStyle(color: theme.textColor),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _deleteAccount() async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'delete_account'.tr,
      middleText: 'delete_account_desc'.tr,
      confirm: ElevatedButton(
        onPressed: () => Get.back(result: true),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: Text(
          'confirm'.tr,
          style: const TextStyle(color: Colors.white),
        ),
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
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(userId)
          .delete();
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: userId)
          .get();
      for (var doc in bookings.docs) {
        await doc.reference.delete();
      }
      await FirebaseFirestore.instance
          .collection('wallets')
          .doc(userId)
          .delete();
      final transactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('metadata.ownerId', isEqualTo: userId)
          .get();
      for (var doc in transactions.docs) {
        await doc.reference.delete();
      }
      final services = await FirebaseFirestore.instance
          .collection('services')
          .where('ownerId', isEqualTo: userId)
          .get();
      for (var doc in services.docs) {
        await doc.reference.delete();
      }
      await authService.logout();
      Get.offAllNamed('/auth-gate');
      Get.snackbar(
        'success'.tr,
        'account_deleted'.tr,
      );
    } catch (e) {
      Get.snackbar('error'.tr, 'delete_error'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final languageController = Get.find<LanguageController>();
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _getOwnerData(),
        builder: (context, ownerSnapshot) {
          final data = ownerSnapshot.data;
          if (data == null)
            return const Center(child: CircularProgressIndicator());
          return StreamBuilder<Map<String, int>>(
            stream: _getBookingStats(),
            builder: (context, bookingSnapshot) {
              final bookingStats =
                  bookingSnapshot.data ??
                      {'total': 0, 'completed': 0, 'pending': 0};
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 70, 24, 30),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppRadius.xxl),
                        ),
                        boxShadow: [theme.softShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryPink,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primaryPink,
                              backgroundImage: _getProfileImage(data),
                              child: _hasNoImage(data)
                                  ? const Icon(
                                Icons.storefront_rounded,
                                size: 50,
                                color: Colors.white,
                              )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Obx(() => Text(
                            Get.find<LanguageController>().languageCode == 'ur'
                                ? (data['salonName_ur'] ?? data['salonName'] ?? 'salonName'.tr)
                                : (data['salonName'] ?? 'salonName'.tr),
                            style: AppTextStyles.displayMedium?.copyWith(
                              fontSize: 24,
                              color: theme.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem(
                                  '${bookingStats['completed']}',
                                  'completed'.tr,
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: theme.borderColor,
                                ),
                                _statItem('${bookingStats['total']}', 'total'.tr),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: theme.borderColor,
                                ),
                                _statItem(
                                  data['status'] == 'approved'
                                      ? 'verified'.tr
                                      : 'pending'.tr,
                                  'status'.tr,
                                  color: data['status'] == 'approved'
                                      ? AppColors.success
                                      : Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('business_mgmt'.tr, theme),
                    _profileTile(
                      Icons.edit_note_rounded,
                      'edit_business_info'.tr,
                      'name_address_details'.tr,
                      theme,
                          () => _editBusinessInfo(data),
                    ),
                    _menuTile(
                      Icons.content_cut_rounded,
                      'service_menu'.tr,
                      'manage_services_prices'.tr,
                      Colors.pinkAccent,
                      theme,() {
                      Get.to(() => const OwnerServicesManagementScreen());
                    }),
                    _menuTile(
                      Icons.image_outlined,
                      'salon_gallery'.tr,
                      'upload_salon_photos'.tr,
                      Colors.blue,
                      theme, () {
                        Get.to(() => const OwnerGalleryManagementScreen());
                        }),
                    _menuTile(
                      Icons.people_rounded,
                      'my_team'.tr,
                      'ustad_shagird_details'.tr,
                      Colors.red,
                      theme, () {
                      Get.to(() => const OwnerStaffScreen());
                    }),
                    _menuTile(
                        Icons.campaign_rounded,
                        'ads_offers'.tr,
                        'create_promote_offer'.tr,
                        Colors.purple,
                        theme, () {
                          Get.to(()=> const OwnerAdScreen());
                    }
                    ),
                    _menuTile(
                      Icons.star_rounded,
                      'reviews_ratings'.tr,
                      'see_customer_feedback'.tr,
                      Colors.yellow,
                      theme, () {
                      Get.to(() => OwnerReviewsScreen(ownerId: ownerId));
                    }),
                    _menuTile(Icons.help_rounded, 'help'.tr, 'help_subtitle'.tr, Colors.orange, theme, () {
                      Get.to(() => const OwnerHelpSupportScreen());
                    }),
                    const SizedBox(height: 24),
                    _sectionHeader('settings'.tr, theme),
                    Obx(
                          () => _buildToggleTile(
                        Icons.dark_mode_outlined,
                        'dark_mode'.tr,
                        Get.find<ThemeController>().isDarkMode.value,
                            (val) => Get.find<ThemeController>().toggleTheme(val),
                        theme,
                      ),
                    ),
                    _buildToggleTile(
                      Icons.store_rounded,
                      'open_salon'.tr,
                      data['isOpenNow'] ?? false,
                          (val) async {
                        await FirebaseFirestore.instance
                            .collection('owners')
                            .doc(ownerId)
                            .update({'isOpenNow': val});
                      },
                      theme,
                    ),
                    _buildToggleTile(
                      Icons.map_rounded,
                      'show_on_map'.tr,
                      data['showOnMap'] ?? true,
                          (val) async {
                        await FirebaseFirestore.instance
                            .collection('owners')
                            .doc(ownerId)
                            .update({'showOnMap': val});
                      },
                      theme,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                    // ✅ FIXED: Obx with inline widget
                    Obx(() => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [theme.softShadow],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.lightPinkColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:  Icon(Icons.language, color: AppColors.primaryPink, size: 20),
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
                      ),
                    )),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [theme.softShadow],
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        onTap: _deleteAccount,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_forever,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          'delete_account'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: Text(
                          'delete_account_desc'.tr,
                          style: AppTextStyles.label.copyWith(
                            color: theme.mutedTextColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.mutedTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () {
                          Get.find<AuthService>().logout();
                          Get.offAllNamed('/auth-gate');
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'logout_business'.tr,
                              style: AppTextStyles.buttonText?.copyWith(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeHelper theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(color: theme.textColor),
        ),
      ),
    );
  }

  Widget _profileTile(
      IconData icon,
      String title,
      String subtitle,
      ThemeHelper theme,
      VoidCallback onTap,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.softShadow],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.lightPinkColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryPink, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.mutedTextColor,
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, Color color, ThemeHelper theme, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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

  Widget _buildToggleTile(
      IconData icon,
      String title,
      bool value,
      Function(bool) onChanged,
      ThemeHelper theme,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.softShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.lightPinkColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryPink,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headingMedium?.copyWith(
            color: color ?? AppColors.primaryPink,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 10,
            color: AppColors.mutedText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

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