import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/controllers/language_controller.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/shared/widgets/favourite_button.dart';

class SalonCard extends StatelessWidget {
  final Map<String, dynamic> salon;
  final VoidCallback onTap;

  const SalonCard({super.key, required this.salon, required this.onTap});

  // Get the best available image
  ImageProvider _getImage() {
    // 1. Check for logo
    final logo = salon['logo'];
    if (logo != null && logo.toString().isNotEmpty) {
      return _getImageProvider(logo.toString());
    }

    // 2. Check for thumbnail
    final thumbnail = salon['thumbnail'];
    if (thumbnail != null && thumbnail.toString().isNotEmpty) {
      return _getImageProvider(thumbnail.toString());
    }

    // 3. Check for imageUrl
    final imageUrl = salon['imageUrl'];
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return _getImageProvider(imageUrl.toString());
    }

    // 4. Check for ownerProfileImage
    final ownerImage = salon['ownerProfileImage'];
    if (ownerImage != null && ownerImage.toString().isNotEmpty) {
      return _getImageProvider(ownerImage.toString());
    }

    // 5. Fallback to placeholder
    return const AssetImage('assets/slide1.png');
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return MemoryImage(bytes);
      } catch (_) {}
    }
    return const AssetImage('assets/slide1.png');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Directionality(
      textDirection: Get.find<LanguageController>().languageCode == 'ur'
        ? TextDirection.rtl
        : TextDirection.ltr,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [theme.softShadow],
              ),
              child: Row(
                children: [
                  // Salon Image/Logo
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.lightPink,
                      image: DecorationImage(
                        image: _getImage(),
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Show store icon if no image
                    child: (salon['logo'] == null &&
                        salon['thumbnail'] == null &&
                        salon['imageUrl'] == null &&
                        salon['ownerProfileImage'] == null)
                        ? const Icon(Icons.store, color: AppColors.primaryPink, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                salon['name'] ?? 'salon'.tr,
                                style: AppTextStyles.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${'starting_from_rs'.tr} ${salon['price'] ?? '500'}',
                              style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                            ),

                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                Text(
                                  '${salon['rating'] ?? 0.0}',
                                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if ((salon['reviewCount'] ?? 0) > 0)
                                  Text(
                                    ' (${salon['reviewCount']})',
                                    style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                                  ),
                              ],
                            ),
                            // const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            // Text(
                            //   '${salon['rating'] ?? 0.0}',
                            //   style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                            // ),
                            // if ((salon['reviewCount'] ?? 0) > 0)
                            //   Text(
                            //     ' (${salon['reviewCount']})',
                            //     style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                            //   ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: AppColors.primaryPink),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                salon['distance'] ?? 'N/A',
                                style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Indicator
                            Container(
                              height: 8, width: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: salon['status'] == 'open'.tr ? AppColors.success : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              salon['status'] ?? 'closed'.tr,
                              style: AppTextStyles.label.copyWith(
                                color: salon['status'] == 'open'.tr ? AppColors.success : Colors.red,
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
            Positioned.directional(
              textDirection: Get.find<LanguageController>().languageCode == 'ur'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              top: 8,
              end: 8,
              child: FavouriteButton(
                  ownerId: salon['ownerId']?.toString() ?? '',
                  iconSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}