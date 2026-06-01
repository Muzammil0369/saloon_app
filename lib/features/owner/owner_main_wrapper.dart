import 'package:flutter/material.dart';
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

    final List<Widget> _screens = [
      OwnerDashboardScreen(onTabChange: _onTabChange),
      const OwnerScheduleScreen(),
      const OwnerEarningsScreen(),
      const OwnerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
        },
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: theme.mutedTextColor,
        backgroundColor: theme.cardColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
