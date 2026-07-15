import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/salon_detail_screen.dart';

class FavouriteSalonsScreen extends StatelessWidget {
  const FavouriteSalonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    final List<Map<String, dynamic>> favourites = [
      {
        'ownerId': 'owner_id_1',
        'name': 'Royal Cuts Studio',
        'distance': '0.3 km',
        'status': 'Open',
        'price': '500',
        'rating': 4.9
      },
      {
        'ownerId': 'owner_id_2',
        'name': 'Glamour Zone',
        'distance': '0.7 km',
        'status': 'Open',
        'price': '800',
        'rating': 4.8
      },
    ];

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
      body: favourites.isEmpty
          ? Center(child: Text('no_favourites'.tr, style: TextStyle(color: theme.mutedTextColor)))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: favourites.length,
        itemBuilder: (context, index) {
          final salon = favourites[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalonDetailScreen(
                  ownerId: salon['ownerId'],
                  salon: salon,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [theme.softShadow],
              ),
              child: Row(
                children: [
                  Container(
                    height: 60, width: 60,
                    decoration: BoxDecoration(
                      color: theme.lightPinkColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.primaryPink),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon['name'],
                          style: AppTextStyles.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          '${salon['distance']} · ${salon['rating']}★',
                          style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite_rounded, color: AppColors.primaryPink, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}