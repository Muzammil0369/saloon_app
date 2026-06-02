import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';

class OwnerScheduleScreen extends StatefulWidget {
  const OwnerScheduleScreen({super.key});
  @override
  State<OwnerScheduleScreen> createState() => _OwnerScheduleScreenState();
}

class _OwnerScheduleScreenState extends State<OwnerScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final ownerId = Get.find<AuthService>().uid;

    // Helper to get start and end of selected day for Firestore query
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text('Schedule', style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Picker (Simplified)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: theme.cardColor,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, i) {
                  final date = DateTime.now().add(Duration(days: i));
                  final selected = isSameDay(_selectedDate, date);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: selected ? AppGradients.primary : null,
                        color: selected ? null : theme.lightPinkColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${date.day}', style: AppTextStyles.headingSmall?.copyWith(color: selected ? Colors.white : theme.textColor)),
                          Text(date.weekday == DateTime.now().weekday ? 'Today' : '${date.day}', style: AppTextStyles.label.copyWith(color: selected ? Colors.white70 : theme.mutedTextColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('ownerId', isEqualTo: ownerId)
                    .where('status', isEqualTo: 'confirmed')
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                    .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  final bookings = snapshot.data!.docs;
                  if (bookings.isEmpty) return const Center(child: Text('No confirmed bookings for this day.'));

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final data = bookings[index].data() as Map<String, dynamic>;
                      return _bookingCard(data, theme);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> data, ThemeHelper theme) {
    final time = data['timeSlot'] ?? '';
    final name = data['customerName'] ?? 'Customer';
    final services = (data['services'] as List).map((s) => s['name']).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: AppColors.primaryPink, width: 4)),
        boxShadow: [theme.softShadow],
      ),
      child: Row(children: [
        Text(time, style: AppTextStyles.headingSmall?.copyWith(color: AppColors.primaryPink)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor)),
            Text(services, style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
          ]),
        ),
      ]),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
