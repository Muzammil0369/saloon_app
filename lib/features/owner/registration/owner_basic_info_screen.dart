import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_services_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';
import 'package:get/get.dart';

class OwnerBasicInfoScreen extends StatefulWidget {
  const OwnerBasicInfoScreen({super.key});

  @override
  State<OwnerBasicInfoScreen> createState() => _OwnerBasicInfoScreenState();
}

class _OwnerBasicInfoScreenState extends State<OwnerBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Salon Info', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProgressStepBar(totalSteps: 6, currentStep: 3),
                const SizedBox(height: 30),

                Text('Basic Details 🏪',
                  style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
                ),
                const SizedBox(height: 8),
                Text('Tell us about your salon',
                    style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                
                const SizedBox(height: 40),

                _buildField('Salon Name', 'e.g. Royal Cuts Studio', theme, _nameController),
                const SizedBox(height: 20),
                _buildField('Full Address', 'Street, Area, City', theme, _addressController),
                const SizedBox(height: 20),
                
                Text('Select Salon Location', style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                const SizedBox(height: 12),
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(target: LatLng(34.0151, 71.5249), zoom: 12),
                      onMapCreated: (c) => _mapController = c,
                      onTap: (pos) => setState(() => _selectedLocation = pos),
                      markers: _selectedLocation != null 
                          ? {Marker(markerId: const MarkerId('salon'), position: _selectedLocation!)} 
                          : {},
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                AppButton(
                  label: 'Save & Next',
                  onTap: () {
                    if (_formKey.currentState!.validate() && _selectedLocation != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerServicesScreen(
                        salonData: {
                          'salonName': _nameController.text.trim(),
                          'address': _addressController.text.trim(),
                          'lat': _selectedLocation!.latitude,
                          'lng': _selectedLocation!.longitude,
                        }
                      )));
                    } else if (_selectedLocation == null) {
                      Get.snackbar('Location Required', 'Please pin your salon location on the map', backgroundColor: Colors.redAccent, colorText: Colors.white);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, ThemeHelper theme, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.borderColor),
          ),
          child: TextFormField(
            controller: controller,
            style: TextStyle(color: theme.textColor),
            validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.mutedTextColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
