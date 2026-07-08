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

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: theme.backgroundColor, // Changed to theme.backgroundColor
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text('Schedule', style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: selected ? AppGradients.primary : null,
                        color: selected ? null : theme.lightPinkColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${date.day}', style: AppTextStyles.headingSmall?.copyWith(color: selected ? Colors.white : theme.textColor)),
                          Text(date.weekday == DateTime.now().weekday ? 'Today' : '', style: AppTextStyles.label.copyWith(color: selected ? Colors.white70 : theme.mutedTextColor)),
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
                  if (bookings.isEmpty) return Center(child: Text('No bookings for ${_selectedDate.day}/${_selectedDate.month}', style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)));

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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20), // More rounded
        boxShadow: [theme.softShadow], // Consistent shadow
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(time.split(' ').first, style: AppTextStyles.headingSmall?.copyWith(color: AppColors.primaryPink)),
            Text(time.split(' ').last, style: AppTextStyles.label?.copyWith(color: AppColors.primaryPink)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.textColor)),
            const SizedBox(height: 4),
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
