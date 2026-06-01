import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class OwnerEarningsScreen extends StatefulWidget {
  const OwnerEarningsScreen({super.key});

  @override
  State<OwnerEarningsScreen> createState() => _OwnerEarningsScreenState();
}

class _OwnerEarningsScreenState extends State<OwnerEarningsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    final List<_ChartData> chartData = [
      _ChartData('Mon', 4500),
      _ChartData('Tue', 3200),
      _ChartData('Wed', 5100),
      _ChartData('Thu', 2800),
      _ChartData('Fri', 6500),
      _ChartData('Sat', 8200),
      _ChartData('Sun', 7500),
    ];

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('Earnings', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Weekly Total Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This Week', style: AppTextStyles.label.copyWith(color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 8),
                  Text('Rs. 37,800.00', style: AppTextStyles.displayLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 4),
                      Text('+12% from last week', style: AppTextStyles.label.copyWith(color: Colors.greenAccent)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Bar Chart ──
            Text('Daily Performance', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
            const SizedBox(height: 16),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.borderColor),
              ),
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: TextStyle(color: theme.mutedTextColor),
                ),
                primaryYAxis: NumericAxis(
                  isVisible: false,
                ),
                plotAreaBorderWidth: 0,
                series: <CartesianSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (_ChartData data, _) => data.x,
                    yValueMapper: (_ChartData data, _) => data.y,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: AppGradients.primary,
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Transactions ──
            Text('Recent Payouts', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
            const SizedBox(height: 16),
            _payoutItem('Oct 20, 2026', 'Rs. 12,400', 'Completed', theme),
            _payoutItem('Oct 13, 2026', 'Rs. 9,800', 'Completed', theme),
          ],
        ),
      ),
    );
  }

  Widget _payoutItem(String date, String amount, String status, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
              Text(status, style: AppTextStyles.label.copyWith(color: Colors.green)),
            ],
          ),
          Text(amount, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}
