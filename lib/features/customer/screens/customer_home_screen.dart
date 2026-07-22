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

import '../../../core/controllers/language_controller.dart';

class CustomerHomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const CustomerHomeScreen({super.key, required this.onTabChange});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final userController = Get.find<UserController>();
  int _selectedCategory = 0;
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

  final List<Map<String, dynamic>> categories = [
    {'name': 'haircut'.tr,    'icon': Icons.content_cut_rounded},
    {'name': 'beard'.tr,      'icon': Icons.face_retouching_natural},
    {'name': 'facial'.tr,     'icon': Icons.spa_rounded},
    {'name': 'nails'.tr,      'icon': Icons.auto_awesome_rounded},
    {'name': 'bridal'.tr,     'icon': Icons.favorite_rounded},
    {'name': 'hair_color'.tr, 'icon': Icons.colorize_rounded},
  ];

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

      if (userPos != null && salonLoc != null) {
        final double distInMeters = Geolocator.distanceBetween(
          userPos.latitude, userPos.longitude,
          salonLoc.latitude, salonLoc.longitude,
        );
        final double distKm = distInMeters / 1000;
        String unit = Get.find<LanguageController>().languageCode == 'ur' ? 'km'.tr : 'km';
        distanceText = '${distKm.toStringAsFixed(1)} $unit';
      }

      return {
        'ownerId': doc.id,
        'name': Get.find<LanguageController>().languageCode == 'ur'
            ? (data['salonName_ur'] ?? data['salonName'] ?? 'Unnamed Salon')
            : (data['salonName'] ?? 'Unnamed Salon'),
        'rating': data['rating']?.toDouble() ?? 4.5,
        'reviewCount': data['reviewCount'] ?? 0,
        'status': data['isOpenNow'] == true ? 'open'.tr : 'closed'.tr,
        'price': '500',
        'distance': distanceText,
        'address': data['address'] ?? 'No address provided',
        'imageUrl': data['logo'] ??
            data['profileImage'] ??
            (data['salonPhotos'] != null && (data['salonPhotos'] as List).isNotEmpty
                ? (data['salonPhotos'] as List).first
                : null),
        'salonPhotos': data['salonPhotos'] ?? [],
        'category': data['category'] ?? 'Haircut',
        'lat': salonLoc?.latitude ?? 0,
        'lng': salonLoc?.longitude ?? 0,
        'showOnMap': data['showOnMap'] ?? true,
      };
    }).toList();
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
                                Obx(() => Text('${userController.userName.value}!', style: AppTextStyles.displayMedium?.copyWith(color: theme.textColor, fontWeight: FontWeight.w800))),
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

                // Categories
                _sectionHeader('categories'.tr, () => widget.onTabChange(1), theme),
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
                      final distA = a['distance'] == 'N/A' ? double.infinity : double.parse((a['distance'] as String).replaceAll(' km', ''));
                      final distB = b['distance'] == 'N/A' ? double.infinity : double.parse((b['distance'] as String).replaceAll(' km', ''));
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
                          onTap: () => Get.to(() => SalonDetailScreen(
                            ownerId: salon['ownerId'],
                            salon: salon,
                          )),
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
}