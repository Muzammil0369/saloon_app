import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/auth/screens/login_screen.dart';
import 'package:saloon_app/features/owner/screens/owner_notifications_screen.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/app_button.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  bool _notificationsOn = true;
  bool _openForBookings = true;
  bool _acceptWalkins = true;
  bool _showOnMap = true;
  bool _darkModeOn = false;

  @override
  void initState() {
    super.initState();
    _darkModeOn = Get.find<ThemeController>().isDarkMode.value;
  }

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.notifications, 'label': 'Notifications', 'bg': AppColors.lightPink, 'color': AppColors.primaryPink, 'screen': () => const OwnerNotificationsScreen(),},
    {'icon': Icons.people_alt_outlined, 'label': 'Staff Members', 'bg': const Color(0xFFFFE8EE), 'color': Colors.pinkAccent},
    {'icon': Icons.photo_size_select_actual, 'label': 'Gallery Photos', 'bg': const Color(0xFFE3F2FD), 'color': Colors.blue},
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Payout Settings', 'bg': const Color(0xFFE3F2FD), 'color': Colors.blue},
    {'icon': Icons.lock_rounded, 'label': 'Privacy & Security', 'bg': const Color(0xFFF3E5F5), 'color': Colors.purple},
    {'icon': Icons.help_rounded, 'label': 'Help & Support', 'bg': const Color(0xFFFFF8E1), 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Salon Settings', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Salon Info Card ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [theme.cardShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/slide1.png'),
                      const SizedBox(height: 4),
                      Text('Royal Cuts Studio', style: AppTextStyles.headingLarge?.copyWith(fontSize: 18, color: theme.textColor)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: theme.grey600()),
                          const SizedBox(width: 4),
                          Text('Peshawar', style: TextStyle(fontSize: 14, color: theme.grey600())),
                          const SizedBox(width: 8),
                          Text('·', style: TextStyle(color: theme.grey400())),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('4.9', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textColor)),
                          const SizedBox(width: 8),
                          Text('·', style: TextStyle(color: theme.grey400())),
                          const SizedBox(width: 8),
                          Text('142 reviews', style: TextStyle(fontSize: 14, color: theme.grey600())),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        child: Container(
                          width: 400,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.lightPinkColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Edit Salon Info',
                                style: AppTextStyles.buttonText?.copyWith(fontSize: 12, color: AppColors.primaryPink)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Quick Toggles Section ──
                Text('Quick Toggles', style: AppTextStyles.headingLarge?.copyWith(fontSize: 18, color: theme.textColor)),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [theme.softShadow],
                  ),
                  child: Column(
                    children: [
                      _buildToggleRow(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        value: _notificationsOn,
                        onToggle: () => setState(() => _notificationsOn = !_notificationsOn),
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: theme.borderColor),
                      const SizedBox(height: 12),
                      _buildToggleRow(
                        icon: Icons.calendar_month_outlined,
                        title: 'Open for Bookings',
                        value: _openForBookings,
                        onToggle: () => setState(() => _openForBookings = !_openForBookings),
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: theme.borderColor),
                      const SizedBox(height: 12),

                      _buildToggleRow(
                        icon: Icons.dark_mode_rounded,
                        title: 'Dark Mode',
                        value: _darkModeOn,
                        onToggle: () {
                          setState(() {
                            _darkModeOn = !_darkModeOn;
                          });
                          Get.find<ThemeController>().toggleTheme(); // Instant!
                        },
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: theme.borderColor),
                      const SizedBox(height: 12),

                      _buildToggleRow(
                        icon: Icons.directions_walk,
                        title: 'Accept Walk-ins',
                        value: _acceptWalkins,
                        onToggle: () => setState(() => _acceptWalkins = !_acceptWalkins),
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: theme.borderColor),
                      const SizedBox(height: 12),

                      _buildToggleRow(
                        icon: Icons.map_outlined,
                        title: 'Show on Map',
                        value: _showOnMap,
                        onToggle: () => setState(() => _showOnMap = !_showOnMap),
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Menu Items ──
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [theme.softShadow],
                  ),
                  child: Column(
                    children: List.generate(_menuItems.length, (i) {
                      final item = _menuItems[i];
                      return Column(
                        children: [
                          GestureDetector(
                          onTap: () {
                        switch (i) {
                          case 0:
                            Get.to(() => const OwnerNotificationsScreen());
                            break;
                          case 1:
                          //  Get.to(() => const StaffMembersScreen());
                            break;
                          case 2:
                          //  Get.to(() => const GalleryPhotosScreen());
                            break;
                          case 3:
                           // Get.to(() => const PayoutSettingsScreen());
                            break;
                          case 4:
                           // Get.to(() => const PrivacySecurityScreen());
                            break;
                          case 5:
                           // Get.to(() => const HelpSupportScreen());
                            break;
                        }
                      },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: item['bg'] as Color,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(item['icon'] as IconData, size: 18, color: item['color'] as Color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(item['label'],
                                        style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.textColor)),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.mutedTextColor),
                                ],
                              ),
                            ),
                          ),
                          if (i < _menuItems.length - 1)
                            Divider(height: 1, indent: 64, endIndent: 16, color: theme.borderColor),
                        ],
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 22),
                AppButton(
                  label: 'Logout',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required VoidCallback onToggle,
    required ThemeHelper theme,
  }) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.textColor)),
        ),
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 22,
            decoration: BoxDecoration(
              color: value ? AppColors.primaryPink : theme.borderColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 16, height: 16,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ],
    );
  }
}