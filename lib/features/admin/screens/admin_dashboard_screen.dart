import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:saloon_app/features/admin/controllers/admin_controller.dart';
import 'package:saloon_app/features/admin/widgets/admin_stat_card.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();

    // Refresh stats when screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminController.refreshStats();
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              AdminStatCard(
                title: "Customers",
                value: adminController.totalCustomers.value.toString(),
                icon: Icons.people,
                trend: adminController.userTrend.value,
              ),
              AdminStatCard(
                title: "Owners",
                value: adminController.totalOwners.value.toString(),
                icon: Icons.store,
                trend: "+${adminController.totalOwners.value > 0 ? '10' : '0'}%", // Simple trend
              ),
              AdminStatCard(
                title: "Admins",
                value: adminController.totalAdmins.value.toString(),
                icon: Icons.admin_panel_settings,
                trend: "+0%",
              ),
              AdminStatCard(
                title: "Total Revenue",
                value: "PKR ${adminController.totalRevenue.value.toStringAsFixed(0)}",
                icon: Icons.payments,
                trend: adminController.revenueTrend.value,
              ),
            ],
          )),

          const SizedBox(height: 32),
          _buildRevenueChart(adminController),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(AdminController controller) {
    final chartData = controller.getRevenueChartData();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Revenue Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <CartesianSeries>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: chartData,
                  xValueMapper: (data, _) => data['day'],
                  yValueMapper: (data, _) => data['amount'],
                  color: AdminColors.accent,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}