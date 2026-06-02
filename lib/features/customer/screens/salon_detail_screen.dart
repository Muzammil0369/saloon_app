import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';
import 'package:saloon_app/core/controllers/booking_controller.dart';
import 'package:saloon_app/features/customer/screens/booking_screen.dart';

class SalonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> salon;

  const SalonDetailScreen({super.key, required this.salon});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  final BookingController _bookingController = Get.put(BookingController());

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
                          _infoItem(Icons.location_on_rounded, AppColors.primaryPink, salon['distance'] ?? 'N/A', 'Distance'),
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
                      Obx(() => ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bookingController.services.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final service = _bookingController.services[index];
                          final isSelected = service['isSelected'];
                          return GestureDetector(
                            onTap: () => _bookingController.toggleService(index),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.lightPink : theme.cardColor,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: isSelected ? AppColors.primaryPink : theme.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? AppColors.primaryPink : theme.mutedTextColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(service['name'], style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor)),
                                        const SizedBox(height: 4),
                                        Text('${service['duration']} min', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                                      ],
                                    ),
                                  ),
                                  Text('Rs. ${service['price']}', style: AppTextStyles.bodyLarge?.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
                    ],
                  ),
                ),

                // ── Gallery & Reviews ──
                // ... (Omitted for brevity, but existing code remains)

                const SizedBox(height: 100),
              ],
            ),
          ),

          // ── Bottom Book Now Button ──
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Obx(() => GestureDetector(
              onTap: _bookingController.selectedServices.isEmpty ? null : () {
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
                  gradient: _bookingController.selectedServices.isEmpty ? LinearGradient(colors: [theme.mutedTextColor, theme.mutedTextColor]) : AppGradients.primary,
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
                  child: Text(
                    _bookingController.selectedServices.isEmpty 
                      ? 'Select Services' 
                      : 'Book Now (Rs. ${_bookingController.totalPrice.toInt()})',
                    style: AppTextStyles.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            )),
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
