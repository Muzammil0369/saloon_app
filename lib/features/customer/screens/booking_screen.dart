import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';
import 'package:saloon_app/features/customer/screens/payment_screen.dart';
import 'package:saloon_app/features/customer/widgets/booking_date_chip.dart';
import 'package:saloon_app/features/customer/widgets/time_slot_chip.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> salon;

  const BookingScreen({super.key, required this.salon});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '';
  int _selectedStaffIndex = 0;

  final List<String> morningSlots = ['09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM'];
  final List<String> afternoonSlots = ['12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM', '02:00 PM', '03:00 PM', '04:00 PM'];
  final List<String> eveningSlots = ['05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM', '09:00 PM'];

  final List<Map<String, String>> staffMembers = [
    {'name': 'Ahmed Ali', 'role': 'Senior Stylist', 'image': 'assets/google.png'},
    {'name': 'Sara Khan', 'role': 'Hair Expert', 'image': 'assets/google.png'},
    {'name': 'Zaid Shah', 'role': 'Beard Master', 'image': 'assets/google.png'},
    {'name': 'Any One', 'role': 'Quickest Available', 'image': 'assets/google.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('Book Appointment', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.borderColor),
            ),
            child: Icon(Icons.arrow_back_rounded, color: theme.textColor, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date Selection ──
            Text('Select Date', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 14, // Next 14 days
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDate.day == date.day && 
                                   _selectedDate.month == date.month;
                  return BookingDateChip(
                    date: date,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedDate = date),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // ── Time Slots ──
            Text('Select Time', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
            const SizedBox(height: 16),
            
            _buildTimeSection('Morning', morningSlots, Icons.wb_sunny_rounded, Colors.orange),
            const SizedBox(height: 20),
            _buildTimeSection('Afternoon', afternoonSlots, Icons.sunny, Colors.amber),
            const SizedBox(height: 20),
            _buildTimeSection('Evening', eveningSlots, Icons.nightlight_round, Colors.indigo),

            const SizedBox(height: 32),

            // ── Staff Selection ──
            Text('Choose Staff', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: staffMembers.length,
                itemBuilder: (context, index) {
                  final staff = staffMembers[index];
                  final isSelected = _selectedStaffIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStaffIndex = index),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryPink.withOpacity(0.05) : theme.cardColor,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryPink : theme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: theme.lightPinkColor,
                            child: const Icon(Icons.person_rounded, color: AppColors.primaryPink),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            staff['name']!,
                            style: AppTextStyles.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            staff['role']!,
                            style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // ── Advance Payment Note ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'To confirm your booking, a 50% advance payment is required.',
                      style: AppTextStyles.bodySmall?.copyWith(color: theme.isDark ? Colors.blue[200] : Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 100), // Bottom padding for sticky button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            if (_selectedTime.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a time slot')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  bookingData: {
                    'salon': widget.salon,
                    'date': _selectedDate,
                    'time': _selectedTime,
                    'staff': staffMembers[_selectedStaffIndex],
                  },
                ),
              ),
            );
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed to Payment',
                    style: AppTextStyles.buttonText?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection(String title, List<String> slots, IconData icon, Color color) {
    final theme = ThemeHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((time) => TimeSlotChip(
            time: time,
            isSelected: _selectedTime == time,
            onTap: () => setState(() => _selectedTime = time),
          )).toList(),
        ),
      ],
    );
  }
}
