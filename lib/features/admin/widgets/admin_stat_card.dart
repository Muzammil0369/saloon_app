import 'package:flutter/material.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';

class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final bool isPositive;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.trend = "0%",
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AdminColors.primary, size: 20),
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? AdminColors.success : AdminColors.danger,
                    size: 16,
                  ),
                  Text(
                  trend,
                  style: TextStyle(
                    color: isPositive ? AdminColors.success : AdminColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AdminColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
