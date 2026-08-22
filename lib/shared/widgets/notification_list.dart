import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_helper.dart';

// Shared, Firestore-backed notification list used by both the customer
// and owner notification screens. Reads real docs from the 'notifications'
// collection instead of hardcoded fake data.
class NotificationsList extends StatelessWidget {
  final String userId;

  const NotificationsList({super.key, required this.userId});

  static Map<String, dynamic> _visualsForType(String type) {
    switch (type) {
      case 'booking_confirmed':
        return {'icon': Icons.check_circle_rounded, 'bg': AppColors.successBg, 'color': AppColors.success};
      case 'booking_cancelled':
        return {'icon': Icons.cancel_rounded, 'bg': const Color(0xFFFFF0F0), 'color': Colors.red};
      case 'reminder':
        return {'icon': Icons.alarm_rounded, 'bg': AppColors.lightPink, 'color': AppColors.primaryPink};
      case 'review':
        return {'icon': Icons.star_rounded, 'bg': const Color(0xFFFFF8E1), 'color': Colors.amber};
      case 'offer':
        return {'icon': Icons.local_offer_rounded, 'bg': AppColors.lightPink, 'color': AppColors.primaryPink};
      case 'payment':
        return {'icon': Icons.account_balance_wallet_rounded, 'bg': AppColors.successBg, 'color': AppColors.success};
      default:
        return {'icon': Icons.notifications_rounded, 'bg': AppColors.lightPink, 'color': AppColors.primaryPink};
    }
  }

  static String _relativeTime(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'just_now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${'min_ago'.tr}';
    if (diff.inHours < 24) return '${diff.inHours} ${'hr_ago'.tr}';
    if (diff.inDays == 1) return 'yesterday'.tr;
    if (diff.inDays < 7) return '${diff.inDays} ${'days_ago'.tr}';
    return '${(diff.inDays / 7).floor()} ${'weeks_ago'.tr}';
  }

  Future<void> _markAllRead(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      if ((doc.data() as Map<String, dynamic>)['read'] != true) {
        batch.update(doc.reference, {'read': true});
      }
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
        }

        final docs = snapshot.data?.docs ?? [];
        final unreadCount = docs.where((d) => (d.data() as Map<String, dynamic>)['read'] != true).length;

        return Column(
          children: [
            Container(
              color: theme.cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('notifications'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor, fontSize: 18)),
                  if (unreadCount > 0)
                    GestureDetector(
                      onTap: () => _markAllRead(docs),
                      child: Text('mark_all_read'.tr, style: AppTextStyles.linkText),
                    ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 48, color: theme.borderColor),
                    const SizedBox(height: 12),
                    Text('no_notifications'.tr, style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final n = doc.data() as Map<String, dynamic>;
                  final unread = n['read'] != true;
                  final visuals = _visualsForType(n['type'] ?? '');

                  return GestureDetector(
                    onTap: () {
                      if (unread) doc.reference.update({'read': true});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: unread
                            ? const Border(left: BorderSide(color: AppColors.primaryPink, width: 3))
                            : null,
                        boxShadow: [theme.softShadow],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: visuals['bg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(visuals['icon'] as IconData, size: 20, color: visuals['color'] as Color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n['title'] ?? '',
                                  style: AppTextStyles.cardTitle?.copyWith(
                                    color: theme.textColor,
                                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  n['body'] ?? '',
                                  style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _relativeTime(n['createdAt'] as Timestamp?),
                                style: AppTextStyles.label?.copyWith(fontSize: 9, color: theme.mutedTextColor),
                              ),
                              if (unread) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}