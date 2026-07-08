import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/features/customer/screens/saved_addresses_screen.dart';
import 'package:saloon_app/core/controllers/user_controller.dart';
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
  final userController = Get.find<UserController>();
  bool _notificationsOn = true;
  bool _darkModeOn = false;

  @override
  void initState() {
    super.initState();
    _darkModeOn = Get.find<ThemeController>().isDarkMode.value;
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
              Text('Edit Profile', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
              const SizedBox(height: 24),
              Text('Full Name', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
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
                    if (newName.isNotEmpty) {
                      // 1. Update Firestore
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await Get.find<DatabaseService>().saveUserProfile(uid, {'name': newName});
                        // 2. Update local state
                        userController.userName.value = newName;
                      }
                    }
                    Navigator.pop(context);
                    Get.snackbar('Profile Updated', 'Your changes have been saved.',
                        backgroundColor: AppColors.success, colorText: Colors.white);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Changes', style: AppTextStyles.buttonText),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Logout', style: TextStyle(color: ThemeHelper(context).textColor)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: ThemeHelper(context).mutedTextColor)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await Get.find<AuthService>().logout();
              Get.offAllNamed('/auth-gate');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Profile', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [theme.softShadow],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primaryPink,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.cardColor, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Text(userController.userName.value, style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor))),
                            const SizedBox(height: 2),
                            Obx(() => Text(userController.userEmail.value, style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showEditProfile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('Edit', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.w700)),
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
                        title: 'Notifications',
                        value: _notificationsOn,
                        onToggle: () => setState(() => _notificationsOn = !_notificationsOn),
                        theme: theme,
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      _buildToggle(
                        icon: Icons.dark_mode_rounded,
                        iconColor: Colors.purple,
                        title: 'Dark Mode',
                        value: _darkModeOn,
                        onToggle: () {
                          setState(() => _darkModeOn = !_darkModeOn);
                          Get.find<ThemeController>().toggleTheme(_darkModeOn);
                        },
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu Items
                _menuTile(Icons.favorite_rounded, 'Favourite Salons', 'Salons you love', Colors.pinkAccent, theme, () {
                   Get.to(() => const FavouriteSalonsScreen());
                }),
                _menuTile(Icons.account_balance_wallet_rounded, 'Payment Methods', 'Manage your cards', AppColors.success, theme, () {
                   Get.toNamed('/wallet');
                }),
                _menuTile(Icons.location_on_rounded, 'Saved Addresses', 'Office, Home...', Colors.blue, theme, () {
                   Get.to(() => const SavedAddressesScreen());
                }),
                _menuTile(Icons.help_rounded, 'Help & Support', 'FAQs and Contact', Colors.orange, theme, () {
                   Get.to(() => const HelpSupportScreen());
                }),

                const SizedBox(height: 32),

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
                        Text('Logout Account', style: AppTextStyles.buttonText?.copyWith(color: Colors.redAccent)),
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
        Switch(
          value: value,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.primaryPink,
        ),
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
}
