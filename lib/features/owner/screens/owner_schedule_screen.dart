import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';

class OwnerScheduleScreen extends StatefulWidget {
  const OwnerScheduleScreen({super.key});
  @override
  State<OwnerScheduleScreen> createState() => _OwnerScheduleScreenState();
}

class _OwnerScheduleScreenState extends State<OwnerScheduleScreen> {
  int _selectedDay = 1;

  final List<Map<String, dynamic>> _slots = [
    {'time': '9:00',  'ampm': 'AM', 'name': 'Ali Hassan',  'service': 'Haircut · Rs.500',       'booked': true},
    {'time': '10:00', 'ampm': 'AM', 'name': 'Sara Khan',   'service': 'Bridal Pkg · Rs.8,000',  'booked': true},
    {'time': '11:00', 'ampm': 'AM', 'name': '',            'service': '',                        'booked': false},
    {'time': '12:00', 'ampm': 'PM', 'name': 'Bilal Ahmad', 'service': 'Facial · Rs.800',         'booked': true},
    {'time': '1:00',  'ampm': 'PM', 'name': '',            'service': '',                        'booked': false},
    {'time': '2:00',  'ampm': 'PM', 'name': 'Usman Tariq', 'service': 'Classic Cut · Rs.600',    'booked': true},
    {'time': '3:00',  'ampm': 'PM', 'name': '',            'service': '',                        'booked': false},
    {'time': '4:00',  'ampm': 'PM', 'name': 'Hina Shah',   'service': 'Hair Color · Rs.2,500',   'booked': true},
  ];

  final List<Map<String, String>> _days = [
    {'d': 'Mon', 'n': '28'}, {'d': 'Tue', 'n': '29'}, {'d': 'Wed', 'n': '30'},
    {'d': 'Thu', 'n': '31'}, {'d': 'Fri', 'n': '1'},  {'d': 'Sat', 'n': '2'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.cardColor,
        elevation: 0,
        titleSpacing: 20,
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Schedule', style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor)),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.add, color: AppColors.primaryPink, size: 14),
                const SizedBox(width: 4),
                Text('Block Time', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Week strip
              Row(
                children: List.generate(_days.length, (i) {
                  final selected = _selectedDay == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDay = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: selected ? AppGradients.primary : null,
                          color: selected ? null : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: selected ? [] : [theme.softShadow],
                        ),
                        child: Column(children: [
                          Text(_days[i]['d']!, style: AppTextStyles.label?.copyWith(color: selected ? Colors.white70 : theme.mutedTextColor)),
                          const SizedBox(height: 4),
                          Text(_days[i]['n']!, style: AppTextStyles.headingSmall?.copyWith(color: selected ? Colors.white : theme.textColor)),
                        ]),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Timeline slots
              ...List.generate(_slots.length, (i) {
                final slot = _slots[i];
                final booked = slot['booked'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: booked
                        ? Border(left: BorderSide(color: AppColors.primaryPink, width: 3))
                        : Border.all(color: theme.borderColor),
                    boxShadow: [theme.softShadow],
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: 48,
                      child: Text('${slot['time']} ${slot['ampm']}',
                          style: AppTextStyles.label?.copyWith(color: booked ? AppColors.primaryPink : theme.mutedTextColor, fontWeight: FontWeight.w700)),
                    ),
                    Container(width: 1, height: 36, color: theme.borderColor, margin: const EdgeInsets.symmetric(horizontal: 12)),
                    Expanded(
                      child: booked
                          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(slot['name']!, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor)),
                        const SizedBox(height: 2),
                        Text(slot['service']!, style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
                      ])
                          : Text('Available', style: AppTextStyles.label?.copyWith(color: theme.mutedTextColor)),
                    ),
                    if (booked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                        child: Text('Conf.', style: AppTextStyles.label.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                      ),
                  ]),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}