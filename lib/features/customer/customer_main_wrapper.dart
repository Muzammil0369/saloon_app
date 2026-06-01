import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/customer_home_screen.dart';
import 'package:saloon_app/features/customer/screens/explore_screen.dart';
import 'package:saloon_app/features/customer/screens/my_bookings_screen.dart';
import 'package:saloon_app/features/customer/screens/customer_profile_screen.dart';
import 'package:saloon_app/features/customer/screens/qr_screen.dart';
import 'package:saloon_app/shared/screens/wallet_screen.dart';

class CustomerMainWrapper extends StatefulWidget {
  final int initialIndex;
  const CustomerMainWrapper({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainWrapper> createState() => _CustomerMainWrapperState();
}

class _CustomerMainWrapperState extends State<CustomerMainWrapper> {
  late int _selectedIndex;

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

    final List<Widget> screens = [
      CustomerHomeScreen(onTabChange: _changeTab),
      const ExploreScreen(),
      const MyBookingsScreen(),
      const WalletScreen(),
      const CustomerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScreen()));
        },
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _changeTab,
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: theme.mutedTextColor,
        backgroundColor: theme.cardColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
