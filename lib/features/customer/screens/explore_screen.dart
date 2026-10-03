import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/controllers/language_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../shared/widgets/salon_card.dart';
import 'salon_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final List<String> _filters = ['All', 'Haircut', 'Beard', 'Facial', 'Bridal', 'Nails'];

  final Set<String> _selectedPriceTiers = {};
  bool _offersOnly = false;
  Set<String> _ownerIdsWithActiveOffers = {};

  Timer? _searchDebounce;

  LatLng? _userLatLng;
  Set<Marker> _markers = {};
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? _mapControllerInstance;
  final TextEditingController _searchController = TextEditingController();

  // ---- Hoisted Firestore state (moved OUT of build) ----
  List<Map<String, dynamic>> _allSalons = [];
  bool _loadingSalons = true;
  StreamSubscription<QuerySnapshot>? _ownersSub;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadActiveOffers();
    _listenToOwners();
  }

  @override
  void dispose() {
    _ownersSub?.cancel();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Sort options - Using hardcoded values for switch cases
  String _selectedSort = 'Rating: High to Low';
  final List<String> _sortOptions = [
    'Nearest to Far',
    'Far to Nearest',
    'Price: Low to High',
    'Price: High to Low',
    'Rating: High to Low',
    'Rating: Low to High',
  ];

  final Map<String, IconData> _sortIcons = {
    'Nearest to Far': Icons.near_me,
    'Far to Nearest': Icons.airplanemode_active,
    'Price: Low to High': Icons.trending_up,
    'Price: High to Low': Icons.trending_down,
    'Rating: High to Low': Icons.star,
    'Rating: Low to High': Icons.star_border,
  };

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(34.0151, 71.5249),
    zoom: 13,
  );

  // ---------- Firestore stream (isolated) ----------

  void _listenToOwners() {
    _ownersSub = FirebaseFirestore.instance
        .collection('owners')
        .snapshots()
        .listen((snapshot) {
      final parsed = _parseSalons(snapshot);
      final newMarkers = _computeMarkers(parsed);
      if (!mounted) return;
      setState(() {
        _allSalons = parsed;
        _markers = newMarkers;
        _loadingSalons = false;
      });
    }, onError: (e) {
      debugPrint('owners stream error: $e');
      if (mounted) setState(() => _loadingSalons = false);
    });
  }

  Future<void> _loadActiveOffers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ads')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();
      if (mounted) {
        setState(() => _ownerIdsWithActiveOffers =
            snapshot.docs.map((d) => d.id).toSet());
      }
    } catch (e) {
      debugPrint('Error loading active offers: $e');
    }
  }

  String _priceTierFor(double price) {
    if (price < 500) return '\$';
    if (price < 1500) return '\$\$';
    return '\$\$\$';
  }

  // ---------- Location ----------

  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;
      setState(() {
        _userLatLng = LatLng(pos.latitude, pos.longitude);
      });

      // Recompute distances now that we know where the user is.
      if (_allSalons.isNotEmpty) {
        final reparsed = _recomputeDistances(_allSalons);
        setState(() {
          _allSalons = reparsed;
          _markers = _computeMarkers(reparsed);
        });
      }

      _animateToUserLocation();
    } catch (e) {
      debugPrint('Location initialization error: $e');
    }
  }

  List<Map<String, dynamic>> _recomputeDistances(
      List<Map<String, dynamic>> salons) {
    if (_userLatLng == null) return salons;
    return salons.map((s) {
      final distKm = Geolocator.distanceBetween(
        _userLatLng!.latitude,
        _userLatLng!.longitude,
        s['lat'] as double,
        s['lng'] as double,
      ) /
          1000;
      return {
        ...s,
        'distance': '${distKm.toStringAsFixed(1)} km',
        'distanceValue': distKm,
      };
    }).toList();
  }

  Future<void> _animateToUserLocation() async {
    if (_userLatLng == null || _mapControllerInstance == null) return;
    try {
      _mapControllerInstance!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLatLng!, zoom: 14),
      ));
    } catch (e) {
      debugPrint('Map animation error: $e');
    }
  }

  // ---------- Parsing / markers ----------

  Set<Marker> _computeMarkers(List<Map<String, dynamic>> salons) {
    final Set<Marker> markers = {};

    if (_userLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: _userLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(title: 'you_are_here'.tr),
        zIndex: 2.0,
      ));
    }

    for (final s in salons) {
      if (s['showOnMap'] == true) {
        markers.add(Marker(
          markerId: MarkerId('salon_${s['ownerId']}'),
          position: LatLng(s['lat'] as double, s['lng'] as double),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueMagenta),
          infoWindow: InfoWindow(
            title: s['name'] as String,
            snippet: s['distance'] as String,
          ),
        ));
      }
    }

    return markers;
  }

  List<Map<String, dynamic>> _parseSalons(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final GeoPoint location =
          data['location'] ?? const GeoPoint(34.0151, 71.5249);

      double distKm = 0.0;
      if (_userLatLng != null) {
        distKm = Geolocator.distanceBetween(
          _userLatLng!.latitude,
          _userLatLng!.longitude,
          location.latitude,
          location.longitude,
        ) /
            1000;
      }

      double priceValue = 500.0;
      if (data['price'] != null) {
        final priceStr =
        data['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
        priceValue = double.tryParse(priceStr) ?? 500.0;
      }

      return {
        'ownerId': doc.id,
        'name': Get.find<LanguageController>().languageCode.value == 'ur'
            ? (data['salonName_ur'] ?? data['salonName'] ?? 'Unnamed Salon')
            : (data['salonName'] ?? 'Unnamed Salon'),
        'distance': '${distKm.toStringAsFixed(1)} km',
        'distanceValue': distKm,
        'rating': data['rating']?.toDouble() ?? 4.5,
        'reviewCount': data['reviewCount'] ?? 0,
        'status': data['isOpenNow'] == true ? 'open'.tr : 'closed'.tr,
        'price': data['price'] ?? 'Rs.500',
        'priceValue': priceValue,
        'category': data['category'] ?? 'Haircut',
        'lat': location.latitude,
        'lng': location.longitude,
        'address': data['address'] ?? '',
        'imageUrl': data['logo'] ??
            data['profileImage'] ??
            (data['salonPhotos'] != null &&
                (data['salonPhotos'] as List).isNotEmpty
                ? (data['salonPhotos'] as List).first
                : null),
        'showOnMap': data['showOnMap'] ?? false,
        'services': (data['services'] as List<dynamic>?)
            ?.map((s) => (s['name'] ?? '').toString().toLowerCase())
            .toList() ??
            [],
      };
    }).toList();
  }

  // ---------- Filtering / sorting ----------

  List<Map<String, dynamic>> _applyFiltersAndSort() {
    final filtered = _allSalons.where((s) {
      final services = s['services'] as List<String>;
      final matchesSearch = _searchQuery.isEmpty ||
          (s['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          services.any((service) => service.contains(_searchQuery.toLowerCase()));
      final matchesFilter = _selectedFilter == 'All' ||
          services.contains(_selectedFilter.toLowerCase());
      final matchesPrice = _selectedPriceTiers.isEmpty ||
          _selectedPriceTiers.contains(_priceTierFor(s['priceValue'] as double));
      final matchesOffers = !_offersOnly ||
          _ownerIdsWithActiveOffers.contains(s['ownerId']);
      return matchesSearch && matchesFilter && matchesPrice && matchesOffers;
    }).toList();

    return _sortSalons(filtered);
  }

  List<Map<String, dynamic>> _sortSalons(List<Map<String, dynamic>> salons) {
    final sortedList = List<Map<String, dynamic>>.from(salons);

    switch (_selectedSort) {
      case 'Nearest to Far':
        sortedList.sort((a, b) =>
            (a['distanceValue'] as double).compareTo(b['distanceValue'] as double));
        break;
      case 'Far to Nearest':
        sortedList.sort((a, b) =>
            (b['distanceValue'] as double).compareTo(a['distanceValue'] as double));
        break;
      case 'Price: Low to High':
        sortedList.sort((a, b) =>
            (a['priceValue'] as double).compareTo(b['priceValue'] as double));
        break;
      case 'Price: High to Low':
        sortedList.sort((a, b) =>
            (b['priceValue'] as double).compareTo(a['priceValue'] as double));
        break;
      case 'Rating: High to Low':
        sortedList.sort((a, b) =>
            (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'Rating: Low to High':
        sortedList.sort((a, b) =>
            (a['rating'] as double).compareTo(b['rating'] as double));
        break;
    }

    return sortedList;
  }

  // ---------- Sort sheet ----------

  void _showSortBottomSheet(ThemeHelper theme) {
    final List<String> translatedOptions = _sortOptions.map((option) {
      switch (option) {
        case 'Nearest to Far':
          return 'sort_nearest'.tr;
        case 'Far to Nearest':
          return 'sort_far'.tr;
        case 'Price: Low to High':
          return 'sort_price_low'.tr;
        case 'Price: High to Low':
          return 'sort_price_high'.tr;
        case 'Rating: High to Low':
          return 'sort_rating_high'.tr;
        case 'Rating: Low to High':
          return 'sort_rating_low'.tr;
        default:
          return option;
      }
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'sort_by'.tr,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(translatedOptions.length, (index) {
                  final option = translatedOptions[index];
                  final isSelected = _selectedSort == _sortOptions[index];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSort = _sortOptions[index];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryPink.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryPink
                              : theme.borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sortIcons[_sortOptions[index]],
                            size: 20,
                            color: isSelected
                                ? AppColors.primaryPink
                                : theme.mutedTextColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            option,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryPink
                                  : theme.textColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: AppColors.primaryPink, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Text('price'.tr,
                    style: AppTextStyles.headingMedium.copyWith(
                        color: theme.textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: ['\$', '\$\$', '\$\$\$'].map((tier) {
                    final isSelected = _selectedPriceTiers.contains(tier);
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(tier),
                        selected: isSelected,
                        selectedColor: AppColors.primaryPink,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) => setModalState(() {
                          if (selected) {
                            _selectedPriceTiers.add(tier);
                          } else {
                            _selectedPriceTiers.remove(tier);
                          }
                        }),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text('offers'.tr,
                    style: AppTextStyles.headingMedium.copyWith(
                        color: theme.textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: _offersOnly,
                  onChanged: (value) =>
                      setModalState(() => _offersOnly = value ?? false),
                  title: Text('has_active_offer'.tr,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: theme.textColor)),
                  activeColor: AppColors.primaryPink,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('apply'.tr,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final sortedSalons = _applyFiltersAndSort();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('find_salons'.tr,
            style: AppTextStyles.headingLarge
                .copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(theme, _markers, _loadingSalons),
            _buildSortRow(theme, sortedSalons.length),
            Expanded(
              child: _buildSalonList(
                theme,
                sortedSalons,
                _loadingSalons,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(
      ThemeHelper theme, Set<Marker> markers, bool isLoading) {
    final List<String> translatedFilters = _filters.map((filter) {
      switch (filter) {
        case 'All':
          return 'all'.tr;
        case 'Haircut':
          return 'haircut'.tr;
        case 'Beard':
          return 'beard'.tr;
        case 'Facial':
          return 'facial'.tr;
        case 'Bridal':
          return 'bridal'.tr;
        case 'Nails':
          return 'nails'.tr;
        default:
          return filter;
      }
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: theme.mutedTextColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce =
                          Timer(const Duration(milliseconds: 400), () {
                            if (mounted && _searchQuery != value) {
                              setState(() => _searchQuery = value);
                            }
                          });
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'search_hint'.tr,
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: theme.mutedTextColor),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: theme.textColor),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close,
                        color: theme.mutedTextColor, size: 18),
                  )
                else
                  const Icon(Icons.tune_rounded,
                      color: AppColors.primaryPink, size: 20),
              ],
            ),
          ),
        ),

        // Filter chips
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: translatedFilters.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilter == _filters[index];
              final label = translatedFilters[index];
              return GestureDetector(
                onTap: () {
                  if (_selectedFilter != _filters[index]) {
                    setState(() => _selectedFilter = _filters[index]);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPink
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.primaryPink
                            : theme.borderColor),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppTextStyles.label.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.mutedTextColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Map
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              child: GoogleMap(
                key: const ValueKey('explore_map'),
                initialCameraPosition: _userLatLng != null
                    ? CameraPosition(target: _userLatLng!, zoom: 14)
                    : _defaultPosition,
                markers: markers,
                onMapCreated: (controller) {
                  _mapControllerInstance = controller;
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                  }
                  _animateToUserLocation();
                },
                myLocationEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortRow(ThemeHelper theme, int salonCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'salon_near_you'.tr,
                style: AppTextStyles.headingSmall.copyWith(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$salonCount',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _showSortBottomSheet(theme),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert,
                      size: 16, color: theme.mutedTextColor),
                  const SizedBox(width: 4),
                  Text('sort'.tr,
                      style: AppTextStyles.label
                          .copyWith(color: theme.mutedTextColor)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down,
                      size: 16, color: theme.mutedTextColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonList(ThemeHelper theme,
      List<Map<String, dynamic>> sortedSalons, bool isLoading) {
    if (isLoading && sortedSalons.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }

    if (sortedSalons.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 300));
        },
        color: AppColors.primaryPink,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(
                  'no_salons'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      color: AppColors.primaryPink,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: sortedSalons.length,
        itemBuilder: (context, index) {
          final salon = sortedSalons[index];
          return SalonCard(
            salon: salon,
            onTap: () => Get.to(() => SalonDetailScreen(
              ownerId: salon['ownerId'],
              salon: salon,
            )),
          );
        },
      ),
    );
  }
}