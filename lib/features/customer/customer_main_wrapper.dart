import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/customer_home_screen.dart';
import 'package:saloon_app/features/customer/screens/explore_screen.dart';
import 'package:saloon_app/features/customer/screens/my_bookings_screen.dart';
import 'package:saloon_app/features/customer/screens/customer_profile_screen.dart';

class CustomerMainWrapper extends StatefulWidget {
  const CustomerMainWrapper({super.key});

  @override
  State<CustomerMainWrapper> createState() => _CustomerMainWrapperState();
}

class _CustomerMainWrapperState extends State<CustomerMainWrapper> {
  int _selectedIndex = 0;

  void _changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    final List<Widget> screens = [
      CustomerHomeScreen(onTabChange: _changeTab),
      const ExploreScreen(),
      const MyBookingsScreen(),
      const CustomerProfileScreen(),
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
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}