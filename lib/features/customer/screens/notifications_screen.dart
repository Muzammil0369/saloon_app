import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'icon':    Icons.check_circle_rounded,
      'iconBg':  AppColors.successBg,
      'iconColor': AppColors.success,
      'title':   'Booking Confirmed',
      'body':    'Your slot at Royal Cuts Studio for 10:00 AM has been confirmed.',
      'time':    '2 min ago',
      'unread':  true,
    },
    {
      'icon':    Icons.alarm_rounded,
      'iconBg':  AppColors.lightPink,
      'iconColor': AppColors.primaryPink,
      'title':   'Reminder',
      'body':    'Your appointment at Royal Cuts is in 1 hour. Get ready!',
      'time':    '1 hr ago',
      'unread':  true,
    },
    {
      'icon':    Icons.star_rounded,
      'iconBg':  const Color(0xFFFFF8E1),
      'iconColor': Colors.amber,
      'title':   'Leave a Review',
      'body':    'How was your visit to The Barber Guild? Share your experience.',
      'time':    'Yesterday',
      'unread':  false,
    },
    {
      'icon':    Icons.local_offer_rounded,
      'iconBg':  AppColors.lightPink,
      'iconColor': AppColors.primaryPink,
      'title':   'Weekend Offer! 🎁',
      'body':    '30% off on all facials this weekend at Glamour Zone.',
      'time':    '2 days ago',
      'unread':  false,
    },
    {
      'icon':    Icons.account_balance_wallet_rounded,
      'iconBg':  AppColors.successBg,
      'iconColor': AppColors.success,
      'title':   'Payment Received',
      'body':    'Rs.700 via EasyPaisa confirmed for Royal Cuts Studio.',
      'time':    '3 days ago',
      'unread':  false,
    },
    {
      'icon':    Icons.cancel_rounded,
      'iconBg':  const Color(0xFFFFF0F0),
      'iconColor': Colors.red,
      'title':   'Booking Cancelled',
      'body':    'Your booking at Elite Hair Studio has been cancelled.',
      'time':    '5 days ago',
      'unread':  false,
    },
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n['unread'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final unreadCount = _notifications.where((n) => n['unread'] == true).length;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // TopBar
            Container(
              color: theme.cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('notifications'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor, fontSize: 18)),
                  if (unreadCount > 0)
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Text('mark_all_read'.tr, style: AppTextStyles.linkText),
                    ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _notifications.isEmpty
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
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  final unread = n['unread'] as bool;

                  return GestureDetector(
                    onTap: () {
                      setState(() => n['unread'] = false);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: unread
                            ? Border(left: BorderSide(color: AppColors.primaryPink, width: 3))
                            : null,
                        boxShadow: [theme.softShadow],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: n['iconBg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              n['icon'] as IconData,
                              size: 20,
                              color: n['iconColor'] as Color,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n['title'],
                                  style: AppTextStyles.cardTitle?.copyWith(
                                    color: theme.textColor,
                                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  n['body'],
                                  style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // time + unread dot
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                n['time'],
                                style: AppTextStyles.label?.copyWith(fontSize: 9, color: theme.mutedTextColor),
                              ),
                              if (unread) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryPink,
                                    shape: BoxShape.circle,
                                  ),
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
        ),
      ),
    );
  }
}