import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class OwnerEarningsScreen extends StatefulWidget {
  const OwnerEarningsScreen({super.key});

  @override
  State<OwnerEarningsScreen> createState() => _OwnerEarningsScreenState();
}

class _OwnerEarningsScreenState extends State<OwnerEarningsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final ownerId = Get.find<AuthService>().uid;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('Earnings', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('ownerId', isEqualTo: ownerId)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final bookings = snapshot.data?.docs ?? [];
          
          // Calculate stats
          double totalEarnings = 0;
          Map<String, double> dailyEarnings = {};

          for (var doc in bookings) {
            final data = doc.data() as Map<String, dynamic>;
            final price = (data['totalPrice'] ?? 0).toDouble();
            final date = (data['date'] as Timestamp).toDate();
            final dateKey = DateFormat('EEE').format(date); // Mon, Tue, etc.

            totalEarnings += price;
            dailyEarnings[dateKey] = (dailyEarnings[dateKey] ?? 0) + price;
          }

          final chartData = dailyEarnings.entries
              .map((e) => _ChartData(e.key, e.value))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Weekly Total Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [theme.softShadow], // Added soft shadow
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Earnings', style: AppTextStyles.label.copyWith(color: Colors.white.withOpacity(0.9))),
                      const SizedBox(height: 8),
                      Text('Rs. ${totalEarnings.toStringAsFixed(0)}', style: AppTextStyles.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Bar Chart ──
                Text('Performance', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24), // Increased radius
                    boxShadow: [theme.softShadow], // Added soft shadow
                  ),
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: TextStyle(color: theme.mutedTextColor, fontFamily: 'DM Sans'),
                    ),
                    primaryYAxis: NumericAxis(isVisible: false),
                    plotAreaBorderWidth: 0,
                    series: <CartesianSeries<_ChartData, String>>[
                      ColumnSeries<_ChartData, String>(
                        dataSource: chartData,
                        xValueMapper: (_ChartData data, _) => data.x,
                        yValueMapper: (_ChartData data, _) => data.y,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        color: AppColors.primaryPink,
                        width: 0.6, // Slimmer bars for modern look
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}
