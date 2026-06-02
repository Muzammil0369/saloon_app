import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class SalonCard extends StatelessWidget {
  final Map<String, dynamic> salon;
  final VoidCallback onTap;

  const SalonCard({super.key, required this.salon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    // Use salon image URL if available, else fallback to placeholder
    final image = salon['imageUrl'] != null 
        ? NetworkImage(salon['imageUrl']) 
        : const AssetImage('assets/slide1.png') as ImageProvider;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [theme.softShadow],
        ),
        child: Row(
          children: [
            Container(
              height: 80, width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(salon['name'] ?? 'Salon', style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          Text('${salon['rating']}', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Starting from Rs. ${salon['price']}', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: AppColors.primaryPink),
                      const SizedBox(width: 4),
                      Text(salon['distance'] ?? 'N/A', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                      const Spacer(),
                      // Status Indicator
                      Container(
                        height: 8, width: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: salon['status'] == 'Open' ? AppColors.success : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        salon['status'] ?? 'Closed',
                        style: AppTextStyles.label.copyWith(
                          color: salon['status'] == 'Open' ? AppColors.success : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
