import 'package:flutter/material.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';

class AdminWidgets {
  static Widget statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'success':
        color = AdminColors.success;
        break;
      case 'pending':
      case 'processing':
        color = AdminColors.warning;
        break;
      case 'rejected':
      case 'failed':
      case 'danger':
        color = AdminColors.danger;
        break;
      default:
        color = AdminColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget searchBar({required TextEditingController controller, String hint = "Search...", Function(String)? onChanged}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20, color: AdminColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
