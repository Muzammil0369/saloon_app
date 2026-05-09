import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';

class OwnerEarningsScreen extends StatefulWidget {
  const OwnerEarningsScreen({super.key});
  @override
  State<OwnerEarningsScreen> createState() => _OwnerEarningsScreenState();
}

class _OwnerEarningsScreenState extends State<OwnerEarningsScreen> {
  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y, width: 35, borderRadius: BorderRadius.circular(6),
        gradient: x == 3 ? AppGradients.primary : null,
        color: x == 3 ? null : AppColors.border,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Earnings', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 8),
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    Text('THIS MONTH', style: AppTextStyles.tagline?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text('Rs. 84,000', style: AppTextStyles.headingLarge.copyWith(color: Colors.white, fontSize: 30)),
                    const SizedBox(height: 2),
                    Text('▲ +18% from last month', style: AppTextStyles.bodyLarge?.copyWith(color: Colors.green)),
                  ]),
                ),
                const SizedBox(height: 18),

                // Weekly Breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [theme.softShadow]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Breakdown', style: AppTextStyles.headingMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 20, color: theme.textColor)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: BarChart(
                          BarChartData(
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  const days = ['M','T','W','T','F','S','S'];
                                  return Text(days[value.toInt()], style: AppTextStyles.label?.copyWith(color: theme.mutedTextColor));
                                },
                              )),
                            ),
                            barGroups: [_bar(0,40),_bar(1,60),_bar(2,45),_bar(3,85),_bar(4,55),_bar(5,70),_bar(6,50)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly Goal
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [theme.softShadow]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Goal', style: AppTextStyles.headingMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 20, color: theme.textColor)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.84, minHeight: 10,
                          backgroundColor: theme.grey100(),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Rs.0', style: TextStyle(fontSize: 13, color: theme.mutedTextColor, fontWeight: FontWeight.w500)),
                        Text('Rs.84K / 100K', style: AppTextStyles.displayMedium?.copyWith(color: AppColors.primaryPink, fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text('Top Services', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
                const SizedBox(height: 14),
                _serviceCard(Icons.cut, 'Haircut', '48 bookings this month', 'Rs.24K', theme),
                const SizedBox(height: 1),
                _serviceCard(Icons.woman, 'Bridal Package', '5 bookings this month', 'Rs.40K', theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(IconData icon, String name, String sub, String price, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), boxShadow: [theme.softShadow]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primaryPink),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
        ])),
        Text(price, style: AppTextStyles.displayMedium?.copyWith(color: AppColors.primaryPink, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}