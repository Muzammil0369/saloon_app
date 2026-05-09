import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/notifications_screen.dart';

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
    {'name': 'Royal Cuts Studio', 'distance': '0.3 km', 'status': 'Open Until 9PM', 'price': '500', 'rating': 4.9},
    {'name': 'Glamour Zone',      'distance': '0.7 km', 'status': 'Open Now',       'price': '800', 'rating': 4.8},
    {'name': 'The Barber Guild',  'distance': '1.2 km', 'status': 'Open Now',       'price': '600', 'rating': 4.7},
  ];

  final List<Map<String, dynamic>> recentSalons = [
    {'name': 'Beauty & Beyond', 'distance': '2.1 km', 'status': 'Open Now', 'price': '1,200', 'rating': 4.9},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TopBar
              Container(
                color: theme.cardColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greeting, style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
                          const SizedBox(height: 2),
                          Text('$userName!', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
                        ],
                      ),
                    ),
                    // notification bell
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute (builder: (context)=> NotificationsScreen()));

                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 42, width: 42,
                            decoration: BoxDecoration(
                              color: theme.lightPinkColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.primaryPink),
                          ),
                          Positioned(
                            top: -2, right: -2,
                            child: Container(
                              height: 10, width: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primaryPink,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.cardColor, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 42, width: 42,
                      decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppGradients.banner,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.primaryPink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: Stack(
                        children: [
                          Positioned(top: -30, right: -20, child: Container(height: 100, width: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle))),
                          Positioned(bottom: -30, right: 20, child: Container(height: 70, width: 70, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SPECIAL OFFER', style: AppTextStyles.overline.copyWith(color: Colors.white.withOpacity(0.85))),
                              const SizedBox(height: 6),
                              Text('30% Off Bridal\nPackages 💐', style: AppTextStyles.headingLarge.copyWith(color: Colors.white, height: 1.3)),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () => widget.onTabChange(1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Book Now', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryPink),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    Text('Categories', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 82,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final selected = _selectedCategory == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = index),
                            child: Container(
                              width: 72,
                              margin: const EdgeInsets.only(right: 10),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 52, width: 52,
                                    decoration: BoxDecoration(
                                      gradient: selected ? AppGradients.primary : null,
                                      color: selected ? null : theme.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [theme.softShadow],
                                    ),
                                    child: Icon(categories[index]['icon'], size: 22, color: selected ? Colors.white : AppColors.primaryPink),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    categories[index]['name'],
                                    style: AppTextStyles.label.copyWith(
                                      color: selected ? AppColors.primaryPink : theme.mutedTextColor,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Top Salons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Top Salons Near You', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                        GestureDetector(onTap: () => widget.onTabChange(1), child: Text('See All', style: AppTextStyles.linkText)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...topSalons.map((salon) => _salonCard(salon, theme)),
                    const SizedBox(height: 24),

                    // Recently Visited
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recently Visited', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                        Text('See All', style: AppTextStyles.linkText),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...recentSalons.map((salon) => _salonCard(salon, theme)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _salonCard(Map<String, dynamic> salon, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.softShadow],
      ),
      child: Row(
        children: [
          Container(
            height: 68, width: 68,
            decoration: BoxDecoration(gradient: AppGradients.heroBg, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.content_cut_rounded, size: 28, color: AppColors.primaryPink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(salon['name'], style: AppTextStyles.cardTitle?.copyWith(color: theme.textColor)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: theme.mutedTextColor),
                    const SizedBox(width: 2),
                    Text(salon['distance'], style: AppTextStyles.label?.copyWith(color: theme.mutedTextColor)),
                    const SizedBox(width: 6),
                    Container(height: 3, width: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.mutedTextColor)),
                    const SizedBox(width: 6),
                    Text(salon['status'], style: AppTextStyles.label?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Rs.${salon['price']}', style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.textColor)),
                    const Spacer(),
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(salon['rating'].toString(), style: AppTextStyles.label?.copyWith(fontWeight: FontWeight.w700, color: theme.textColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}