import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final List<Map<String, String>> addresses = [
      {'title': 'Home', 'address': 'House 123, Sector F-10/4, Islamabad'},
      {'title': 'Office', 'address': 'Silver City Plaza, 2nd Floor, Peshawar'},
    ];

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('Addresses', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final addr = addresses[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: theme.lightPinkColor, shape: BoxShape.circle),
                  child: Icon(addr['title'] == 'Home' ? Icons.home_rounded : Icons.work_rounded, color: AppColors.primaryPink, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(addr['title']!, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                      Text(addr['address']!, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert_rounded, color: AppColors.mutedText),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
