import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/features/owner/screens/owner_dashboard_screen.dart';
import 'package:saloon_app/features/owner/screens/owner_schedule_screen.dart';
import 'package:saloon_app/features/owner/screens/owner_earnings_screen.dart';
import 'package:saloon_app/features/owner/screens/owner_profile_screen.dart';

import '../../core/theme/theme_helper.dart';

class OwnerMainWrapper extends StatefulWidget {
  const OwnerMainWrapper({super.key});

  @override
  State<OwnerMainWrapper> createState() => _OwnerMainWrapperState();
}

class _OwnerMainWrapperState extends State<OwnerMainWrapper> {
  int _selectedIndex = 0;

  void _changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);


    final List<Widget> screens = [
      OwnerDashboardScreen(onTabChange: _changeTab),
      const OwnerScheduleScreen(),
      const OwnerEarningsScreen(),
      const OwnerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _changeTab,
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: theme.mutedTextColor,
        backgroundColor: theme.cardColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}