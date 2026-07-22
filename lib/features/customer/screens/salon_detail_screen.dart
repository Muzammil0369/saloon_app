import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/controllers/booking_controller.dart';
import '../../../core/controllers/language_controller.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_helper.dart';
import 'booking_screen.dart';
import '../../../shared/widgets/favourite_button.dart';
import '../../../shared/widgets/ad_banner_card.dart';

class SalonDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? salon;
  final String? ownerId;
  final int initialTabIndex; // 0 = Services (default), 1 = Offers

  const SalonDetailScreen({
    super.key,
    this.salon,
    this.ownerId,
    this.initialTabIndex = 0,
  });

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  final BookingController _bookingController = Get.put(BookingController());
  final DatabaseService _dbService = DatabaseService.instance;
  late int _selectedTab = widget.initialTabIndex;

  String get _ownerId => widget.ownerId ?? widget.salon?['ownerId'] ?? '';

  @override
  void initState() {
    super.initState();
    print('Loading services for ownerId: $_ownerId');
    _bookingController.loadServices(_ownerId);

    ever(_bookingController.services, (services) {
      print('Services loaded: ${services.length}');
      for (var s in services) {
        print('  - ${s['name']} | Rs. ${s['price']} | ${s['duration']} min');
      }
    });
  }

  // Selects (in the booking controller) whichever loaded services match the
  // ad's included service names, then jumps to the Services tab so the
  // bottom "Book Now" button becomes enabled with those services pre-picked.
  void _bookThisOffer(List<Map<String, dynamic>> offerServices) {
    final offerNames = offerServices.map((s) => (s['name'] ?? '').toString().trim().toLowerCase()).toSet();

    if (_bookingController.services.isEmpty) {
      Get.snackbar('error'.tr, 'services_still_loading'.tr);
      return;
    }

    bool matchedAny = false;
    for (var i = 0; i < _bookingController.services.length; i++) {
      final name = (_bookingController.services[i]['name'] ?? '').toString().trim().toLowerCase();
      final shouldSelect = offerNames.contains(name);
      if (shouldSelect) matchedAny = true;
      _bookingController.services[i]['isSelected'] = shouldSelect;
    }
    _bookingController.services.refresh();

    if (!matchedAny) {
      Get.snackbar('error'.tr, 'offer_services_unavailable'.tr);
      return;
    }

    setState(() => _selectedTab = 0);
  }

  // Helper to build image from URL or Base64
  Widget _buildImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.store, size: 80, color: Colors.white54),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryPink,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _dbService.getSalonStream(_ownerId),
        builder: (context, salonSnapshot) {
          if (salonSnapshot.connectionState == ConnectionState.waiting) {
            return  Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            );
          }

          if (!salonSnapshot.hasData || !salonSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.mutedTextColor),
                  const SizedBox(height: 16),
                  Text('salon_not_found'.tr, style: TextStyle(color: theme.textColor)),
                ],
              ),
            );
          }

          final salonData = salonSnapshot.data!.data() as Map<String, dynamic>;
          final String salonName = Get.find<LanguageController>().languageCode == 'ur'
              ? (salonData['salonName_ur'] ?? salonData['salonName'] ?? widget.salon?['name'] ?? 'Unnamed Salon')
              : (salonData['salonName'] ?? widget.salon?['name'] ?? 'Unnamed Salon');
          final double salonRating = (salonData['rating'] ?? widget.salon?['rating'] ?? 0.0).toDouble();
          final int salonReviewCount = (salonData['reviewCount'] ?? widget.salon?['reviewCount'] ?? 0);
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
                            child: _buildImage(thumbnail),
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
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          right: 10,
                          child: FavouriteButton(
                            ownerId: _ownerId,
                            backgroundColor: const Color(0x4D000000), // black @ ~30% opacity
                            iconSize: 20,
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
                                  color: isOpen ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  isOpen ? 'open'.tr.toUpperCase() : 'closed'.tr.toUpperCase(),
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
                              _infoItem(Icons.star_rounded, Colors.amber, salonRating.toStringAsFixed(1),
                                  salonReviewCount > 0 ? '${'rating'.tr} ($salonReviewCount)' : 'rating'.tr),
                              _infoItem(Icons.location_on_rounded, AppColors.primaryPink, distance, 'distance'.tr),
                              _infoItem(Icons.access_time_filled_rounded, Colors.blue, '9AM - 9PM', 'timing'.tr),
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

                    // ── Services / Offers Tab Bar ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 0 ? AppColors.primaryPink : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'services'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedTab == 0 ? Colors.white : theme.mutedTextColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 1 ? AppColors.primaryPink : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'offers'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedTab == 1 ? Colors.white : theme.mutedTextColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Services Section ──
                    if (_selectedTab == 0)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'our_services'.tr,
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
                                      'no_services_available'.tr,
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

                    // ── Offers Section ──
                    if (_selectedTab == 1)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('ads').doc(_ownerId).snapshots(),
                          builder: (context, adSnapshot) {
                            final hasAd = adSnapshot.hasData && adSnapshot.data!.exists;
                            if (!hasAd) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(Icons.local_offer_outlined, size: 48, color: theme.mutedTextColor),
                                      const SizedBox(height: 12),
                                      Text('no_active_offers'.tr, style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final adData = adSnapshot.data!.data() as Map<String, dynamic>;
                            final expiresAt = (adData['expiresAt'] as Timestamp?)?.toDate();
                            final daysLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : 0;
                            final services = (adData['selectedServices'] as List? ?? []).whereType<Map<String, dynamic>>().toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AdBannerCard(ad: adData, height: 215),
                                const SizedBox(height: 12),
                                if (daysLeft > 0)
                                  Text('${'offer_valid_for_days'.tr}: $daysLeft', style: TextStyle(color: theme.mutedTextColor, fontSize: 12)),
                                const SizedBox(height: 16),
                                if (services.isNotEmpty) ...[
                                  Text('included_services'.tr, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                                  const SizedBox(height: 10),
                                  ...services.map((s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryPink),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(s['name'] ?? '', style: TextStyle(color: theme.textColor))),
                                        Text('${'rs'.tr} ${s['price']}', style: TextStyle(color: theme.mutedTextColor)),
                                      ],
                                    ),
                                  )),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _bookThisOffer(services),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryPink,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      'book_this_offer'.tr,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    // ── Gallery Section ──
                    if (salonPhotos.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'gallery'.tr,
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
                                child: _buildImage(salonPhotos[index], width: 120),
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
                      salon: salonSnapshot.data!.data() as Map<String, dynamic>,
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
                            ? 'select_services'.tr
                            : '${'book_now'.tr} (Rs. ${_bookingController.totalPrice.toInt()})',
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