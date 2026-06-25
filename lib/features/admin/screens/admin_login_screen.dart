import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/features/admin/admin_main_wrapper.dart';

import '../../../core/constants/app_radius.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final dbService = Get.find<DatabaseService>();
    
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings, size: 64, color: AppColors.primaryPink),
                const SizedBox(height: 16),
                Text(
                  "Admin Portal",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please sign in to manage Glambook",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Admin Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // 1. Sign in with Firebase
                        await authService.signInWithEmail(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        );

                        // 2. Verify if the user is actually an admin
                        final uid = authService.uid;
                        if (uid != null) {
                          final userDoc = await dbService.getUserProfile(uid);
                          final data = userDoc.data() as Map<String, dynamic>?;
                          if (userDoc.exists && data?['role'] == 'admin') {
                            Get.offAllNamed('/admin-main');
                          } else {
                            // Not an admin, sign them out immediately
                            await authService.logout();
                            Get.snackbar(
                              "Access Denied",
                              "You do not have admin privileges.",
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        }
                      } catch (e) {
                        Get.snackbar(
                          "Login Failed",
                          e.toString(),
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: const Text("Login to Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
