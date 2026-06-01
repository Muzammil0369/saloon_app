import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/notifications_screen.dart';
import 'package:saloon_app/features/customer/screens/salon_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const CustomerHomeScreen({super.key, required this.onTabChange});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final String userName = 'Muzammil';
  int _selectedCategory = 0;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  final List<Map<String, dynamic>> categories = [
    {'name': 'Haircut',    'icon': Icons.content_cut_rounded},
    {'name': 'Beard',      'icon': Icons.face_retouching_natural},
    {'name': 'Facial',     'icon': Icons.spa_rounded},
    {'name': 'Nails',      'icon': Icons.auto_awesome_rounded},
    {'name': 'Bridal',     'icon': Icons.favorite_rounded},
    {'name': 'Hair Color', 'icon': Icons.colorize_rounded},
  ];

  final List<Map<String, dynamic>> topSalons = [
    {'name': 'Royal Cuts Studio', 'distance': '0.3 km', 'status': 'Open', 'price': '500', 'rating': 4.9},
    {'name': 'Glamour Zone',      'distance': '0.7 km', 'status': 'Open', 'price': '800', 'rating': 4.8},
    {'name': 'The Barber Guild',  'distance': '1.2 km', 'status': 'Open', 'price': '600', 'rating': 4.7},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [theme.softShadow],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                            Text('$userName!', style: AppTextStyles.displayMedium?.copyWith(color: theme.textColor, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      _iconBtn(Icons.notifications_none_rounded, theme, () => Get.to(() => const NotificationsScreen())),
                      const SizedBox(width: 10),
                      _iconBtn(Icons.person_outline_rounded, theme, () => widget.onTabChange(4)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  GestureDetector(
                    onTap: () => widget.onTabChange(1), // Go to Explore
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.lightPinkColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.primaryPink, size: 20),
                          const SizedBox(width: 12),
                          Text('Search for salons, stylists...', style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)),
                          const Spacer(),
                          const Icon(Icons.tune_rounded, color: AppColors.primaryPink, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 10, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryPink.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20, bottom: -20,
                              child: Icon(Icons.auto_awesome_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('30% OFF', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('First Grooming\nSession!', style: AppTextStyles.headingLarge?.copyWith(color: Colors.white)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                    child: Text('Claim Now', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Categories
                    _sectionHeader('Categories', () => widget.onTabChange(1), theme),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final c = categories[index];
                          final isSelected = _selectedCategory == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = index);
                              widget.onTabChange(1);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryPink : theme.cardColor,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [theme.softShadow],
                                    ),
                                    child: Icon(c['icon'], color: isSelected ? Colors.white : AppColors.primaryPink, size: 24),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(c['name'], style: AppTextStyles.label.copyWith(color: isSelected ? AppColors.primaryPink : theme.textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Top Salons
                    _sectionHeader('Top Rated Near You', () => widget.onTabChange(1), theme),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: topSalons.length,
                      itemBuilder: (context, index) {
                        final salon = topSalons[index];
                        return _salonCard(salon, theme);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onSeeAll, ThemeHelper theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See All', style: AppTextStyles.linkText),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, ThemeHelper theme, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.lightPinkColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryPink, size: 22),
      ),
    );
  }

  Widget _salonCard(Map<String, dynamic> salon, ThemeHelper theme) {
    return GestureDetector(
      onTap: () => Get.to(() => SalonDetailScreen(salon: salon)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [theme.softShadow],
        ),
        child: Row(
          children: [
            Container(
              height: 80, width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(image: AssetImage('assets/slide1.png'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(salon['name'], style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          Text('${salon['rating']}', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Starting from Rs. ${salon['price']}', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: AppColors.primaryPink),
                      const SizedBox(width: 4),
                      Text(salon['distance'], style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                      const Spacer(),
                      Text('Book Now', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
