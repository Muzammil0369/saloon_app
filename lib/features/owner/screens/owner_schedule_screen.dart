// lib/features/owner/screens/owner_schedule_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/controllers/payment_controller.dart';
import 'package:saloon_app/features/owner/screens/qr_scanner_screen.dart';
import 'package:intl/intl.dart';

class OwnerScheduleScreen extends StatefulWidget {
  const OwnerScheduleScreen({super.key});
  @override
  State<OwnerScheduleScreen> createState() => _OwnerScheduleScreenState();
}

class _OwnerScheduleScreenState extends State<OwnerScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  String get _ownerId => Get.find<AuthService>().uid ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text('schedule'.tr, style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date selector
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
                          Text('${date.day}', style: AppTextStyles.headingSmall?.copyWith(
                            color: selected ? Colors.white : theme.textColor,
                          )),
                          Text(
                            date.weekday == DateTime.now().weekday ? 'today'.tr : DateFormat('E').format(date),
                            style: AppTextStyles.label.copyWith(
                              color: selected ? Colors.white70 : theme.mutedTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bookings list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('ownerId', isEqualTo: _ownerId)
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                    .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                    .orderBy('date', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
                  }

                  final bookings = snapshot.data!.docs;
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 64, color: theme.mutedTextColor),
                          const SizedBox(height: 16),
                          Text(
                            '${'no_bookings_date'.tr} ${_selectedDate.day}/${_selectedDate.month}',
                            style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final data = bookings[index].data() as Map<String, dynamic>;
                      final bookingId = bookings[index].id;
                      return _buildBookingCard(data, bookingId, theme);
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

  Widget _customerAvatar(dynamic imageUrl, ThemeHelper theme) {
    final String url = (imageUrl ?? '').toString();
    final ImageProvider? provider = _getCustomerImageProvider(url);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightPink,
        image: provider != null ? DecorationImage(image: provider, fit: BoxFit.cover) : null,
      ),
      child: provider == null
          ? Icon(Icons.person, size: 16, color: AppColors.primaryPink)
          : null,
    );
  }

  ImageProvider? _getCustomerImageProvider(String url) {
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

  Widget _buildBookingCard(Map<String, dynamic> data, String bookingId, ThemeHelper theme) {
    final time = data['timeSlot'] ?? '';
    final name = data['customerName'] ?? 'Customer';
    final customerId = data['customerId'] ?? '';
    final status = data['status'] ?? 'pending';
    final paymentStatus = data['paymentStatus'] ?? 'unpaid';
    final paymentMethod = data['paymentMethod'] ?? '';
    final totalPrice = data['totalPrice'] ?? 0;
    final services = (data['services'] as List?)?.map((s) {
      if (s is Map) return s['name'] ?? s['serviceName'] ?? '';
      return s.toString();
    }).join(', ') ?? '';

    // Status color and label
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'pending':
        statusColor = Colors.grey;
        statusLabel = 'pending_status'.tr;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusLabel = 'confirmed_status'.tr;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusLabel = 'in_progress_status'.tr;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusLabel = 'completed'.tr;
        break;
      case 'paid':
        statusColor = Colors.green;
        statusLabel = 'paid_status'.tr;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusLabel = 'cancelled_status'.tr;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'unknown'.tr;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [theme.softShadow],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showBookingActions(data, bookingId, theme),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Time column
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.lightPinkColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      if ((data['staffName'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline, size: 13, color: AppColors.primaryPink),
                              const SizedBox(width: 4),
                              Text(
                                data['staffName'],
                                style: const TextStyle(
                                  color: AppColors.primaryPink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        time.split(' ').first,
                        style: AppTextStyles.headingSmall?.copyWith(color: AppColors.primaryPink),
                      ),
                      Text(
                        time.split(' ').last,
                        style: AppTextStyles.label?.copyWith(color: AppColors.primaryPink),
                      ),

                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _customerAvatar(data['customerImage'], theme),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: AppTextStyles.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        services,
                        style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Rs. ${totalPrice.toString()}',
                            style: TextStyle(
                              color: AppColors.primaryPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (paymentStatus == 'paid')
                            Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Paid via ${paymentMethod}',
                                  style: TextStyle(color: Colors.green, fontSize: 10),
                                ),
                              ],
                            ),
                          if (status == 'confirmed' || status == 'in_progress')
                            Icon(Icons.arrow_forward_ios, size: 14, color: theme.mutedTextColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Action buttons
            if (status == 'confirmed' || status == 'in_progress' || status == 'completed')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'confirmed')
                      _actionButton('accept'.tr, Colors.blue, () => _updateStatus(bookingId, 'in_progress')),
                    if (status == 'in_progress')
                      _actionButton('complete'.tr, Colors.purple, () => _updateStatus(bookingId, 'completed')),
                    if (status == 'completed' && paymentStatus != 'paid')
                      _actionButton('collect_payment'.tr, AppColors.primaryPink, () => _showPaymentSheet(
                        customerId: customerId,
                        bookingId: bookingId,
                        totalAmount: totalPrice.toDouble(),
                        customerName: name,
                      )),
                    const SizedBox(width: 8),
                    if (status != 'cancelled' && status != 'paid')
                      _actionButton('cancel'.tr, Colors.red, () => _updateStatus(bookingId, 'cancelled')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
    );
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar(
        'updated'.tr,
        '${'booking'.tr} ${newStatus.replaceAll('_', ' ')}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_update_status'.tr);
    }
  }

  void _showBookingActions(Map<String, dynamic> data, String bookingId, ThemeHelper theme) {
    final status = data['status'] ?? '';
    final paymentStatus = data['paymentStatus'] ?? '';
    final customerId = data['customerId'] ?? '';
    final totalPrice = data['totalPrice'] ?? 0;
    final name = data['customerName'] ?? 'Customer';

    // Only show bottom sheet for bookings needing action
    if (status == 'paid' || status == 'cancelled' || status == 'pending') return;

    if (status == 'completed' && paymentStatus != 'paid') {
      _showPaymentSheet(
        customerId: customerId,
        bookingId: bookingId,
        totalAmount: totalPrice.toDouble(),
        customerName: name,
      );
    }
  }

  void _showPaymentSheet({
    required String customerId,
    required String bookingId,
    required double totalAmount,
    required String customerName,
  }) {
    final paymentController = Get.find<PaymentController>();
    paymentController.selectedPaymentMethod.value = 'cash';

    final theme = ThemeHelper(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('collect_payment'.tr, style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor)),
            const SizedBox(height: 4),
            Text('${'customer'.tr}: $customerName', style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)),
            Text('${'total'.tr}: Rs. ${totalAmount.toStringAsFixed(0)}', style: AppTextStyles.headingLarge?.copyWith(
              color: AppColors.primaryPink, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 20),

            // Payment method selector
            Obx(() => Column(
              children: paymentController.salonPaymentMethods.map((method) {
                final isSelected = paymentController.selectedPaymentMethod.value == method['id'];
                return GestureDetector(
                  onTap: () => paymentController.selectedPaymentMethod.value = method['id'] as String,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.lightPink : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryPink : theme.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          method['id'] == 'cash' ? Icons.money :
                          method['id'] == 'wallet' ? Icons.account_balance_wallet : Icons.phone_android,
                          color: isSelected ? AppColors.primaryPink : theme.mutedTextColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(method['name'] as String, style: TextStyle(
                                fontWeight: FontWeight.w600, color: theme.textColor,
                              )),
                              Text(method['description'] as String, style: TextStyle(
                                fontSize: 11, color: theme.mutedTextColor,
                              )),
                            ],
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle, color: AppColors.primaryPink, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 20),

            // Confirm button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: paymentController.isPaymentProcessing.value ? null : () async {
                  final success = await paymentController.processSalonPayment(
                    customerId: customerId,
                    ownerId: _ownerId,
                    bookingId: bookingId,
                    totalAmount: totalAmount,
                    paymentMethod: paymentController.selectedPaymentMethod.value,
                  );
                  if (success) {
                    Get.back();
                    Get.snackbar('payment_confirmed'.tr, 'booking_marked_paid'.tr);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: paymentController.isPaymentProcessing.value
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : Text('confirm_payment'.tr, style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                )),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}