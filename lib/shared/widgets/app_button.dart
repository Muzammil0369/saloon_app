import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final bool isOutline;
  final bool isSmall;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width,
    this.height = 48,
    this.isOutline = false,
    this.isSmall = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.lightPink,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryPink,
            ),
          ),
        ),
      );
    }

    if (isOutline) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: onTap,
          child: Text(label),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Syne',
              ),
            ),
          ],
        ),
      ),
    );
  }
}