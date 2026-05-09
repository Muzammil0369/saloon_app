import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_helper.dart';

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

  // Fallback local salons when API fails
  final List<Map<String, dynamic>> _localSalons = [
    {'name': 'Hair Focus Salon',      'distance': '1.2 km', 'distanceValue': 1.2, 'rating': 4.5, 'status': 'Open',   'price': 'Rs.500',   'category': 'Haircut', 'lat': 34.0100, 'lng': 71.5600},
    {'name': 'Gents Hair Salon',      'distance': '1.5 km', 'distanceValue': 1.5, 'rating': 4.3, 'status': 'Open',   'price': 'Rs.300',   'category': 'Beard',   'lat': 34.0050, 'lng': 71.5400},
    {'name': 'New Look Beauty Parlor','distance': '2.0 km', 'distanceValue': 2.0, 'rating': 4.6, 'status': 'Open',   'price': 'Rs.800',   'category': 'Facial',  'lat': 33.9900, 'lng': 71.5550},
    {'name': 'Royal Barbers',         'distance': '2.5 km', 'distanceValue': 2.5, 'rating': 4.4, 'status': 'Open',   'price': 'Rs.400',   'category': 'Haircut', 'lat': 34.0200, 'lng': 71.5350},
    {'name': 'Golden Scissors',       'distance': '2.8 km', 'distanceValue': 2.8, 'rating': 4.2, 'status': 'Closed', 'price': 'Rs.350',   'category': 'Haircut', 'lat': 33.9980, 'lng': 71.5500},
    {'name': 'Elite Hair Studio',     'distance': '3.2 km', 'distanceValue': 3.2, 'rating': 4.7, 'status': 'Open',   'price': 'Rs.1,000', 'category': 'Bridal',  'lat': 34.0300, 'lng': 71.5450},
    {'name': 'Star Beauty Salon',     'distance': '3.5 km', 'distanceValue': 3.5, 'rating': 4.1, 'status': 'Open',   'price': 'Rs.450',   'category': 'Facial',  'lat': 33.9950, 'lng': 71.5420},
    {'name': 'Modern Cuts',           'distance': '4.0 km', 'distanceValue': 4.0, 'rating': 4.8, 'status': 'Open',   'price': 'Rs.700',   'category': 'Haircut', 'lat': 34.0150, 'lng': 71.5700},
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ── Get real user location ──
  Future<void> _initLocation() async {
    debugPrint('=== _initLocation started ===');
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location enabled: $enabled');
      // check service
      if (!await Geolocator.isLocationServiceEnabled()) {
        _loadFallback('Location services disabled');
        return;
      }

      // check permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _loadFallback('Location permission denied');
        return;
      }

      // get position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _userLatLng = LatLng(pos.latitude, pos.longitude));

      // move camera to user
      try {
        final ctrl = await _mapController.future
            .timeout(const Duration(seconds: 5));
        ctrl.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLatLng!, zoom: 14),
        ));
      } catch (e) {
        debugPrint('Map controller timeout: $e');
      }

      // fetch from API — if fails use local
      await _fetchFromApi(pos);

    } catch (e) {
      debugPrint('Location error: $e');
      _loadFallback('Could not get location');
    }
  }

  // ── TomTom API — tries 3 queries ──
  Future<void> _fetchFromApi(Position pos) async {
    final queries = ['salon', 'barber', 'beauty parlour'];

    for (final query in queries) {
      try {
        final url = Uri.parse(
          'https://api.tomtom.com/search/2/search/\${Uri.encodeComponent(query)}.json'
              '?lat=\${pos.latitude}&lon=\${pos.longitude}'
              '&radius=10000&limit=15&key=\$_apiKey',
        );

        debugPrint('TomTom query: \$query');
        final res = await http.get(url).timeout(const Duration(seconds: 10));
        debugPrint('Status: \${res.statusCode}');

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final results = data['results'] as List?;
          debugPrint('Found: \${results?.length ?? 0} for \$query');

          if (results != null && results.isNotEmpty) {
            for (final r in results) {
              final pos2   = r['position'];
              final addr   = r['address'];
              final name   = r['poi']?['name'] ?? 'Salon';

              // skip duplicates
              if (_salons.any((s) => s['name'] == name)) continue;

              // dist comes as int or double — use num cast
              final distRaw    = r['dist'];
              final distMeters = distRaw != null
                  ? (distRaw as num).toDouble()
                  : Geolocator.distanceBetween(
                pos.latitude, pos.longitude,
                (pos2?['lat'] as num?)?.toDouble() ?? pos.latitude,
                (pos2?['lon'] as num?)?.toDouble() ?? pos.longitude,
              );

              final distKm = distMeters / 1000;

              _salons.add({
                'name':          name,
                'distance':      '\${distKm.toStringAsFixed(1)} km',
                'distanceValue': distKm,
                'rating':        4.0 + (_salons.length % 10) * 0.1,
                'status':        'Open',
                'price':         'Rs.500',
                'category':      'Haircut',
                'lat':           (pos2?['lat'] as num?)?.toDouble() ?? pos.latitude,
                'lng':           (pos2?['lon'] as num?)?.toDouble() ?? pos.longitude,
                'address':       addr?['freeformAddress'] ?? '',
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Query error (\$query): \$e');
      }
    }

    if (_salons.isNotEmpty) {
      _salons.sort((a, b) =>
          (a['distanceValue'] as double).compareTo(b['distanceValue'] as double));
      _finishLoading();
    } else {
      debugPrint('All queries failed — using local fallback');
      _loadFallbackWithRealDistance(pos);
    }
  }

  // ── Load fallback with real distance calculation ──
  void _loadFallbackWithRealDistance(Position userPos) {
    _salons.clear();
    for (final s in _localSalons) {
      // calculate real distance from user position
      final realDist = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        s['lat'],
        s['lng'],
      ) / 1000;

      _salons.add({
        ...s,
        'distance':      '${realDist.toStringAsFixed(1)} km',
        'distanceValue': realDist,
      });
    }
    // sort by real distance
    _salons.sort((a, b) =>
        (a['distanceValue'] as double)
            .compareTo(b['distanceValue'] as double));
    _finishLoading();
  }

  void _loadFallback(String error) {
    _salons.addAll(_localSalons);
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
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    // salon count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 16, 20, 10),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_filtered.length} Salons Nearby',
                            style: AppTextStyles.headingSmall.copyWith(color: theme.textColor),
                          ),
                          if (_errorMessage != null)
                            Row(
                              children: [
                                Icon(
                                    Icons.info_outline_rounded,
                                    size: 13,
                                    color: theme.mutedTextColor),
                                const SizedBox(width: 4),
                                Text('Showing local data',
                                    style: AppTextStyles.label),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // ── Google Map ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 180,
                          child: GoogleMap(
                            initialCameraPosition: _userLatLng != null
                                ? CameraPosition(
                                target: _userLatLng!, zoom: 14)
                                : _defaultPosition,
                            markers: _markers,
                            onMapCreated: (c) =>
                                _mapController.complete(c),
                            myLocationEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // results header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Results (${_filtered.length})',
                              style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                          Row(
                            children: [
                              Icon(Icons.sort_rounded,
                                  size: 16,
                                  color: theme.mutedTextColor),
                              const SizedBox(width: 4),
                              Text('Sort',
                                  style: AppTextStyles.linkText),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // salon list
                    _isLoading
                        ? Padding(
                          padding: const EdgeInsets.only(top: 140),
                          child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryPink)),
                        )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final salon = _filtered[index];
                        return GestureDetector(
                          onTap: () => _focusSalon(
                              salon['lat'], salon['lng']),
                          child: Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius:
                              BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPink
                                      .withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // thumb
                                Container(
                                  height: 68,
                                  width: 68,
                                  decoration: BoxDecoration(
                                    color: theme.lightPinkColor,
                                    borderRadius:
                                    BorderRadius.circular(
                                        14),
                                  ),
                                  child: const Icon(
                                    Icons.content_cut_rounded,
                                    size: 28,
                                    color: AppColors.primaryPink,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        salon['name'] ?? '',
                                        style: AppTextStyles
                                            .cardTitle.copyWith(color: theme.textColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons
                                                  .location_on_outlined,
                                              size: 12,
                                              color: AppColors
                                                  .mutedText),
                                          const SizedBox(
                                              width: 2),
                                          Text(
                                              salon['distance'] ??
                                                  '',
                                              style: AppTextStyles
                                                  .label),
                                          const SizedBox(
                                              width: 6),
                                          const Icon(
                                              Icons.star_rounded,
                                              size: 12,
                                              color: Colors.amber),
                                          const SizedBox(
                                              width: 2),
                                          Text(
                                            salon['rating']
                                                ?.toStringAsFixed(
                                                1) ??
                                                '4.5',
                                            style: AppTextStyles
                                                .label
                                                .copyWith(
                                                fontWeight:
                                                FontWeight
                                                    .w600),
                                          ),
                                          const SizedBox(
                                              width: 6),
                                          Container(
                                            height: 6,
                                            width: 6,
                                            decoration:
                                            BoxDecoration(
                                              shape:
                                              BoxShape.circle,
                                              color: salon[
                                              'status'] ==
                                                  'Open'
                                                  ? AppColors
                                                  .success
                                                  : Colors.red,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 3),
                                          Text(
                                            salon['status'] ??
                                                'Open',
                                            style: AppTextStyles
                                                .label
                                                .copyWith(
                                              color: salon['status'] ==
                                                  'Open'
                                                  ? AppColors
                                                  .success
                                                  : Colors.red,
                                              fontWeight:
                                              FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'From ${salon['price'] ?? 'Rs.500'}',
                                        style: AppTextStyles
                                            .bodyMedium
                                            .copyWith(
                                          fontWeight:
                                          FontWeight.w700,
                                          color:
                                          AppColors.primaryPink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                    Icons
                                        .arrow_forward_ios_rounded,
                                    size: 14,
                                    color: theme.mutedTextColor),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}