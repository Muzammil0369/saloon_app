import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/controllers/language_controller.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/screens/owner_dashboard_screen.dart';
import 'package:saloon_app/features/owner/screens/owner_schedule_screen.dart';
import 'package:saloon_app/features/owner/screens/owner_earnings_screen.dart';
import 'package:saloon_app/features/owner/screens/owner_profile_screen.dart';
import 'package:saloon_app/features/owner/screens/qr_scanner_screen.dart';

class OwnerMainWrapper extends StatefulWidget {
  final int initialIndex;
  const OwnerMainWrapper({super.key, this.initialIndex = 0});

  @override
  State<OwnerMainWrapper> createState() => _OwnerMainWrapperState();
}

class _OwnerMainWrapperState extends State<OwnerMainWrapper> {
  late int _selectedIndex;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard_rounded, 'activeIcon': Icons.dashboard, 'label': 'dashboard'.tr, 'color': AppColors.primaryPink},
    {'icon': Icons.calendar_month_rounded, 'activeIcon': Icons.calendar_month, 'label': 'schedule'.tr, 'color': const Color(0xFF4ECDC4)},
    {'icon': Icons.payments_rounded, 'activeIcon': Icons.payments, 'label': 'earnings'.tr, 'color': const Color(0xFFF59E0B)},
    {'icon': Icons.storefront_rounded, 'activeIcon': Icons.store, 'label': 'profile'.tr, 'color': const Color(0xFFA78BFA)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onTabChange(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      OwnerDashboardScreen(onTabChange: _onTabChange),
      const OwnerScheduleScreen(),
      const OwnerEarningsScreen(),
      const OwnerProfileScreen(),
    ];

    return Directionality(
      textDirection: Get.find<LanguageController>().languageCode == 'ur' 
          ? TextDirection.rtl 
          : TextDirection.ltr,
      child: Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),

      // FAB - Always visible for owner
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          );
        },
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Nav
      bottomNavigationBar: Container(
        height: 70 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final isSelected = _selectedIndex == index;
            final item = _navItems[index];
            final Color activeColor = item['color'] as Color;

            return GestureDetector(
              onTap: () => _onTabChange(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 64,
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sliding indicator line
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(bottom: isSelected ? 8 : 0),
                      width: isSelected ? 24 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Icon
                    Icon(
                      isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                      size: 22,
                      color: isSelected
                          ? activeColor
                          : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                    ),
                    const SizedBox(height: 2),
                    // Label
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? activeColor
                            : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
      ),
    );
  }
}