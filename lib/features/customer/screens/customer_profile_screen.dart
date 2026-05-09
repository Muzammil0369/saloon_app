import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/theme/theme_controller.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _notificationsOn = true;
  bool _darkModeOn = false;

  @override
  void initState() {
    super.initState();
    _darkModeOn = Get.find<ThemeController>().isDarkMode.value;
  }

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.calendar_today_rounded, 'label': 'My Bookings',       'bg': AppColors.lightPink,        'color': AppColors.primaryPink},
    {'icon': Icons.favorite_rounded,       'label': 'Favourite Salons',  'bg': const Color(0xFFFFE8EE),    'color': Colors.pinkAccent},
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Payment Methods', 'bg': const Color(0xFFE8F5E9), 'color': AppColors.success},
    {'icon': Icons.location_on_rounded,    'label': 'Saved Addresses',   'bg': const Color(0xFFE3F2FD),    'color': Colors.blue},
    {'icon': Icons.lock_rounded,           'label': 'Privacy & Security','bg': const Color(0xFFF3E5F5),    'color': Colors.purple},
    {'icon': Icons.help_rounded,           'label': 'Help & Support',    'bg': const Color(0xFFFFF8E1),    'color': Colors.orange},
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
                    boxShadow: [theme.cardShadow],
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
                            Text('Muzammil', style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor)),
                            const SizedBox(height: 2),
                            Text('+92 300 1234567', style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
                            const SizedBox(height: 4),
                            Text('3 bookings this month', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('Edit', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('8', 'Total Bookings'),
                      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.3)),
                      _statItem('3', 'This Month'),
                      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.3)),
                      _statItem('2', 'Favourites'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Settings
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 12),
                      Divider(height: 1, color: theme.borderColor),
                      const SizedBox(height: 12),
                      _buildToggle(
                        icon: Icons.dark_mode_rounded,
                        iconColor: Colors.purple,
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Menu Items
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
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: item['bg'] as Color, borderRadius: BorderRadius.circular(10)),
                                    child: Icon(item['icon'] as IconData, size: 18, color: item['color'] as Color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(item['label'], style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.textColor)),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.mutedTextColor),
                                ],
                              ),
                            ),
                          ),
                          if (i < _menuItems.length - 1) Divider(height: 1, indent: 64, endIndent: 16, color: theme.borderColor),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // Logout
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.lightPinkColor, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, size: 18, color: AppColors.primaryPink),
                        const SizedBox(width: 8),
                        Text('Logout', style: AppTextStyles.bodyMedium?.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required VoidCallback onToggle,
    required ThemeHelper theme,
  }) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.textColor))),
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

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white70)),
      ],
    );
  }
}