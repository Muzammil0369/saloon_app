import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/shared/widgets/notification_list.dart';

import '../../../core/theme/theme_helper.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final uid = Get.find<AuthService>().uid ?? "";

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(child: NotificationsList(userId: uid)),
    );
  }
}
