import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/controllers/user_controller.dart';
import 'package:saloon_app/features/customer/screens/notifications_screen.dart';
import 'package:saloon_app/features/customer/screens/salon_detail_screen.dart';
import 'package:saloon_app/shared/widgets/salon_card.dart';
import 'package:saloon_app/shared/widgets/ad_banner_card.dart';
import 'package:saloon_app/shared/widgets/notification_bell.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/controllers/language_controller.dart';
import '../../../core/controllers/salon_controller.dart';

class CustomerHomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const CustomerHomeScreen({super.key, required this.onTabChange});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final userController = Get.find<UserController>();
  final salonController = Get.find<SalonController>();
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyAds = [];
  bool _isLoadingAds = true;

  // Ads farther than this are not shown at all, even if they're the
  // "closest available" — irrelevant-but-technically-nearest is still irrelevant.
  static const double _maxAdDistanceKm = 25.0;
  static const int _maxAdsShown = 8;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr;
    if (hour < 17) return 'good_afternoon'.tr;
    return 'good_evening'.tr;
  }



  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
    await _loadNearbyAds();
  }

  Future<void> _loadNearbyAds() async {
    setState(() => _isLoadingAds = true);
    try {
      // Single-field query only — no composite index needed
      final snapshot = await FirebaseFirestore.instance
          .collection('ads')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();

      final List<Map<String, dynamic>> ads = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final GeoPoint? loc = data['location'];
        double distanceKm = double.infinity;

        if (_currentPosition != null && loc != null) {
          distanceKm = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            loc.latitude, loc.longitude,
          ) /
              1000;
        }

        // Skip ads with no usable distance, or too far to be relevant
        if (distanceKm > _maxAdDistanceKm) continue;

        ads.add({
          ...data,
          'ownerId': doc.id,
          'distanceKm': distanceKm,
        });
      }

      // Paid ads first (future monetization hook — all false today, so this
      // is a no-op until that feature is switched on), then nearest, then
      // highest-rated as the final tie-break.
      ads.sort((a, b) {
        final paidCompare = (b['isPaid'] == true ? 1 : 0).compareTo(a['isPaid'] == true ? 1 : 0);
        if (paidCompare != 0) return paidCompare;
        final distCompare = (a['distanceKm'] as double).compareTo(b['distanceKm'] as double);
        if (distCompare != 0) return distCompare;
        return ((b['rating'] ?? 0.0) as num).compareTo((a['rating'] ?? 0.0) as num);
      });

      if (mounted) {
        setState(() {
          _nearbyAds = ads.take(_maxAdsShown).toList();
          _isLoadingAds = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ads: $e');
      if (mounted) setState(() => _isLoadingAds = false);
    }
  }

  Future<void> _onRefresh() async {
    await _getCurrentLocation();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  List<Map<String, dynamic>> _processSalonSnapshot(QuerySnapshot snapshot, Position? userPos) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final GeoPoint? salonLoc = data['location'];
      String distanceText = 'N/A';
      double distanceValue = double.infinity;

      if (userPos != null && salonLoc != null) {
        final double distInMeters = Geolocator.distanceBetween(
          userPos.latitude, userPos.longitude,
          salonLoc.latitude, salonLoc.longitude,
        );
        final double distKm = distInMeters / 1000;
        distanceValue = distKm;
        String unit = Get.find<LanguageController>().languageCode == 'ur' ? 'km'.tr : 'km';
        distanceText = '${distKm.toStringAsFixed(1)} $unit';
      }

      return {
        'ownerId': doc.id,
        'name': Get.find<LanguageController>().languageCode == 'ur'
            ? (data['salonName_ur'] ?? data['salonName'] ?? 'Unnamed Salon')
            : (data['salonName'] ?? 'Unnamed Salon'),
        'salonName': data['salonName'] ?? 'Unnamed Salon', // redundant but safe
        'rating': data['rating']?.toDouble() ?? 4.5,
        'reviewCount': data['reviewCount'] ?? 0,
        'status': data['isOpenNow'] == true ? 'open'.tr : 'closed'.tr,
        'price': '500',
        'distance': distanceText,
        'distanceValue': distanceValue,
        'address': data['address'] ?? 'No address provided',
        'imageUrl': data['logo'] ??
            data['thumbnail'] ??
            data['profileImage'] ??
            (data['salonPhotos'] != null && (data['salonPhotos'] as List).isNotEmpty
                ? (data['salonPhotos'] as List).first
                : null),
        'logo': data['logo'],
        'thumbnail': data['thumbnail'],
        'salonPhotos': data['salonPhotos'] ?? [],
        'category': data['category'] ?? 'Haircut',
        'lat': salonLoc?.latitude ?? 0,
        'lng': salonLoc?.longitude ?? 0,
        'showOnMap': data['showOnMap'] ?? true,
      };
    }).toList();
  }

  Widget _buildSalonImage(String? url, ThemeHelper theme, {double size = 64}) {
    if (url == null || url.isEmpty) return _recentPlaceholder(theme, size: size);

    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _recentPlaceholder(theme, size: size),
        );
      } catch (_) {
        return _recentPlaceholder(theme, size: size);
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        color: theme.lightPinkColor,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _recentPlaceholder(theme, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryPink,
          backgroundColor: theme.cardColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                                Obx(() => Text('${userController.userName.value}!', style: AppTextStyles.displayMedium?.copyWith(fontSize: 22,color: theme.textColor, fontWeight: FontWeight.w800))),
                              ],
                            ),
                          ),
                          NotificationBell(
                            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                            theme: theme,
                            onTap: () => Get.to(() => const NotificationsScreen()),
                          ),
                          const SizedBox(width: 10),
                          _iconBtn(Icons.person_outline_rounded, theme, () => widget.onTabChange(4)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search Bar
                      GestureDetector(
                        onTap: () => widget.onTabChange(1),
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
                              Text('search_hint'.tr, style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)),
                              const Spacer(),
                              const Icon(Icons.tune_rounded, color: AppColors.primaryPink, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Promo Banner — nearest active salon ads, sorted by distance
                if (_isLoadingAds)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryPink)),
                  )
                else if (_nearbyAds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      height: 215,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _nearbyAds.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final ad = _nearbyAds[index];
                          return AdBannerCard(
                            ad: ad,
                            width: MediaQuery.of(context).size.width - 60,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SalonDetailScreen(
                                  ownerId: ad['ownerId'],
                                  initialTabIndex: 1, // jump straight to Offers tab
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                // No ads within range — show nothing rather than an irrelevant one

                const SizedBox(height: 32),

                // Recent Salons
                _buildRecentSalons(theme),

                const SizedBox(height: 32),

                // Top Rated Near You section
                _sectionHeader('top_rated_near'.tr, () => widget.onTabChange(1), theme),
                const SizedBox(height: 16),

                // Salons List
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('owners')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryPink),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 40, color: theme.mutedTextColor),
                              const SizedBox(height: 8),
                              Text('failed_to_load_salons'.tr, style: TextStyle(color: theme.mutedTextColor)),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _onRefresh,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: Text('retry'.tr),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.store_outlined, size: 48, color: theme.mutedTextColor),
                              const SizedBox(height: 8),
                              Text('no_salons'.tr, style: TextStyle(color: theme.mutedTextColor)),
                            ],
                          ),
                        ),
                      );
                    }

                    final salons = _processSalonSnapshot(snapshot.data!, _currentPosition);

                    salons.sort((a, b) {
                      final distA = (a['distanceValue'] ?? double.infinity) as double;
                      final distB = (b['distanceValue'] ?? double.infinity) as double;
                      return distA.compareTo(distB);
                    });

                    final displaySalons = salons.length > 10 ? salons.sublist(0, 10) : salons;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: displaySalons.length,
                      itemBuilder: (context, index) {
                        final salon = displaySalons[index];
                        return SalonCard(
                          salon: salon,
                          onTap: () {
                            salonController.addToRecent(salon);
                            Get.to(() => SalonDetailScreen(
                              ownerId: salon['ownerId'],
                              salon: salon,
                            ));
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
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
            child: Row(
              children: [
                Text('see_all'.tr, style: AppTextStyles.linkText),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryPink),
              ],
            ),
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

  Widget _buildRecentSalons(ThemeHelper theme) {
    return Obx(() {
      if (salonController.recentSalons.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('recent_salons'.tr, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                Text('scroll'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.linkText.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: salonController.recentSalons.length,
              itemBuilder: (context, index) {
                final salon = salonController.recentSalons[index];
                return GestureDetector(
                  onTap: () {
                    // Update recent list to move this to top
                    salonController.addToRecent(Map<String, dynamic>.from(salon));
                    Get.to(() => SalonDetailScreen(
                      ownerId: salon['ownerId'],
                      salon: salon,
                    ));
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildSalonImage(salon['imageUrl'], theme),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          salon['name'] ?? salon['salonName'] ?? '',
                          style: AppTextStyles.label.copyWith(color: theme.textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _recentPlaceholder(ThemeHelper theme, {double size = 64}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.lightPinkColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.store_rounded, color: AppColors.primaryPink, size: size * 0.45),
    );
  }
}