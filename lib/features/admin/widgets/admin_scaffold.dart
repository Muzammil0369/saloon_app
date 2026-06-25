import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';

class AdminScaffold extends StatelessWidget {
  final Widget body;
  final String title;

  const AdminScaffold({super.key, required this.body, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
        backgroundColor: AdminColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AdminColors.danger),
            onPressed: () => Get.offAllNamed('/admin-login'),
          ),
        ],
      ),
      body: body,
    );
  }
}