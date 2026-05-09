import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/customer_main_wrapper.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/progress_step_bar.dart';

class CustomerProfileSetupScreen extends StatefulWidget {
  const CustomerProfileSetupScreen({super.key});

  @override
  State<CustomerProfileSetupScreen> createState() => _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState extends State<CustomerProfileSetupScreen> {
  String userInput = "";
  String? selectedCity;
  final List<String> cities = [
    'Peshawar',
    'Karachi',
    'Lahore',
    'Islamabad',
    'Quetta'
  ];

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
          onTap: () {
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.lightPinkColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, color: theme.textColor),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressStepBar(
                  totalSteps: 3,
                  currentStep: 3,
                ),
                const SizedBox(height: 30),
                Text('Almost Done',
                  style: AppTextStyles.displayLarge?.copyWith(color: theme.textColor),
                ),
                Text('Set up your profile to get started',
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
                ),
                const SizedBox(height: 30),
        
                // Profile Photo
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.darkPink,
                          ),
                          child: const CircleAvatar(
                            radius: 60,
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.cardColor,
                                width: 3,
                              ),
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
        
                // Full Name
                TextField(
                  keyboardType: TextInputType.name,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Owner Full Name',
                    hintStyle: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
                    labelText: 'Full Name',
                    labelStyle: AppTextStyles.taglinePink,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    prefixIcon: const Icon(Icons.drive_file_rename_outline, color: AppColors.primaryPink),
                  ),
                  onChanged: (value) {
                    setState(() {
                      userInput = value;
                    });
                  },
                ),
                const SizedBox(height: 15),
        
                // Email
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'example@email.com',
                    hintStyle: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor),
                    labelText: 'Email',
                    labelStyle: AppTextStyles.taglinePink,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryPink),
                  ),
                  onChanged: (value) {
                    setState(() {
                      userInput = value;
                    });
                  },
                ),
                const SizedBox(height: 15),
        
                // City Dropdown
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
                        hint: Row(
                          children: [
                            const Icon(Icons.location_city, color: AppColors.primaryPink),
                            const SizedBox(width: 12),
                            Text('Select City',
                              style: AppTextStyles.taglinePink?.copyWith(color: theme.mutedTextColor),
                            ),
                          ],
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryPink),
                        items: cities.map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Row(
                              children: [
                                const Icon(Icons.location_city, color: AppColors.primaryPink),
                                const SizedBox(width: 12),
                                Text(city, style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                )),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCity = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
        
                const SizedBox(height: 50),
        
                AppButton(label: 'Start Booking', onTap: () {
                   Navigator.push(context,
                   MaterialPageRoute (builder: (context)=> CustomerMainWrapper()));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}