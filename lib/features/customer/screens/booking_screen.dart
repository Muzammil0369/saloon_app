import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/controllers/booking_controller.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/features/customer/screens/success_screen.dart';
import '../../../core/services/auth_service.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> salon;
  final String ownerId; // Add ownerId parameter

  const BookingScreen({
    super.key,
    required this.salon,
    required this.ownerId, // Make it required
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingController _bookingController = Get.find<BookingController>();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '10:00 AM', '11:00 AM', '12:00 PM', '01:00 PM',
    '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Date', style: AppTextStyles.headingMedium),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 7)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primaryPink,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text('Select Time', style: AppTextStyles.headingMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTime == time;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryPink : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryPink : theme.borderColor,
                      ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.textColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            AppButton(
              label: 'Confirm Booking',
              onTap: (_selectedDay != null && _selectedTime != null)
                  ? _submitBooking
                  : () => Get.snackbar('Required', 'Please select date and time'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitBooking() async {
    setState(() => _isLoading = true);

    final authService = Get.find<AuthService>();
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

    final bookingData = {
      'bookingId': bookingRef.id,
      'customerId': authService.uid,
      'ownerId': widget.ownerId, // Use ownerId directly
      'salonName': widget.salon['name'] ?? 'Unnamed Salon',
      'services': _bookingController.selectedServices,
      'totalPrice': _bookingController.totalPrice.toInt(),
      'date': Timestamp.fromDate(_selectedDay!),
      'timeSlot': _selectedTime,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await bookingRef.set(bookingData);
      setState(() => _isLoading = false);

      Get.to(() => SuccessScreen(
        bookingId: bookingRef.id,
        dateTime: '${_selectedDay!.toString().split(' ')[0]} · $_selectedTime',
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to book: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}