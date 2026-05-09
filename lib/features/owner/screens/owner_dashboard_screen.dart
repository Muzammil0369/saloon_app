import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/screens/owner_schedule_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const OwnerDashboardScreen({super.key, required this.onTabChange});
  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              height: 48, width: 48,
              decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Royal Cuts', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
                  Text('Peshawar, KPK', style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Icon(Icons.circle, color: AppColors.success, size: 6),
                const SizedBox(width: 4),
                Text('Open', style: AppTextStyles.label.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn('12', 'APPOINTMENTS'),
                    Container(width: 1, height: 36, color: Colors.white.withOpacity(0.3)),
                    _statColumn('8,400', 'REVENUE (Rs.)'),
                    Container(width: 1, height: 36, color: Colors.white.withOpacity(0.3)),
                    _statColumn('4.9★', 'RATING'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _gridItem(Icons.calendar_month_rounded, 'Schedule', Colors.blue, () => widget.onTabChange(1), theme),
                  _gridItem(Icons.trending_up_rounded, 'Earnings', Colors.green, () => widget.onTabChange(2), theme),
                  _gridItem(Icons.people_rounded, 'Staff', Colors.orange, () {}, theme),
                  _gridItem(Icons.settings_rounded, 'Settings', Colors.purple, () => widget.onTabChange(3), theme),
                ],
              ),
              const SizedBox(height: 20),

              // Today's Queue Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Queue", style: AppTextStyles.headingLarge?.copyWith(fontSize: 16, color: theme.textColor)),
                  GestureDetector(onTap: () => widget.onTabChange(1), child: Text('Manage All', style: AppTextStyles.linkText)),
                ],
              ),
              const SizedBox(height: 12),

              _appointmentCard('10:00', 'AM', 'Ali Hassan', 'Haircut + Beard · Rs.700', theme),
              _appointmentCard('11:30', 'AM', 'Sara Khan', 'Bridal Package · Rs.8,000', theme),
              _appointmentCard('2:00', 'PM', 'Bilal Ahmad', 'Facial · Rs.800', theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(children: [
      Text(value, style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
      const SizedBox(height: 4),
      Text(label, style: AppTextStyles.label.copyWith(color: Colors.white70)),
    ]);
  }

  Widget _gridItem(IconData icon, String label, Color color, VoidCallback onTap, ThemeHelper theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.isDark ? color.withOpacity(0.1) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor)),
          ],
        ),
      ),
    );
  }

  Widget _appointmentCard(String time, String ampm, String name, String service, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [theme.softShadow],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(time, style: AppTextStyles.headingSmall?.copyWith(color: AppColors.primaryPink)),
            Text(ampm, style: AppTextStyles.label?.copyWith(color: AppColors.primaryPink)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 2),
            Text(service, style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
          ]),
        ),
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
        ),
        const SizedBox(width: 6),
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primaryPink),
        ),
      ]),
    );
  }
}