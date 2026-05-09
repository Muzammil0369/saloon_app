import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_services_screen.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/upload_box.dart';

class OwnerDocumentsScreen extends StatefulWidget {
  const OwnerDocumentsScreen({super.key});
  @override
  State<OwnerDocumentsScreen> createState() => _OwnerDocumentsScreenState();
}

class _OwnerDocumentsScreenState extends State<OwnerDocumentsScreen> {
  String userInput = "";
  File? _cnicFrontImage;
  File? _cnicBackImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        if (isFront) { _cnicFrontImage = File(image.path); }
        else { _cnicBackImage = File(image.path); }
      });
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
        title: Text('Verification', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, bottom: 8),
            child: Container(
              decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.arrow_back, color: theme.textColor),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressStepBar(currentStep: 4, totalSteps: 5),
                const SizedBox(height: 30),
                Text('Verify Identity', style: AppTextStyles.displayLarge?.copyWith(color: theme.textColor)),
                Text('Required to prevent fraud and protect customers', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.lightPinkColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.borderColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔒 Why we need this?', style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor)),
                      Text('Your documents are encrypted and only reviewed by our admin team.', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                      Text('They will never be shared publicly.', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: '17301-xxxxxxx-x',
                    hintStyle: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
                    labelText: 'CNIC Number',
                    labelStyle: AppTextStyles.taglinePink,
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
                    prefixIcon: const Icon(Icons.numbers, color: AppColors.primaryPink),
                  ),
                  onChanged: (value) => setState(() => userInput = value),
                ),
                const SizedBox(height: 22),
                UploadBox(title: 'CNIC Front Photo', subtitle: 'Tap to upload · JPG or PNG', icon: Icons.camera_alt_outlined, initialImage: _cnicFrontImage, onImagePicked: (file) { _pickImage(true); }),
                const SizedBox(height: 16),
                UploadBox(title: 'CNIC Back Photo', subtitle: 'Tap to upload · JPG or PNG', icon: Icons.camera_alt_outlined, initialImage: _cnicBackImage, onImagePicked: (file) { _pickImage(false); }),
                const SizedBox(height: 16),
                UploadBox(title: 'Salon Photos (min 3)', subtitle: 'Interior, exterior, equipment', icon: Icons.camera_alt_outlined, initialImage: _cnicBackImage, onImagePicked: (file) { _pickImage(false); }),
                const SizedBox(height: 16),
                UploadBox(title: 'Salon Registration Certificate', subtitle: 'Certificate image', icon: Icons.camera_alt_outlined, initialImage: _cnicBackImage, onImagePicked: (file) { _pickImage(false); }),
                const SizedBox(height: 50),
                AppButton(label: 'Next', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerServicesScreen()));
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}