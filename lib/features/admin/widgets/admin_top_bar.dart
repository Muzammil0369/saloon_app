import 'package:flutter/material.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';

class AdminTopBar extends StatelessWidget {
  final String adminName;
  final String adminRole;
  final VoidCallback onLogout;
  final VoidCallback? onMenuPressed;

  const AdminTopBar({
    super.key,
    this.adminName = "Admin",
    this.adminRole = "Administrator",
    required this.onLogout,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(
          bottom: BorderSide(color: AdminColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: AdminColors.textPrimary),
              onPressed: onMenuPressed,
            ),
            const Spacer(),
          ],

          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AdminColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 16),

          // Divider
          Container(height: 32, width: 1, color: AdminColors.border),
          const SizedBox(width: 16),

          // Profile Info
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(adminName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminColors.textPrimary)),
                  Text(adminRole, style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)), // ← Dynamic
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(radius: 18, backgroundColor: AdminColors.primary, child: Icon(Icons.person, color: Colors.white, size: 20)),
            ],
          ),
        ],
      ),
    );
  }
}