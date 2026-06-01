import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';
import 'package:saloon_app/features/customer/screens/booking_screen.dart';

class SalonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> salon;

  const SalonDetailScreen({super.key, required this.salon});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  final List<Map<String, dynamic>> services = [
    {'name': 'Classic Haircut', 'price': 'Rs. 500', 'duration': '30 min'},
    {'name': 'Beard Trim & Shape', 'price': 'Rs. 300', 'duration': '20 min'},
    {'name': 'Facial Spa', 'price': 'Rs. 1,200', 'duration': '45 min'},
    {'name': 'Hair Color (Global)', 'price': 'Rs. 2,500', 'duration': '90 min'},
    {'name': 'Head Massage', 'price': 'Rs. 400', 'duration': '15 min'},
  ];

  final List<String> galleryImages = [
    'assets/slide1.png',
    'assets/slide2.png',
    'assets/slide3.png',
    'assets/slide1.png',
  ];

  final List<Map<String, dynamic>> reviews = [
    {'user': 'Ali Khan', 'rating': 5.0, 'comment': 'Excellent service and very professional staff!', 'date': '2 days ago'},
    {'user': 'Sara Ahmed', 'rating': 4.5, 'comment': 'Loved the facial spa. Highly recommended.', 'date': '1 week ago'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final salon = widget.salon;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          // ── Scrollable Content ──
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Image ──
                Stack(
                  children: [
                    Hero(
                      tag: 'salon_image_${salon['name']}',
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppGradients.heroBg,
                          image: const DecorationImage(
                            image: AssetImage('assets/slide1.png'), // Placeholder
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'OPEN',
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            salon['name'],
                            style: AppTextStyles.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Salon Info ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl)),
                    boxShadow: [theme.softShadow],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoItem(Icons.star_rounded, Colors.amber, '${salon['rating']}', 'Rating'),
                          _infoItem(Icons.location_on_rounded, AppColors.primaryPink, salon['distance'], 'Distance'),
                          _infoItem(Icons.access_time_filled_rounded, Colors.blue, '9AM - 9PM', 'Timing'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: AppColors.mutedText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              salon['address'] ?? 'Street 5, Hayatabad Phase 6, Peshawar',
                              style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Services Section ──
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Our Services', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: services.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final service = services[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: theme.borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service['name'],
                                        style: AppTextStyles.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        service['duration'],
                                        style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  service['price'],
                                  style: AppTextStyles.bodyLarge?.copyWith(
                                    color: AppColors.primaryPink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Gallery Section ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gallery', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: galleryImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Container(
                                width: 120,
                                color: theme.lightPinkColor,
                                child: Image.asset(
                                  galleryImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.primaryPink),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Reviews Section ──
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reviews', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                          Text('See All', style: AppTextStyles.linkText),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...reviews.map((review) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [theme.softShadow],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review['user'],
                                  style: AppTextStyles.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${review['rating']}',
                                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review['comment'],
                              style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review['date'],
                              style: AppTextStyles.overline.copyWith(color: theme.mutedTextColor.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for sticky button
              ],
            ),
          ),

          // ── Back Button Overlay ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryPink, size: 22),
              ),
            ),
          ),

          // ── Favorite Button Overlay ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded, color: AppColors.primaryPink, size: 22),
            ),
          ),

          // ── Bottom Book Now Button ──
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(salon: salon),
                  ),
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Book Now',
                        style: AppTextStyles.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, Color color, String value, String label) {
    final theme = ThemeHelper(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
        ),
      ],
    );
  }
}
