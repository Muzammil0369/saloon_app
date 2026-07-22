import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/controllers/favourites_controller.dart';
import 'package:saloon_app/core/controllers/language_controller.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/salon_detail_screen.dart';
import 'package:saloon_app/shared/widgets/salon_card.dart';

class FavouriteSalonsScreen extends StatefulWidget {
  const FavouriteSalonsScreen({super.key});

  @override
  State<FavouriteSalonsScreen> createState() => _FavouriteSalonsScreenState();
}

class _FavouriteSalonsScreenState extends State<FavouriteSalonsScreen> {
  final FavouritesController _favController = Get.find<FavouritesController>();
  List<Map<String, dynamic>> _favouriteSalons = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((_) => _loadFavouriteSalons());
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadFavouriteSalons() async {
    setState(() => _isLoading = true);

    await _favController.refresh();
    final ids = _favController.favouriteIds.toList();

    if (ids.isEmpty) {
      setState(() {
        _favouriteSalons = [];
        _isLoading = false;
      });
      return;
    }

    // Firestore whereIn supports max 10 values per query, so chunk it
    final List<Map<String, dynamic>> results = [];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snapshot = await FirebaseFirestore.instance
          .collection('owners')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final GeoPoint? salonLoc = data['location'];
        String distanceText = 'N/A';

        if (_currentPosition != null && salonLoc != null) {
          final double distInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            salonLoc.latitude, salonLoc.longitude,
          );
          final double distKm = distInMeters / 1000;
          final String unit = Get.find<LanguageController>().languageCode == 'ur' ? 'km'.tr : 'km';
          distanceText = '${distKm.toStringAsFixed(1)} $unit';
        }

        results.add({
          'ownerId': doc.id,
          'name': data['salonName'] ?? 'Unnamed Salon',
          'rating': data['rating']?.toDouble() ?? 0.0,
          'reviewCount': data['reviewCount'] ?? 0,
          'status': data['isOpenNow'] == true ? 'open'.tr : 'closed'.tr,
          'price': '500',
          'distance': distanceText,
          'logo': data['logo'],
          'thumbnail': data['thumbnail'],
          'imageUrl': data['salonPhotos'] != null && (data['salonPhotos'] as List).isNotEmpty
              ? (data['salonPhotos'] as List).first
              : null,
        });
      }
    }

    setState(() {
      _favouriteSalons = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('favourite_salons'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : _favouriteSalons.isEmpty
          ? Center(child: Text('no_favourites'.tr, style: TextStyle(color: theme.mutedTextColor)))
          : RefreshIndicator(
        onRefresh: () async {
          await _getCurrentLocation();
          await _loadFavouriteSalons();
        },
        color: AppColors.primaryPink,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _favouriteSalons.length,
          itemBuilder: (context, index) {
            final salon = _favouriteSalons[index];
            return SalonCard(
              salon: salon,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalonDetailScreen(
                      ownerId: salon['ownerId'],
                      salon: salon,
                    ),
                  ),
                );
                // Refresh in case the user un-favourited from the detail screen
                _loadFavouriteSalons();
              },
            );
          },
        ),
      ),
    );
  }
}