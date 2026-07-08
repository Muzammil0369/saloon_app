import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';
import 'package:saloon_app/core/controllers/booking_controller.dart';
import 'package:saloon_app/features/customer/screens/booking_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/database_service.dart';

class SalonDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? salon; // Keep for backward compatibility
  final String? ownerId; // New parameter

  const SalonDetailScreen({
    super.key,
    this.salon,
    this.ownerId,
  });

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  final BookingController _bookingController = Get.put(BookingController());
  final DatabaseService _dbService = DatabaseService.instance;

  String get _ownerId => widget.ownerId ?? widget.salon?['ownerId'] ?? '';

  @override
  void initState() {
    super.initState();
    print('Loading services for ownerId: $_ownerId');
    _bookingController.loadServices(_ownerId);

    // Debug: Listen to services changes
    ever(_bookingController.services, (services) {
      print('Services loaded: ${services.length}');
      for (var s in services) {
        print('  - ${s['name']} | Rs. ${s['price']} | ${s['duration']} min');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _dbService.getSalonStream(_ownerId),
        builder: (context, salonSnapshot) {
          // Loading state
          if (salonSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            );
          }

          // Error or no data
          if (!salonSnapshot.hasData || !salonSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.mutedTextColor),
                  const SizedBox(height: 16),
                  Text('Salon not found', style: TextStyle(color: theme.textColor)),
                ],
              ),
            );
          }

          // Get fresh salon data from Firestore
          final salonData = salonSnapshot.data!.data() as Map<String, dynamic>;
          final String salonName = salonData['salonName'] ?? widget.salon?['name'] ?? 'Unnamed Salon';
          final double salonRating = (salonData['rating'] ?? widget.salon?['rating'] ?? 0.0).toDouble();
          final String salonAddress = salonData['address'] ?? widget.salon?['address'] ?? 'No address provided';
          final bool isOpen = salonData['isOpenNow'] ?? widget.salon?['status'] == 'Open';
          final String? thumbnail = salonData['thumbnail'] ?? widget.salon?['imageUrl'];
          final List<String> salonPhotos = List<String>.from(
              salonData['salonPhotos'] ?? widget.salon?['salonPhotos'] ?? []
          );
          final String category = salonData['category'] ?? widget.salon?['category'] ?? 'Haircut';
          final String phoneNumber = salonData['phoneNumber'] ?? widget.salon?['phoneNumber'] ?? 'N/A';
          final String distance = widget.salon?['distance'] ?? 'N/A';

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero Image ──
                    Stack(
                      children: [
                        Hero(
                          tag: 'salon_image_$_ownerId',
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppGradients.heroBg,
                            ),
                            child: thumbnail != null && thumbnail.isNotEmpty
                                ? CachedNetworkImage(
                              imageUrl: thumbnail,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryPink,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: AppGradients.heroBg,
                                ),
                                child: const Icon(
                                  Icons.store,
                                  size: 80,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                                : Container(
                              decoration: BoxDecoration(
                                gradient: AppGradients.heroBg,
                              ),
                              child: const Icon(
                                Icons.store,
                                size: 80,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                        // Gradient overlay
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
                        // Back button
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 10,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                            onPressed: () => Get.back(),
                          ),
                        ),
                        // Salon info overlay
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
                                  color: isOpen ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  isOpen ? 'OPEN' : 'CLOSED',
                                  style: AppTextStyles.label.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                salonName,
                                style: AppTextStyles.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    salonRating.toStringAsFixed(1),
                                    style: AppTextStyles.bodyMedium?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    category,
                                    style: AppTextStyles.label.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Salon Info Card ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppRadius.xxl),
                        ),
                        boxShadow: [theme.softShadow],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _infoItem(Icons.star_rounded, Colors.amber, salonRating.toStringAsFixed(1), 'Rating'),
                              _infoItem(Icons.location_on_rounded, AppColors.primaryPink, distance, 'Distance'),
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
                                  salonAddress,
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
                          Text(
                            'Our Services',
                            style: AppTextStyles.headingSmall.copyWith(color: theme.textColor),
                          ),
                          const SizedBox(height: 16),
                          Obx(() {
                            if (_bookingController.isLoading.value) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(color: AppColors.primaryPink),
                                ),
                              );
                            }

                            if (_bookingController.services.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'No services available',
                                    style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _bookingController.services.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final service = _bookingController.services[index];
                                final isSelected = service['isSelected'] ?? false;
                                return GestureDetector(
                                  onTap: () => _bookingController.toggleService(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                        colors: [AppColors.lightPink, AppColors.lightPink.withOpacity(0.5)],
                                      )
                                          : null,
                                      color: isSelected ? null : theme.cardColor,
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryPink : theme.borderColor,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                        BoxShadow(
                                          color: AppColors.primaryPink.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(
                                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                                            color: isSelected ? AppColors.primaryPink : theme.mutedTextColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                // Try multiple possible field names
                                                service['name'] ?? service['serviceName'] ?? 'Unnamed Service',
                                                style: AppTextStyles.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.timer_outlined, size: 14, color: theme.mutedTextColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${service['duration'] ?? 30} min',
                                                    style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${service['price'] ?? 0}',
                                          style: AppTextStyles.bodyLarge?.copyWith(
                                            color: AppColors.primaryPink,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),

                    // ── Gallery Section ──
                    if (salonPhotos.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Gallery',
                          style: AppTextStyles.headingSmall.copyWith(color: theme.textColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: salonPhotos.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: salonPhotos[index],
                                  width: 120,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

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
                  onTap: _bookingController.selectedServices.isEmpty
                      ? null
                      : () {
                    Get.to(() => BookingScreen(
                      ownerId: _ownerId,
                      salon: widget.salon ?? salonSnapshot.data!.data() as Map<String, dynamic>,
                    ));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _bookingController.selectedServices.isEmpty
                          ? LinearGradient(colors: [Colors.grey, Colors.grey])
                          : AppGradients.primary,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: _bookingController.selectedServices.isEmpty
                          ? null
                          : [
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
          );
        },
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
        ),
      ],
    );
  }
}