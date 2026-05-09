import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_documents_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/progress_step_bar.dart';

class OwnerBasicInfoScreen extends StatefulWidget {
  const OwnerBasicInfoScreen({super.key});
  @override
  State<OwnerBasicInfoScreen> createState() => _OwnerBasicInfoScreenState();
}

class _OwnerBasicInfoScreenState extends State<OwnerBasicInfoScreen> {
  String userInput = "";
  String? selectedCity;
  final List<String> cities = ['Peshawar', 'Karachi', 'Lahore', 'Islamabad', 'Quetta'];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Basic Info', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
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
                ProgressStepBar(totalSteps: 5, currentStep: 3),
                const SizedBox(height: 30),
                Text('Salon Details', style: AppTextStyles.displayLarge?.copyWith(color: theme.textColor)),
                Text('Tell us about your salon', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                const SizedBox(height: 30),
                _buildTextField('Owner Full Name', Icons.drive_file_rename_outline, false, theme, label: 'Name'),
                const SizedBox(height: 15),
                _buildTextField('example@email.com', Icons.email_outlined, true, theme, label: 'Email'),
                const SizedBox(height: 15),
                _buildTextField('King Salon', Icons.drive_file_rename_outline_outlined, false, theme, label: 'Salon Name'),
                const SizedBox(height: 15),
                _buildTextField('abc road xyz city', Icons.location_on_outlined, false, theme, label: 'Salon Address'),
                const SizedBox(height: 15),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCity,
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        hint: Row(children: [const Icon(Icons.location_city, color: AppColors.primaryPink), const SizedBox(width: 12), Text('Select City', style: AppTextStyles.taglinePink)]),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryPink),
                        items: cities.map((city) => DropdownMenuItem(value: city, child: Row(children: [const Icon(Icons.location_city, color: AppColors.primaryPink), const SizedBox(width: 12), Text(city, style: TextStyle(color: theme.textColor, fontSize: 14))]))).toList(),
                        onChanged: (value) => setState(() => selectedCity = value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField('Google Maps Link (Optional)', Icons.location_on_outlined, false, theme, label: 'Map Link'),
                const SizedBox(height: 50),
                AppButton(label: 'Next', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerDocumentsScreen()));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, bool isEmail, ThemeHelper theme, {String? label}) {
    return TextField(
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.name,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
        labelText: label,
        labelStyle: AppTextStyles.taglinePink,
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
        prefixIcon: Icon(icon, color: AppColors.primaryPink),
      ),
      onChanged: (value) => setState(() => userInput = value),
    );
  }
}