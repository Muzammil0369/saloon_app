import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/customer_home_screen.dart';
import 'package:saloon_app/features/customer/screens/explore_screen.dart';
import 'package:saloon_app/features/customer/screens/customer_profile_screen.dart';
import 'package:saloon_app/features/customer/screens/my_bookings_screen.dart';
import 'package:saloon_app/features/customer/screens/qr_screen.dart';
import 'package:saloon_app/shared/screens/wallet_screen.dart';

import '../../core/controllers/language_controller.dart';

class CustomerMainWrapper extends StatefulWidget {
  final int initialIndex;
  const CustomerMainWrapper({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainWrapper> createState() => _CustomerMainWrapperState();
}

class _CustomerMainWrapperState extends State<CustomerMainWrapper> {
  late int _selectedIndex;


  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'activeIcon': Icons.home, 'label': 'home'.tr, 'color': AppColors.primaryPink},
    {'icon': Icons.search_rounded, 'activeIcon': Icons.explore, 'label': 'explore'.tr, 'color': const Color(0xFF4ECDC4)},
    {'icon': Icons.calendar_today_rounded, 'activeIcon': Icons.calendar_month, 'label': 'my_bookings'.tr, 'color': const Color(0xFFA78BFA)},
    {'icon': Icons.account_balance_wallet_rounded, 'activeIcon': Icons.wallet, 'label': 'wallet'.tr, 'color': const Color(0xFFF59E0B)},
    {'icon': Icons.person_rounded, 'activeIcon': Icons.person, 'label': 'profile'.tr, 'color': const Color(0xFF6EE7B7)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      CustomerHomeScreen(onTabChange: _changeTab),
      const ExploreScreen(),
      const MyBookingsScreen(),
      const WalletScreen(),
      const CustomerProfileScreen(),
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

        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScreen(bookingId: '', ownerId: '',)),
            );
          },
          backgroundColor: AppColors.primaryPink,
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        )
            : null,

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
                onTap: () => _changeTab(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 64,
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      Icon(
                        isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                        size: 22,
                        color: isSelected
                            ? activeColor
                            : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
                      ),
                      const SizedBox(height: 2),
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