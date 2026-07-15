import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_controller.dart';

class SalonController extends GetxController {
  var salons = <Map<String, dynamic>>[].obs;
  var recentSalons = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var userPosition = Rxn<Position>();

  // Search, Filter, Sort
  var searchQuery = ''.obs;
  var selectedCategory = 'All'.obs;
  var filteredSalons = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initBackgroundLocation();
    fetchSalons();
    loadRecentSalons();

    // Listen to changes to update filtered list automatically
    everAll([searchQuery, selectedCategory, salons], (_) => _updateFilteredList());
  }

  void _updateFilteredList() {
    final langCode = Get.find<LanguageController>().languageCode;
    filteredSalons.value = salons.where((salon) {
      final String nameToSearch = langCode == 'ur' 
          ? (salon['salonName_ur'] ?? salon['salonName'] ?? '') 
          : (salon['salonName'] ?? '');
          
      final matchesSearch = nameToSearch.toString().toLowerCase().contains(searchQuery.value.toLowerCase());
      final List<String> salonCategories = (salon['categories'] as List<String>?) ?? [];
      final matchesCategory = selectedCategory.value == 'All' || salonCategories.contains(selectedCategory.value);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void sortSalons(String criteria) {
    if (criteria == 'Nearest') {
      salons.sort((a, b) => (a['distanceValue'] as double).compareTo(b['distanceValue'] as double));
    } else if (criteria == 'Price (Low-High)') {
      salons.sort((a, b) => (int.tryParse(a['price'].toString()) ?? 0).compareTo(int.tryParse(b['price'].toString()) ?? 0));
    } else if (criteria == 'Price (High-Low)') {
      salons.sort((a, b) => (int.tryParse(b['price'].toString()) ?? 0).compareTo(int.tryParse(a['price'].toString()) ?? 0));
    }
    _updateFilteredList();
  }

  // Fetch location in background to update distances reactively
  Future<void> _initBackgroundLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        updateUserPosition(pos);
      }
    } catch (e) {
       print("SalonController: Background location error: $e");
    }
  }

  void updateUserPosition(Position pos) {
    userPosition.value = pos;
    _recalculateAllDistances();
  }

  void _recalculateAllDistances() {
    if (userPosition.value == null) return;

    // 1. Recalculate main salons list
    final List<Map<String, dynamic>> updatedSalons = salons.map((s) => _calculateSingleDistance(s)).toList();
    salons.value = updatedSalons;

    // 2. Recalculate recent salons list
    final List<Map<String, dynamic>> updatedRecents = recentSalons.map((s) => _calculateSingleDistance(s)).toList();
    recentSalons.value = updatedRecents;
  }

  Map<String, dynamic> _calculateSingleDistance(Map<String, dynamic> salon) {
    if (userPosition.value == null || salon['lat'] == null || salon['lng'] == null) return salon;
    
    final double distInMeters = Geolocator.distanceBetween(
      userPosition.value!.latitude, userPosition.value!.longitude,
      salon['lat'], salon['lng'],
    );
    final double distKm = distInMeters / 1000;
    String distanceText;
    
    if (distKm > 1000) {
      distanceText = '${(distKm / 1000).toStringAsFixed(1)}k km';
    } else {
      distanceText = '${distKm.toStringAsFixed(1)} km';
    }

    return {
      ...salon,
      'distance': distanceText,
      'distanceValue': distKm,
    };
  }

  Future<void> fetchSalons({Position? userPos}) async {
    isLoading.value = true;
    if (userPos != null) userPosition.value = userPos;
    
    try {
      if (userPosition.value == null) {
        try {
          userPosition.value = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (e) {
          print("SalonController: Fetch location error: $e");
        }
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('owners')
          .where('showOnMap', isNotEqualTo: false)
          .get();
      
      print("SalonController: Found ${snapshot.docs.length} salons");
      
      salons.value = snapshot.docs.map((doc) {
        final data = doc.data();
        final GeoPoint? location = data['location'];
        final List<dynamic> services = data['services'] ?? [];
        
        // Calculate min price dynamically
        int minPrice = 0;
        if (services.isNotEmpty) {
          minPrice = services
              .map((s) => int.tryParse(s['price'].toString()) ?? 0)
              .reduce((a, b) => a < b ? a : b);
        }

        // Get categories (assuming each service has a 'name' that acts as category, or an explicit category field)
        // For now, mapping all service names to a set of categories
        final List<String> categories = services.map((s) => s['name'].toString()).toList();
        
        Map<String, dynamic> salon = {
          'ownerId': doc.id,
          'salonName': data['salonName'] ?? 'Unnamed Salon',
          'salonName_ur': data['salonName_ur'] ?? '',
          'name': data['salonName'] ?? 'Unnamed Salon',
          'rating': data['rating']?.toDouble() ?? 4.5,
          'status': data['isOpenNow'] == true ? 'Open' : 'Closed',
          'acceptWalkIns': data['acceptWalkIns'] ?? true,
          'price': minPrice.toString(), 
          'categories': categories, // Store as a list
          'lat': location?.latitude ?? 0.0,
          'lng': location?.longitude ?? 0.0,
          'address': data['address'] ?? '',
          'imageUrl': data['salonPhotos'] != null && (data['salonPhotos'] as List).isNotEmpty 
              ? (data['salonPhotos'] as List).first : null,
          'distance': 'N/A',
          'distanceValue': 999.0,
        };

        return _calculateSingleDistance(salon);
      }).toList();

      // Sort by rank (simplified logic for now)
      salons.sort((a, b) => (a['distanceValue'] as double).compareTo(b['distanceValue'] as double));
      
      _updateFilteredList(); // ADDED THIS
      
    } catch (e) {
      print("SalonController: Firestore error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRecentSalons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recentJson = prefs.getString('recent_salons');
    if (recentJson != null) {
      final List<dynamic> list = jsonDecode(recentJson);
      recentSalons.value = list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  Future<void> addToRecent(Map<String, dynamic> salon) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove if already exists (to move to top)
    recentSalons.removeWhere((s) => s['ownerId'] == salon['ownerId']);
    
    // Add to top
    recentSalons.insert(0, salon);
    
    // Limit to 5
    if (recentSalons.length > 5) {
      recentSalons.removeLast();
    }
    
    await prefs.setString('recent_salons', jsonEncode(recentSalons));
  }
}
