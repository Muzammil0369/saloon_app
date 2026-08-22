import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../shared/widgets/notification_list.dart';

class OwnerNotificationsScreen extends StatelessWidget {
  const OwnerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final uid = Get.find<AuthService>().uid ?? '';

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(child: NotificationsList(userId: uid)),
    );
  }
}