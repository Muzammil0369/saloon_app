import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_helper.dart';

// A bell icon with a live, real-time unread-count badge — used on both the
// customer home screen and the owner dashboard header.
class NotificationBell extends StatelessWidget {
  final String userId;
  final VoidCallback onTap;
  final ThemeHelper theme;

  const NotificationBell({
    super.key,
    required this.userId,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Single equality filter only — no composite index required.
      // (userId + read together would need one, and a missing index
      // fails silently in a StreamBuilder unless you check snapshot.hasError.)
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final unreadCount = docs.where((d) => (d.data() as Map<String, dynamic>)['read'] != true).length;

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [theme.softShadow],
                ),
                child: Icon(Icons.notifications_none_rounded, color: theme.textColor, size: 22),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}