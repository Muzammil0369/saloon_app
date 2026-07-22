import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';

// Fixed set of gradient templates owners can pick from, built from AppColors
// so every banner stays visually consistent with the rest of the app.
class AdTemplates {
  static const Map<String, LinearGradient> templates = {
    'pink_dark': LinearGradient(
      colors: [AppColors.primaryPink, AppColors.darkPink],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'soft_pink': LinearGradient(
      colors: [Color(0xFFFFD8E8), Color(0xFFFFB0CC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'midnight': LinearGradient(
      colors: [AppColors.darkText, AppColors.primaryPink],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'success': LinearGradient(
      colors: [AppColors.success, Color(0xFF1B6B38)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  static LinearGradient get(String? id) => templates[id] ?? templates['pink_dark']!;
}

class AdBannerCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const AdBannerCard({
    super.key,
    required this.ad,
    this.onTap,
    this.width = double.infinity,
    this.height = 215,
  });

  ImageProvider? _resolveImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    if (url.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(url.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String? bgImageUrl = ad['backgroundImageUrl'];
    final ImageProvider? bgImage = _resolveImage(bgImageUrl);
    final int percentOff = ad['percentOff'] ?? 0;
    final String offerTitle = ad['offerTitle'] ?? '';
    final String salonName = ad['salonName'] ?? '';
    final String? logoUrl = ad['logoUrl'];
    final ImageProvider? logoImage = _resolveImage(logoUrl);
    final num? originalPrice = ad['originalPrice'];
    final num? discountedPrice = ad['discountedPrice'];
    final List services = (ad['selectedServices'] as List?) ?? [];
    final String servicesLine = services.map((s) => s is Map ? (s['name'] ?? '') : s.toString()).where((n) => n.toString().isNotEmpty).join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: bgImage == null ? AdTemplates.get(ad['templateId']) : null,
          image: bgImage != null ? DecorationImage(image: bgImage, fit: BoxFit.cover) : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primaryPink.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Container(
          // A dark gradient overlay so text stays legible over ANY custom photo,
          // regardless of how bright or busy the owner's uploaded image is.
          decoration: bgImage != null
              ? BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.55)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Salon logo + name
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        image: logoImage != null ? DecorationImage(image: logoImage, fit: BoxFit.cover) : null,
                      ),
                      child: logoImage == null
                          ? const Icon(Icons.store, size: 14, color: AppColors.primaryPink)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        salonName,
                        style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. % off, standalone
                if (percentOff > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$percentOff% ${'off'.tr}',
                      style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 6),

                // 3. Big offer name — the headline
                Text(
                  offerTitle,
                  style: AppTextStyles.headingMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 4. Price line
                if (originalPrice != null && discountedPrice != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${'rs'.tr} $originalPrice',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${'rs'.tr} $discountedPrice',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ],

                // 5. Included services — small text, wraps to a 2nd line if long
                if (servicesLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    servicesLine,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const Spacer(),

                // 6. Claim Now
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'claim_now'.tr,
                    style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}