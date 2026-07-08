import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final List<String> _filters = ['All', 'Haircut', 'Beard', 'Facial', 'Bridal', 'Nails'];
  LatLng? _userLatLng;
  Set<Marker> _markers = {};
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? _mapControllerInstance;

  // Sort options
  String _selectedSort = 'Nearest to Far';
  final List<String> _sortOptions = [
    'Nearest to Far',
    'Far to Nearest',
    'Price: Low to High',
    'Price: High to Low',
    'Rating: High to Low',
    'Rating: Low to High',
  ];

  // Icons for sort options
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

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;
      setState(() {
        _userLatLng = LatLng(pos.latitude, pos.longitude);
      });

      _animateToUserLocation();
    } catch (e) {
      debugPrint('Location initialization error: $e');
    }
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

  Set<Marker> _computeMarkers(List<Map<String, dynamic>> salons) {
    final Set<Marker> markers = {};

    if (_userLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: _userLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: const InfoWindow(title: 'You are here'),
        zIndex: 2.0,
      ));
    }

    for (int i = 0; i < salons.length; i++) {
      final s = salons[i];
      if (s['showOnMap'] == true) {
        markers.add(Marker(
          markerId: MarkerId('salon_${s['ownerId']}'),
          position: LatLng(s['lat'], s['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
          infoWindow: InfoWindow(
            title: s['name'],
            snippet: '${s['distance']}',
          ),
        ));
      }
    }

    return markers;
  }

  List<Map<String, dynamic>> _parseSalons(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final GeoPoint location = data['location'] ?? const GeoPoint(34.0151, 71.5249);

      double distKm = 0.0;
      if (_userLatLng != null) {
        distKm = Geolocator.distanceBetween(
          _userLatLng!.latitude, _userLatLng!.longitude,
          location.latitude, location.longitude,
        ) / 1000;
      }

      // Parse price as double for sorting
      double priceValue = 500.0; // Default
      if (data['price'] != null) {
        final priceStr = data['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
        priceValue = double.tryParse(priceStr) ?? 500.0;
      }

      return {
        'ownerId': doc.id,
        'name': data['salonName'] ?? 'Unnamed Salon',
        'distance': '${distKm.toStringAsFixed(1)} km',
        'distanceValue': distKm,
        'rating': data['rating']?.toDouble() ?? 4.5,
        'status': data['isOpenNow'] == true ? 'Open' : 'Closed',
        'price': data['price'] ?? 'Rs.500',
        'priceValue': priceValue,
        'category': data['category'] ?? 'Haircut',
        'lat': location.latitude,
        'lng': location.longitude,
        'address': data['address'] ?? '',
        'imageUrl': data['salonPhotos'] != null && (data['salonPhotos'] as List).isNotEmpty
            ? (data['salonPhotos'] as List).first : null,
        'showOnMap': data['showOnMap'] ?? false,
      };
    }).toList();
  }

  // Sort salons based on selected option
  List<Map<String, dynamic>> _sortSalons(List<Map<String, dynamic>> salons) {
    List<Map<String, dynamic>> sortedList = List.from(salons);

    switch (_selectedSort) {
      case 'Nearest to Far':
        sortedList.sort((a, b) => (a['distanceValue'] as double).compareTo(b['distanceValue'] as double));
        break;
      case 'Far to Nearest':
        sortedList.sort((a, b) => (b['distanceValue'] as double).compareTo(a['distanceValue'] as double));
        break;
      case 'Price: Low to High':
        sortedList.sort((a, b) => (a['priceValue'] as double).compareTo(b['priceValue'] as double));
        break;
      case 'Price: High to Low':
        sortedList.sort((a, b) => (b['priceValue'] as double).compareTo(a['priceValue'] as double));
        break;
      case 'Rating: High to Low':
        sortedList.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'Rating: Low to High':
        sortedList.sort((a, b) => (a['rating'] as double).compareTo(b['rating'] as double));
        break;
    }

    return sortedList;
  }

  // Show sort bottom sheet
  void _showSortBottomSheet(ThemeHelper theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Title
            Text(
              'Sort By',
              style: AppTextStyles.headingMedium?.copyWith(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Sort options
            ...List.generate(_sortOptions.length, (index) {
              final option = _sortOptions[index];
              final isSelected = _selectedSort == option;

              return InkWell(
                onTap: () {
                  setState(() => _selectedSort = option);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPink.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryPink : theme.borderColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _sortIcons[option],
                        size: 20,
                        color: isSelected ? AppColors.primaryPink : theme.mutedTextColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option,
                        style: AppTextStyles.bodyMedium?.copyWith(
                          color: isSelected ? AppColors.primaryPink : theme.textColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.primaryPink, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text('Find Salons', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('owners').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _markers.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No salons found.', style: TextStyle(color: theme.textColor)));
            }

            final allSalons = _parseSalons(snapshot.data!);
            final markers = _computeMarkers(allSalons);

            // Apply filter and sort
            final filteredSalons = allSalons.where((s) =>
            _selectedFilter == 'All' || s['category'] == _selectedFilter
            ).toList();
            final sortedSalons = _sortSalons(filteredSalons);

            return Column(
              children: [
                // Fixed top section (Search + Filters + Map)
                _buildTopSection(theme, markers, snapshot.connectionState == ConnectionState.waiting),

                // Salon Near You + Sort row
                _buildSortRow(theme, sortedSalons.length),

                // Scrollable salon list
                Expanded(
                  child: _buildSalonList(theme, sortedSalons, snapshot.connectionState == ConnectionState.waiting),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSection(ThemeHelper theme, Set<Marker> markers, bool isLoading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: theme.mutedTextColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search salons...',
                    ),
                    style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor),
                  ),
                ),
                Icon(Icons.tune_rounded, color: AppColors.primaryPink, size: 20),
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
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final selected = _selectedFilter == _filters[index];
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = _filters[index]),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryPink : theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? AppColors.primaryPink : theme.borderColor),
                  ),
                  child: Center(
                    child: Text(
                      _filters[index],
                      style: AppTextStyles.label.copyWith(
                        color: selected ? Colors.white : theme.mutedTextColor,
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

  // Sort row widget
  Widget _buildSortRow(ThemeHelper theme, int salonCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Salon Near You text with count
          Row(
            children: [
              Text(
                'Salon Near You',
                style: AppTextStyles.headingSmall?.copyWith(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$salonCount',
                  style: AppTextStyles.label?.copyWith(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Sort button
          GestureDetector(
            onTap: () => _showSortBottomSheet(theme),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_vert,
                    size: 16,
                    color: theme.mutedTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: AppTextStyles.label?.copyWith(
                      color: theme.mutedTextColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: theme.mutedTextColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonList(ThemeHelper theme, List<Map<String, dynamic>> sortedSalons, bool isLoading) {
    if (isLoading && sortedSalons.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
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