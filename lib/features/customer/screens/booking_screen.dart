import 'dart:convert';
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
import 'package:saloon_app/core/controllers/user_controller.dart';
import '../../../core/services/auth_service.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> salon;
  final String ownerId;

  const BookingScreen({
    super.key,
    required this.salon,
    required this.ownerId,
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
  bool _isLoadingSlots = false;

  // Every 30-minute slot from 10:00 AM to 8:00 PM (salon has no configurable
  // business hours field yet, so this window is fixed for now)
  final List<String> _allTimeSlots = _generateTimeSlots();

  // For the selected day: timeSlot -> set of staffIds already booked at that time
  Map<String, Set<String>> _bookedStaffBySlot = {};

  // Full staff pool for this salon: owner (Ustad) + any workers, each with a stable id.
  // Sorted by each staff member's own rating (highest first) once that data exists —
  // defaults to 0 for everyone until the staff-rating feature is writing real values.
  late final List<Map<String, dynamic>> _staffPool = _buildStaffPool();

  String? _selectedStaffId;

  static List<String> _generateTimeSlots() {
    final List<String> slots = [];
    for (int minutes = 10 * 60; minutes < 20 * 60; minutes += 30) {
      final hour24 = minutes ~/ 60;
      final minute = minutes % 60;
      final period = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
      final minuteStr = minute.toString().padLeft(2, '0');
      slots.add('${hour12.toString().padLeft(2, '0')}:$minuteStr $period');
    }
    return slots;
  }

  // Groups the flat slot list into Morning / Afternoon / Evening sections for display
  Map<String, List<String>> get _groupedSlots {
    final Map<String, List<String>> groups = {'morning': [], 'afternoon': [], 'evening': []};
    for (var slot in _allTimeSlots) {
      final isPM = slot.contains('PM');
      final hour = int.parse(slot.split(':')[0]);
      if (!isPM) {
        groups['morning']!.add(slot);
      } else if (hour == 12 || hour < 4) {
        groups['afternoon']!.add(slot);
      } else {
        groups['evening']!.add(slot);
      }
    }
    return groups;
  }

  List<Map<String, dynamic>> _buildStaffPool() {
    final List<Map<String, dynamic>> pool = [];

    pool.add({
      'id': 'owner',
      'name': widget.salon['ownerName'] ?? widget.salon['fullName'] ?? 'owner'.tr,
      'imageUrl': widget.salon['ownerProfileImage'],
      'isOwner': true,
      'phone': widget.salon['phoneNumber'],
      'rating': (widget.salon['ownerStaffRating'] ?? 0.0).toDouble(),
    });

    final workers = widget.salon['workers'] as List? ?? [];
    for (var i = 0; i < workers.length; i++) {
      final w = workers[i] as Map<String, dynamic>;
      pool.add({
        'id': 'staff_$i',
        'name': w['name'] ?? 'Staff ${i + 1}',
        'imageUrl': w['profileImage'],
        'isOwner': false,
        'fatherName': w['fatherName'],
        'cnic': w['cnic'],
        'rating': (w['rating'] ?? 0.0).toDouble(),
      });
    }

    // Highest-rated staff first. Everyone defaults to 0 until real ratings exist,
    // in which case they keep their original (owner-first) order.
    pool.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    return pool;
  }

  ImageProvider? _getImageProvider(String url) {
    if (url.startsWith('http')) return NetworkImage(url);
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    print('DEBUG: BookingScreen initialized. Current discountRate: ${_bookingController.discountRate.value}');
    _selectedDay = DateTime.now();
    _loadBookedSlotsForDay(_selectedDay!);
  }

  Future<void> _loadBookedSlotsForDay(DateTime day) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null;
      _selectedStaffId = null;
    });

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: widget.ownerId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed', 'in_progress', 'completed', 'paid', 'verified'])
          .get();

      final Map<String, Set<String>> bookedMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String slot = data['timeSlot'] ?? '';
        // Legacy bookings made before staff selection existed have no staffId.
        // Treat those as occupying the owner's slot by default.
        final String staffId = data['staffId'] ?? 'owner';
        if (slot.isEmpty) continue;
        bookedMap.putIfAbsent(slot, () => <String>{}).add(staffId);
      }

      if (mounted) {
        setState(() {
          _bookedStaffBySlot = bookedMap;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSlots = false);
      debugPrint('Error loading booked slots: $e');
    }
  }

  bool _isSlotFullyBooked(String slot) {
    final bookedIds = _bookedStaffBySlot[slot] ?? <String>{};
    return bookedIds.length >= _staffPool.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(title: Text('book_appointment'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('select_date'.tr, style: AppTextStyles.headingMedium),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadBookedSlotsForDay(selectedDay);
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
            Text('select_time'.tr, style: AppTextStyles.headingMedium),
            const SizedBox(height: 16),

            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
            else
              ..._groupedSlots.entries.where((e) => e.value.isNotEmpty).map((entry) {
                final sectionIcon = switch (entry.key) {
                  'morning' => Icons.wb_twilight_rounded,
                  'afternoon' => Icons.wb_sunny_rounded,
                  _ => Icons.nightlight_round,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(sectionIcon, size: 16, color: AppColors.primaryPink),
                          const SizedBox(width: 6),
                          Text(
                            entry.key.tr,
                            style: TextStyle(fontWeight: FontWeight.w700, color: theme.mutedTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: entry.value.map((time) {
                          final isSelected = _selectedTime == time;
                          final isFull = _isSlotFullyBooked(time);

                          return GestureDetector(
                            onTap: isFull
                                ? null
                                : () => setState(() {
                              _selectedTime = time;
                              _selectedStaffId = null;
                            }),
                            child: Container(
                              width: 96,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isFull
                                    ? theme.borderColor.withOpacity(0.2)
                                    : (isSelected ? AppColors.primaryPink : theme.cardColor),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryPink : theme.borderColor,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: AppColors.primaryPink.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    time,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isFull ? theme.mutedTextColor : (isSelected ? Colors.white : theme.textColor),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isFull) ...[
                                    const SizedBox(height: 2),
                                    Text('slot_booked'.tr, style: TextStyle(fontSize: 9, color: theme.mutedTextColor)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),

            // Staff selection — only shown once a time slot is picked
            if (_selectedTime != null) ...[
              const SizedBox(height: 10),
              Text('select_staff'.tr, style: AppTextStyles.headingMedium),
              const SizedBox(height: 16),
              ..._staffPool.map((staff) {
                final bookedIds = _bookedStaffBySlot[_selectedTime!] ?? <String>{};
                final isBusy = bookedIds.contains(staff['id']);
                final isSelected = _selectedStaffId == staff['id'];
                final String? imageUrl = staff['imageUrl'];

                return GestureDetector(
                  onTap: isBusy ? null : () => setState(() => _selectedStaffId = staff['id']),
                  child: Opacity(
                    opacity: isBusy ? 0.5 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [theme.softShadow],
                        border: isSelected
                            ? Border.all(color: AppColors.primaryPink, width: 2)
                            : (staff['isOwner'] == true ? Border.all(color: AppColors.primaryPink.withOpacity(0.4), width: 1) : null),
                      ),
                      child: Row(
                        children: [
                          // Profile image, same style as owner_staff_screen
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: staff['isOwner'] == true ? AppColors.primaryPink : theme.borderColor,
                                width: 2,
                              ),
                              image: (imageUrl != null && imageUrl.isNotEmpty && _getImageProvider(imageUrl) != null)
                                  ? DecorationImage(image: _getImageProvider(imageUrl)!, fit: BoxFit.cover)
                                  : null,
                            ),
                            child: (imageUrl == null || imageUrl.isEmpty || _getImageProvider(imageUrl) == null)
                                ? Icon(
                              staff['isOwner'] == true ? Icons.star : Icons.person,
                              color: staff['isOwner'] == true ? AppColors.primaryPink : theme.mutedTextColor,
                            )
                                : null,
                          ),
                          const SizedBox(width: 14),

                          // Name + role + optional father/cnic
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        staff['name'],
                                        style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (staff['isOwner'] == true) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryPink.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('ustad'.tr, style: const TextStyle(fontSize: 9, color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  staff['isOwner'] == true ? 'ustad_owner'.tr : 'shagird_worker'.tr,
                                  style: AppTextStyles.label.copyWith(color: theme.mutedTextColor, fontSize: 11),
                                ),
                                if ((staff['rating'] as double) > 0) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        (staff['rating'] as double).toStringAsFixed(1),
                                        style: TextStyle(fontSize: 11, color: theme.mutedTextColor, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Free / Busy / Selected status
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppColors.primaryPink)
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (isBusy ? Colors.redAccent : Colors.green).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: (isBusy ? Colors.redAccent : Colors.green).withOpacity(0.3)),
                              ),
                              child: Text(
                                isBusy ? 'busy'.tr : 'free'.tr,
                                style: TextStyle(
                                  color: isBusy ? Colors.redAccent : Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 30),
            // Price Summary Section
            Obx(() => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.borderColor)),
              child: Column(
                children: [
                  _priceRow('subtotal'.tr, _bookingController.services.where((s) => s['isSelected'] == true).fold(0.0, (sum, s) => sum + (s['price'] as int)), false),
                  if (_bookingController.discountRate.value > 0)
                    _priceRow('${'discount'.tr} (${_bookingController.discountRate.value.toInt()}%)', 
                        _bookingController.services.where((s) => s['isSelected'] == true).fold(0.0, (sum, s) => sum + (s['price'] as int)) * (_bookingController.discountRate.value / 100), true),
                  const Divider(),
                  _priceRow('total'.tr, _bookingController.totalPrice, false, isTotal: true),
                ],
              ),
            )),
            const SizedBox(height: 40),
            Obx(() => AppButton(
              label: '${'confirm_booking'.tr} (Rs. ${_bookingController.totalPrice.toInt()})',
              onTap: (_selectedDay != null && _selectedTime != null && _selectedStaffId != null)
                  ? _submitBooking
                  : () => Get.snackbar('required'.tr, 'please_select'.tr),
            )),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double price, bool isDiscount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isDiscount ? Colors.green : null)),
          Text(
            '${isDiscount ? '-' : ''}Rs. ${price.toInt()}',
            style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isDiscount ? Colors.green : (isTotal ? AppColors.primaryPink : null)),
          ),
        ],
      ),
    );
  }

  void _submitBooking() async {
    setState(() => _isLoading = true);

    final authService = Get.find<AuthService>();
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
    final selectedStaff = _staffPool.firstWhere((s) => s['id'] == _selectedStaffId);

    final bookingData = {
      'bookingId': bookingRef.id,
      'customerId': authService.uid,
      'customerName': Get.find<UserController>().userName.value,
      'customerImage': Get.find<UserController>().userProfileImage.value,
      'ownerId': widget.ownerId,
      'salonName': widget.salon['salonName'] ?? widget.salon['name'] ?? 'Unnamed Salon',
      'services': _bookingController.selectedServices,
      'totalPrice': _bookingController.totalPrice.toInt(),
      'date': Timestamp.fromDate(DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)),
      'timeSlot': _selectedTime,
      'staffId': _selectedStaffId,
      'staffName': selectedStaff['name'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await bookingRef.set(bookingData);
      setState(() => _isLoading = false);
      _bookingController.discountRate.value = 0.0; // Reset discount
      
      Get.to(() => SuccessScreen(
        bookingId: bookingRef.id,
        dateTime: '${_selectedDay!.toString().split(' ')[0]} · $_selectedTime',
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'error'.tr,
        '${'failed_to_book'.tr}: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}