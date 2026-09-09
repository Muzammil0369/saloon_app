import 'package:flutter/material.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';

class AdminWidgets {
  static Widget statusChip(String status) {
    Color color;
    String displayText = status;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'success':
        color = Colors.green;
        displayText = '✅ Completed';
        break;
      case 'pending':
      case 'processing':
        color = Colors.orange;
        displayText = '⏳ Pending';
        break;
      case 'rejected':
      case 'failed':
        color = Colors.red;
        displayText = '❌ Failed';
        break;
      case 'cancelled':
        color = Colors.red;
        displayText = '❌ Cancelled';
        break;
      default:
        color = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 11,
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