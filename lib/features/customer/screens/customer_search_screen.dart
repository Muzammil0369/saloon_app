import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/controllers/language_controller.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/salon_detail_screen.dart';
import 'package:saloon_app/shared/widgets/salon_card.dart';

/// Dedicated search flow opened from the customer home search bar.
///   Step 1: browse state (popular services + popular searches) before typing
///   Step 2: results split into Salons / Services / Staff tabs
///   Step 3: tapping a result opens the salon detail page
class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  late final TabController _tabs;
  Timer? _debounce;

  bool _loading = true;
  String _query = '';
  List<Map<String, dynamic>> _salons = [];

  static const List<String> _popularServices = [
    'Haircut',
    'Beard Trim',
    'Facial',
    'Hair Color',
    'Massage',
    'Bridal Makeup',
    'Shave',
    'Manicure',
  ];

  static const List<String> _popularSearches = [
    'Haircut',
    'Facial',
    'Bridal',
    'Beard',
    'Spa',
    'Threading',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadSalons();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    _tabs.dispose();
    super.dispose();
  }

  // ---------- Data ----------

  Future<void> _loadSalons() async {
    try {
      Position? pos;
      try {
        if (await Geolocator.isLocationServiceEnabled()) {
          final perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse) {
            pos = await Geolocator.getLastKnownPosition();
          }
        }
      } catch (_) {}

      final snap = await FirebaseFirestore.instance.collection('owners').get();
      final isUr = Get.find<LanguageController>().languageCode.value == 'ur';

      final list = snap.docs.map((doc) {
        final data = doc.data();
        final GeoPoint loc = data['location'] is GeoPoint
            ? data['location'] as GeoPoint
            : const GeoPoint(34.0151, 71.5249);

        String distance = 'N/A';
        if (pos != null) {
          final km = Geolocator.distanceBetween(
              pos.latitude, pos.longitude, loc.latitude, loc.longitude) /
              1000;
          distance = '${km.toStringAsFixed(1)} km';
        }

        final services = ((data['services'] as List<dynamic>?) ?? [])
            .whereType<Map>()
            .map((s) => {
          'name': (s['name'] ?? '').toString(),
          'price': s['price'],
        })
            .where((s) => (s['name'] as String).isNotEmpty)
            .toList();

        final workers = ((data['workers'] as List<dynamic>?) ?? [])
            .whereType<Map>()
            .map((w) => {
          'name': (w['name'] ?? '').toString(),
          'imageUrl': w['profileImage'],
          'rating': (w['rating'] ?? 0).toDouble(),
        })
            .where((w) => (w['name'] as String).isNotEmpty)
            .toList();

        final photos = data['salonPhotos'];
        final ownerName =
        (data['ownerName'] ?? data['fullName'] ?? '').toString();
        return <String, dynamic>{
          'ownerId': doc.id,
          'name': isUr
              ? (data['salonName_ur'] ?? data['salonName'] ?? 'Unnamed Salon')
              : (data['salonName'] ?? 'Unnamed Salon'),
          'rating': (data['rating'] ?? 4.5).toDouble(),
          'reviewCount': data['reviewCount'] ?? 0,
          'status': data['isOpenNow'] == true ? 'open'.tr : 'closed'.tr,
          'price': data['price'] ?? 'Rs.500',
          'distance': distance,
          'address': data['address'] ?? '',
          'category': data['category'] ?? 'Haircut',
          'imageUrl': data['logo'] ??
              data['profileImage'] ??
              ((photos is List && photos.isNotEmpty) ? photos.first : null),
          'services': services,
          'workers': [
            if (ownerName.isNotEmpty)
              {
                'name': ownerName,
                'imageUrl': data['ownerProfileImage'],
                'rating': (data['ownerStaffRating'] ?? 0).toDouble(),
              },
            ...workers,
          ],
          'ownerName': data['ownerName'],
          'ownerProfileImage': data['ownerProfileImage'],
          'phoneNumber': data['phoneNumber'],
          'businessHours': data['businessHours'],
          'hasCoworkers': data['hasCoworkers'],
          'rawWorkers': data['workers'],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _salons = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Search load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _searchFor(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _debounce?.cancel();
    setState(() => _query = text.trim());
    _focus.unfocus();
  }

  // ---------- Helpers ----------

  /// Staff/salon photos are stored either as http URLs or base64 data URIs.
  ImageProvider? _imageProvider(dynamic raw) {
    final url = raw?.toString() ?? '';
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return CachedNetworkImageProvider(url);
    if (url.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(url.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Fade + slide-up entrance, staggered by list position.
  Widget _entrance(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index.clamp(0, 8) * 60)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: c),
      ),
      child: child,
    );
  }

  // ---------- Matching ----------

  bool _has(String? source, String q) =>
      (source ?? '').toLowerCase().contains(q.toLowerCase());

  List<Map<String, dynamic>> get _matchingSalons {
    if (_query.isEmpty) return [];
    return _salons.where((s) {
      if (_has(s['name'] as String?, _query)) return true;
      if (_has(s['category'] as String?, _query)) return true;
      return (s['services'] as List)
          .any((sv) => _has(sv['name'] as String?, _query));
    }).toList();
  }

  /// Aggregated by service name: how many salons offer it + lowest price.
  List<Map<String, dynamic>> get _matchingServices {
    if (_query.isEmpty) return [];
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final salon in _salons) {
      for (final sv in (salon['services'] as List)) {
        final name = sv['name'] as String;
        if (!_has(name, _query)) continue;
        final key = name.toLowerCase();
        final price = num.tryParse(
            (sv['price'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), ''));
        final entry = grouped.putIfAbsent(
            key, () => {'name': name, 'count': 0, 'minPrice': null});
        entry['count'] = (entry['count'] as int) + 1;
        if (price != null) {
          final current = entry['minPrice'] as num?;
          if (current == null || price < current) entry['minPrice'] = price;
        }
      }
    }
    final result = grouped.values.toList();
    result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return result;
  }

  List<Map<String, dynamic>> get _matchingStaff {
    if (_query.isEmpty) return [];
    final List<Map<String, dynamic>> result = [];
    for (final salon in _salons) {
      for (final w in (salon['workers'] as List)) {
        if (_has(w['name'] as String?, _query)) {
          result.add({
            'name': w['name'],
            'imageUrl': w['imageUrl'],
            'rating': w['rating'],
            'salonName': salon['name'],
            'ownerId': salon['ownerId'],
            'salon': salon,
          });
        }
      }
    }
    return result;
  }

  void _openSalon(Map<String, dynamic> salon) {
    Get.to(() => SalonDetailScreen(
      ownerId: salon['ownerId'],
      salon: salon,
      initialQuery: _query,
    ));
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final hasQuery = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textColor),
        titleSpacing: 0,
        title: _buildSearchField(theme),
        bottom: hasQuery
            ? TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryPink,
          unselectedLabelColor: theme.mutedTextColor,
          indicatorColor: AppColors.primaryPink,
          tabs: [
            Tab(text: 'salons'.tr),
            Tab(text: 'services'.tr),
            Tab(text: 'staff'.tr),
          ],
        )
            : null,
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink))
          : hasQuery
          ? TabBarView(
        controller: _tabs,
        children: [
          _buildSalonsTab(theme),
          _buildServicesTab(theme),
          _buildStaffTab(theme),
        ],
      )
          : _buildBrowse(theme),
    );
  }

  Widget _buildSearchField(ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.lightPinkColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.primaryPink, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodyMedium.copyWith(color: theme.textColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'search_hint'.tr,
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: theme.mutedTextColor),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                _debounce?.cancel();
                setState(() => _query = '');
              },
              child: Icon(Icons.close_rounded,
                  color: theme.mutedTextColor, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildBrowse(ThemeHelper theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('popular_services'.tr,
            style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < _popularServices.length; i++)
              _entrance(i,
                  _chip(_popularServices[i], theme, Icons.content_cut_rounded)),
          ],
        ),
        const SizedBox(height: 28),
        Text('popular_searches'.tr,
            style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
        const SizedBox(height: 8),
        ..._popularSearches.map((s) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.trending_up_rounded,
              color: theme.mutedTextColor, size: 20),
          title: Text(s,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: theme.textColor)),
          onTap: () => _searchFor(s),
        )),
      ],
    );
  }

  Widget _chip(String label, ThemeHelper theme, IconData icon) {
    return GestureDetector(
      onTap: () => _searchFor(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryPink),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalonsTab(ThemeHelper theme) {
    final results = _matchingSalons;
    if (results.isEmpty) return _emptyState('no_salons_found'.tr, theme);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (_, i) => _entrance(
        i,
        SalonCard(
          salon: results[i],
          onTap: () => _openSalon(results[i]),
        ),
      ),
    );
  }

  Widget _buildServicesTab(ThemeHelper theme) {
    final results = _matchingServices;
    if (results.isEmpty) return _emptyState('no_services_found'.tr, theme);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = results[i];
        final minPrice = r['minPrice'];
        return _entrance(i, Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Show salons offering this service
              _searchFor(r['name'] as String);
              _tabs.animateTo(0);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.lightPinkColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.content_cut_rounded,
                        color: AppColors.primaryPink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'] as String,
                            style: AppTextStyles.bodyLarge.copyWith(
                                color: theme.textColor,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${'offered_by'.tr} ${r['count']} ${'salons_lowercase'.tr}'
                              '${minPrice != null ? ' • ${'from'.tr} Rs.$minPrice' : ''}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: theme.mutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: theme.mutedTextColor),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  Widget _buildStaffTab(ThemeHelper theme) {
    final results = _matchingStaff;
    if (results.isEmpty) return _emptyState('no_staff_found'.tr, theme);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = results[i];
        final img = r['imageUrl'];
        final rating = (r['rating'] as num).toDouble();
        return _entrance(i, Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openSalon(r['salon'] as Map<String, dynamic>),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [AppColors.primaryPink, Color(0xFFFF9A9E)]),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.lightPinkColor,
                      backgroundImage: _imageProvider(img),
                      child: _imageProvider(img) != null
                          ? null
                          : const Icon(Icons.person,
                          color: AppColors.primaryPink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'] as String,
                            style: AppTextStyles.bodyLarge.copyWith(
                                color: theme.textColor,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${'at'.tr} ${r['salonName']}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: theme.mutedTextColor)),
                      ],
                    ),
                  ),
                  if (rating > 0) ...[
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 2),
                    Text(rating.toStringAsFixed(1),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: theme.textColor)),
                  ],
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  Widget _emptyState(String message, ThemeHelper theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: theme.mutedTextColor),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.mutedTextColor)),
          ],
        ),
      ),
    );
  }
}


/// Premium open animation: fade + gentle scale-up + slide from the search bar.
Route<T> searchRoute<T>() {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => const CustomerSearchScreen(),
    transitionsBuilder: (_, animation, __, child) {
      final curved =
      CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      final fade =
      CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
              .animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}