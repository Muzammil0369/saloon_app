import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class BookingDateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const BookingDateChip({
    super.key,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final dayName = DateFormat('EEE').format(date);
    final dayNum = DateFormat('dd').format(date);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : theme.borderColor,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white.withOpacity(0.8) : theme.mutedTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNum,
              style: AppTextStyles.headingMedium?.copyWith(
                color: isSelected ? Colors.white : theme.textColor,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}