import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/services/auth_service.dart';

/// Asks the user to prove it is really them before their account is deleted.
/// Password accounts type their password; Google accounts pick their account.
/// Returns true when it is safe to continue with the deletion.
Future<bool> reauthenticateForDeletion() async {
  final auth = Get.find<AuthService>();
  String? error;

  if (auth.usesPasswordLogin) {
    final controller = TextEditingController();
    final password = await Get.dialog<String>(
      AlertDialog(
        title: Text('enter_password_to_confirm'.tr),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(hintText: 'password'.tr),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: controller.text),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) return false;
    error = await auth.reauthenticateWithPassword(password);
  } else {
    error = await auth.reauthenticateWithGoogle();
  }

  if (error != null) {
    if (error != 'Cancelled') {
      Get.snackbar('error'.tr, error,
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }
  return true;
}