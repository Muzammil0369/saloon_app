import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/controllers/favourites_controller.dart';
import 'package:saloon_app/core/theme/app_colors.dart';

class FavouriteButton extends StatelessWidget {
  final String ownerId;
  final double iconSize;
  final Color backgroundColor;

  const FavouriteButton({
    super.key,
    required this.ownerId,
    this.iconSize = 20,
    this.backgroundColor = const Color(0xD9FFFFFF), // white @ ~85% opacity
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FavouritesController>();

    return Obx(() {
      final isFav = controller.isFavourite(ownerId);
      return GestureDetector(
        onTap: () => controller.toggleFavourite(ownerId),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: AppColors.primaryPink,
            size: iconSize,
          ),
        ),
      );
    });
  }
}