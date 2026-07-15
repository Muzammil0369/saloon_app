import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_services_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';
import 'package:get/get.dart';

import '../../../core/services/translation_service.dart';

class OwnerBasicInfoScreen extends StatefulWidget {
  const OwnerBasicInfoScreen({super.key});

  @override
  State<OwnerBasicInfoScreen> createState() => _OwnerBasicInfoScreenState();
}

class _OwnerBasicInfoScreenState extends State<OwnerBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _ownerProfileImage;

  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = false;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(34.0151, 71.5249),
    zoom: 14,
  );

  @override
  void dispose() {
    _ownerNameController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Pick owner profile image
  Future<void> _pickOwnerImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('add_your_photo'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryPink),
              title: Text('take_photo'.tr),
              onTap: () {
                Navigator.pop(context);
                _captureImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryPink),
              title: Text('choose_gallery'.tr),
              onTap: () {
                Navigator.pop(context);
                _captureImage(ImageSource.gallery);
              },
            ),
            if (_ownerProfileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('remove_photo'.tr, style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _ownerProfileImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (image != null) {
        setState(() => _ownerProfileImage = File(image.path));
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_pick_image'.tr);
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('permission_denied'.tr, 'please_allow_location'.tr);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userLocation = LatLng(position.latitude, position.longitude);
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: userLocation, zoom: 16)),
      );
      setState(() {
        _selectedLocation = userLocation;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('salon_info'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProgressStepBar(totalSteps: 7, currentStep: 3),
                      const SizedBox(height: 30),

                      Text('basic_details'.tr + '🏪',
                        style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
                      ),
                      const SizedBox(height: 8),
                      Text('tell_about_salon'.tr,
                          style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                      const SizedBox(height: 32),

                      // ✅ Owner Profile Photo
                      Center(
                        child: GestureDetector(
                          onTap: _pickOwnerImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primaryPink, width: 3),
                                  image: _ownerProfileImage != null
                                      ? DecorationImage(image: FileImage(_ownerProfileImage!), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _ownerProfileImage == null
                                    ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person, size: 40, color: theme.mutedTextColor),
                                    const SizedBox(height: 4),
                                    Text('add_photo'.tr, style: TextStyle(fontSize: 10, color: theme.mutedTextColor)),
                                  ],
                                )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryPink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Owner Name
                      _buildField('owner_full_name'.tr, 'e.g. Aslam Khan', theme, _ownerNameController),
                      const SizedBox(height: 16),

                      // Salon Name
                      _buildField('salon_name'.tr, 'e.g. Royal Cuts Studio', theme, _nameController),
                      const SizedBox(height: 16),

                      // Phone Number
                      _buildField('phone'.tr, '03XX-XXXXXXX', theme, _phoneController,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),

                      // Full Address
                      _buildField('address'.tr, 'Street, Area, City', theme, _addressController),
                      const SizedBox(height: 24),

                      // Map Section (same as before - working perfectly)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Salon Location', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                          GestureDetector(
                            onTap: _isLoadingLocation ? null : _goToCurrentLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.lightPink,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _isLoadingLocation
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink))
                                      : const Icon(Icons.my_location, size: 16, color: AppColors.primaryPink),
                                  const SizedBox(width: 6),
                                  Text('Use My Location', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Tap anywhere on the map to place the pin', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                      if (_selectedLocation != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text('📍 Selected: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                        ),
                      ],
                      const SizedBox(height: 12),

                      Container(
                        height: 300, width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.borderColor, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                            initialCameraPosition: _defaultPosition,
                            onMapCreated: (controller) => _mapController = controller,
                            onTap: (LatLng pos) {
                              setState(() => _selectedLocation = pos);
                              _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
                            },
                            onLongPress: (LatLng pos) {
                              setState(() => _selectedLocation = pos);
                              _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
                            },
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            myLocationButtonEnabled: true,
                            myLocationEnabled: true,
                            compassEnabled: true,
                            mapToolbarEnabled: true,
                            markers: _selectedLocation != null
                                ? {Marker(markerId: const MarkerId('salon'), position: _selectedLocation!, draggable: true,
                                onDragEnd: (np) => setState(() => _selectedLocation = np),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                                infoWindow: const InfoWindow(title: '🏪 Your Salon', snippet: 'Drag to adjust'))}
                                : {},
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      AppButton(
                        label: 'save_next'.tr,
                        onTap: () async {
                          if (_formKey.currentState!.validate() && _selectedLocation != null) {
                            // Get translation service
                            final translationService = Get.find<TranslationService>();

                            // Translate salon name and address to Urdu
                            final salonNameUr = await translationService.translateEnToUr(_nameController.text.trim());
                            final addressUr = await translationService.translateEnToUr(_addressController.text.trim());

                            Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerServicesScreen(
                                salonData: {
                                  'ownerName': _ownerNameController.text.trim(),
                                  'ownerProfileImage': _ownerProfileImage?.path,
                                  'salonName': _nameController.text.trim(),
                                  'salonName_ur': salonNameUr, // ✅ Add Urdu translation
                                  'phoneNumber': _phoneController.text.trim(),
                                  'address': _addressController.text.trim(),
                                  'address_ur': addressUr, // ✅ Add Urdu translation
                                  'lat': _selectedLocation!.latitude,
                                  'lng': _selectedLocation!.longitude,
                                }
                            )));
                          } else if (_selectedLocation == null) {
                            Get.snackbar('location_required'.tr, 'please_pin_location'.tr,
                                backgroundColor: Colors.redAccent, colorText: Colors.white);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, ThemeHelper theme, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.borderColor)),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: theme.textColor),
            validator:(value) => value!.isEmpty ? '${'please_enter'.tr} $label' : null,
            decoration: InputDecoration(
              hintText: hint, hintStyle: TextStyle(color: theme.mutedTextColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}