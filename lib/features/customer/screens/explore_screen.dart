import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
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
  // ── State ──
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Haircut', 'Beard', 'Facial', 'Bridal', 'Nails'];
  final List<Map<String, dynamic>> _salons = [];
  bool _isLoading = true;
  String? _errorMessage;
  LatLng? _userLatLng;
  Set<Marker> _markers = {};
  final Completer<GoogleMapController> _mapController = Completer();

  // TomTom API key
  static const String _apiKey = 'ymqyPupk68qNc0xwvAiOPUeW5fHcAMnq';

  // Default camera — Peshawar
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(34.0151, 71.5249),
    zoom: 13,
  );

  // Fallback local salons removed — only real Firestore data is now used.

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ── Get real user location ──
  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!await Geolocator.isLocationServiceEnabled()) {
        _loadFallback('Location services disabled');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _loadFallback('Location permission denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _userLatLng = LatLng(pos.latitude, pos.longitude));

      try {
        final ctrl = await _mapController.future
            .timeout(const Duration(seconds: 5));
        ctrl.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLatLng!, zoom: 14),
        ));
      } catch (e) {
        debugPrint('Map controller timeout: $e');
      }

      await _fetchSalonsFromFirestore();

    } catch (e) {
      debugPrint('Location error: $e');
      _loadFallback('Could not get location');
    }
  }

  Future<void> _fetchSalonsFromFirestore() async {
    try {
      // Ensure we have user location before fetching
      if (_userLatLng == null) await _initLocation();
      if (_userLatLng == null) return;

      final snapshot = await FirebaseFirestore.instance.collection('owners').get();
      
      final List<Map<String, dynamic>> salons = snapshot.docs.map((doc) {
        final data = doc.data();
        final GeoPoint location = data['location'];
        
        // Calculate real distance
        final double distInMeters = Geolocator.distanceBetween(
          _userLatLng!.latitude, _userLatLng!.longitude,
          location.latitude, location.longitude,
        );
        final double distKm = distInMeters / 1000;

        return {
          'name': data['salonName'] ?? 'Unnamed Salon',
          'distance': '${distKm.toStringAsFixed(1)} km',
          'distanceValue': distKm,
          'rating': data['rating']?.toDouble() ?? 4.5,
          'status': data['isOpenNow'] == true ? 'Open' : 'Closed',
          'price': 'Rs.500', 
          'category': 'Haircut',
          'lat': location.latitude,
          'lng': location.longitude,
          'address': data['address'] ?? '',
        };
      }).toList();

      // Sort by distance
      salons.sort((a, b) => (a['distanceValue'] as double).compareTo(b['distanceValue'] as double));

      if (mounted) {
        setState(() {
          _salons.clear();
          _salons.addAll(salons);
          _isLoading = false;
        });
        _addMarkers();
      }
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helper methods removed as fallback is no longer used ──

  void _loadFallback(String error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
      _addMarkers();
    }
  }

  void _finishLoading() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      _addMarkers();
    }
  }

  // ── Add markers to map ──
  void _addMarkers() {
    final Set<Marker> markers = {};

    // user marker
    if (_userLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: _userLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRose),
        infoWindow: const InfoWindow(title: 'You are here'),
      ));
    }

    // salon markers
    for (int i = 0; i < _salons.length; i++) {
      final s = _salons[i];
      markers.add(Marker(
        markerId: MarkerId('salon_$i'),
        position: LatLng(s['lat'], s['lng']),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueMagenta),
        infoWindow: InfoWindow(
          title: s['name'],
          snippet: '${s['distance']} · ${s['price']}',
        ),
        onTap: () {
          // scroll to this salon later
        },
      ));
    }

    setState(() => _markers = markers);
  }

  // ── Jump map to salon ──
  Future<void> _focusSalon(double lat, double lng) async {
    final ctrl = await _mapController.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(lat, lng), zoom: 16),
    ));
  }

  // ── Filtered list ──
  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 'All') return _salons;
    return _salons
        .where((s) => s['category'] == _selectedFilter)
        .toList();
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
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
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
                          Icon(Icons.search_rounded,
                              color: theme.mutedTextColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                fillColor: Colors.transparent,
                                hintText: 'Search salons or services...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor)
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: theme.lightPinkColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded,
                                color: AppColors.primaryPink, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),

            // ── Filter chips ──
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(
                  left: 20, right: 20, bottom: 14),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final selected = _selectedFilter == _filters[index];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFilter = _filters[index]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryPink
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryPink
                                : theme.borderColor,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: AppTextStyles.label.copyWith(
                              color: selected
                                  ? theme.cardColor
                                  : theme.mutedTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: Column(
                children: [
                  // salon count
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_filtered.length} Salons Nearby',
                          style: AppTextStyles.headingSmall.copyWith(color: theme.textColor),
                        ),
                        if (_errorMessage != null)
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 13, color: theme.mutedTextColor),
                              const SizedBox(width: 4),
                              Text('Showing local data', style: AppTextStyles.label),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // ── Google Map ──
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
                          markers: _markers,
                          onMapCreated: (c) => _mapController.complete(c),
                          myLocationEnabled: false,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: true,
                          scrollGesturesEnabled: true,
                          zoomGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // results header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Results (${_filtered.length})',
                          style: AppTextStyles.headingSmall.copyWith(color: theme.textColor),
                        ),
                        Row(
                          children: [
                            Icon(Icons.sort_rounded, size: 16, color: theme.mutedTextColor),
                            const SizedBox(width: 4),
                            Text('Sort', style: AppTextStyles.linkText),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // salon list - THIS IS THE SCROLLABLE PART
                  Expanded(
                    child: _isLoading
                        ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryPink),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final salon = _filtered[index];
                        return SalonCard(
                          salon: salon,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SalonDetailScreen(salon: salon),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}