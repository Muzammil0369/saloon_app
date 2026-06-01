import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';
import 'package:saloon_app/features/owner/owner_main_wrapper.dart';
import '../../../core/theme/theme_controller.dart';
import 'owner_gallery_management_screen.dart';
import 'owner_services_management_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  String _salonName = 'Royal Cuts Studio';
  String _ownerName = 'Ahmed Ali';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = Get.find<ThemeController>().isDarkMode.value;
  }

  void _editBusinessInfo() {
    final nameCtrl = TextEditingController(text: _salonName);
    final ownerCtrl = TextEditingController(text: _ownerName);
    
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
              Text('Business Info', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
              const SizedBox(height: 24),
              _editField('Salon Name', nameCtrl, theme),
              const SizedBox(height: 16),
              _editField('Owner Name', ownerCtrl, theme),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _salonName = nameCtrl.text;
                      _ownerName = ownerCtrl.text;
                    });
                    Navigator.pop(context);
                    Get.snackbar('Success', 'Business info updated', 
                      backgroundColor: AppColors.success, colorText: Colors.white);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Update Info', style: AppTextStyles.buttonText),
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
        Text(label, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: ctrl,
            style: TextStyle(color: theme.textColor),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Logout', style: TextStyle(color: ThemeHelper(context).textColor)),
        content: Text('Exit owner dashboard?', style: TextStyle(color: ThemeHelper(context).mutedTextColor)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.offAllNamed('/'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl)),
                boxShadow: [theme.softShadow],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryPink,
                    child: Icon(Icons.storefront_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(_salonName, style: AppTextStyles.displayMedium?.copyWith(color: theme.textColor)),
                  Text('Owner: $_ownerName', style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statItem('4.9', 'Rating'),
                      _verticalDivider(theme),
                      _statItem('1.2k', 'Bookings'),
                      _verticalDivider(theme),
                      _statItem('Verified', 'Status', isSuccess: true),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Business Management ──
            _sectionHeader('Business Management', theme),
            _profileTile(Icons.edit_note_rounded, 'Edit Business Info', 'Name and owner details', theme, _editBusinessInfo),
            _profileTile(Icons.access_time_rounded, 'Business Hours', '9:00 AM - 9:00 PM', theme, () {
              Get.snackbar('Hours', 'Feature coming soon: Drag to set hours', backgroundColor: theme.cardColor, colorText: theme.textColor);
            }),
            _profileTile(Icons.content_cut_rounded, 'Service Menu', 'Manage services & prices', theme, () {
               Get.to(() => const OwnerServicesManagementScreen());
            }),
            _profileTile(Icons.image_outlined, 'Salon Gallery', 'Upload salon photos', theme, () {
               Get.to(() => const OwnerGalleryManagementScreen());
            }),
            
            const SizedBox(height: 24),
            
            _sectionHeader('Settings', theme),
            _buildToggleTile(Icons.dark_mode_outlined, 'Dark Mode', _isDarkMode, (val) {
              setState(() => _isDarkMode = val);
              Get.find<ThemeController>().toggleTheme();
            }, theme),
            _profileTile(Icons.notifications_none_rounded, 'Notifications', 'Manage alerts', theme, () {}),
            
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text('Logout Business', style: AppTextStyles.buttonText?.copyWith(color: Colors.redAccent)),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeHelper theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, String subtitle, ThemeHelper theme, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.softShadow],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primaryPink, size: 20),
        ),
        title: Text(title, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
        subtitle: Text(subtitle, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.mutedTextColor),
      ),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, bool value, Function(bool) onChanged, ThemeHelper theme) {
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
            decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primaryPink),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, {bool isSuccess = false}) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headingMedium?.copyWith(color: isSuccess ? AppColors.success : AppColors.primaryPink)),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }

  Widget _verticalDivider(ThemeHelper theme) {
    return Container(height: 30, width: 1, color: theme.borderColor, margin: const EdgeInsets.symmetric(horizontal: 20));
  }
}
