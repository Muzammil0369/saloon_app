import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ProgressStepBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressStepBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final filled = i < currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 5 : 0),
                decoration: BoxDecoration(
                  color: filled ? AppColors.primaryPink : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Step $currentStep of $totalSteps',
          style: AppTextStyles.tagline,
        ),
      ],
    );
  }
}