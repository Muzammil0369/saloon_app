import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/controllers/search_radius_controller.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

/// Bottom sheet to pick the search radius (2 / 5 / 10 / 20 / 25 km).
void showRadiusSheet(BuildContext context) {
  final theme = ThemeHelper(context);
  final controller = SearchRadiusController.instance;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: EdgeInsets.fromLTRB(
          22, 14, 22, 24 + MediaQuery.of(sheetContext).padding.bottom),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.lightPinkColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.radar_rounded,
                    color: AppColors.primaryPink, size: 20),
              ),
              const SizedBox(width: 10),
              Text('search_radius'.tr,
                  style: AppTextStyles.headingSmall
                      .copyWith(color: theme.textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text('search_radius_hint'.tr,
              style: TextStyle(color: theme.mutedTextColor, fontSize: 13)),
          const SizedBox(height: 20),
          Obx(() => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: SearchRadiusController.options.map((r) {
              final active = controller.km.value == r;
              return GestureDetector(
                onTap: () {
                  controller.setRadius(r);
                  Navigator.of(sheetContext).pop();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 92,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                    active ? AppColors.primaryPink : theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: active
                            ? AppColors.primaryPink
                            : theme.borderColor),
                  ),
                  child: Text('$r km',
                      style: TextStyle(
                          color: active ? Colors.white : theme.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              );
            }).toList(),
          )),
        ],
      ),
    ),
  );
}