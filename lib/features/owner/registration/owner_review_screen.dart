import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/owner_main_wrapper.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import '../../../core/theme/app_colors.dart';

class OwnerReviewScreen extends StatefulWidget {
  const OwnerReviewScreen({super.key});
  @override
  State<OwnerReviewScreen> createState() => _OwnerReviewScreenState();
}

class _OwnerReviewScreenState extends State<OwnerReviewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation, _scaleAnimation, _checklistAnimation, _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));
    _checklistAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.8, 1.0, curve: Curves.easeInOut)));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Center(
                      child: Container(
                        height: 100, width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.lightPinkColor,
                          boxShadow: [BoxShadow(color: AppColors.primaryPink.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
                        ),
                        child: const Icon(Icons.hourglass_bottom_rounded, size: 50, color: AppColors.primaryPink),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: Text('Under Review', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor))),
                const SizedBox(height: 12),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(text: 'Your application has been submitted! Our admin team will review your documents within ', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                      TextSpan(text: '24–48 hours.', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.borderColor, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChecklistItem('Phone verified', Icons.check_circle, Colors.green, theme),
                        const SizedBox(height: 12),
                        _buildChecklistItem('Salon details submitted', Icons.check_circle, Colors.green, theme),
                        const SizedBox(height: 12),
                        _buildChecklistItem('CNIC documents uploaded', Icons.check_circle, Colors.green, theme),
                        const SizedBox(height: 12),
                        _buildChecklistItem('Admin approval pending...', Icons.access_time_rounded, Colors.orange, theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.sms_outlined, size: 16, color: theme.mutedTextColor),
                    const SizedBox(width: 8),
                    Text("You'll receive an SMS when approved", style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                  ]),
                ),
                const SizedBox(height: 24),
                AppButton(label: 'Preview Dashboard', onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerMainWrapper()));}),
                const SizedBox(height: 18),
                AppButton(label: 'Back to Home', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerMainWrapper())); }, isOutline: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text, IconData icon, Color iconColor, ThemeHelper theme) {
    return Row(children: [
      Icon(icon, color: iconColor, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor))),
    ]);
  }
}