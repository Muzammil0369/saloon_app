// lib/features/customer/screens/my_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/features/customer/screens/qr_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _selectedTab = 'upcoming';
  bool _isNavigating = false;

  String get _customerId => Get.find<AuthService>().uid ?? '';

  Stream<QuerySnapshot> _getBookings() {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: _customerId)
        .orderBy('createdAt', descending: true);

    if (_selectedTab == 'upcoming') {
      query = query.where('status', whereIn: ['pending', 'confirmed', 'in_progress']);
    } else if (_selectedTab == 'completed') {
      query = query.where('status', whereIn: ['completed', 'paid', 'verified']);
    } else if (_selectedTab == 'cancelled') {
      query = query.where('status', isEqualTo: 'cancelled');
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('my_bookings'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab('upcoming'.tr, 'upcoming'),
                _buildTab('completed'.tr, 'completed'),
                _buildTab('canceled'.tr, 'cancelled'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: theme.mutedTextColor),
                        const SizedBox(height: 16),
                        Text('no_bookings'.tr, style: TextStyle(color: theme.mutedTextColor)),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index].data() as Map<String, dynamic>;
                    final bookingId = bookings[index].id;
                    return _buildBookingCard(booking, bookingId, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String value) {
    final isSelected = _selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPink : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkMutedText : AppColors.mutedText),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, String bookingId, ThemeHelper theme) {
    final status = booking['status'] ?? 'pending';
    final salonName = booking['salonName'] ?? 'Salon';
    final services = booking['services'] as List? ?? [];
    final totalPrice = booking['totalPrice'] ?? 0;
    final date = (booking['date'] as Timestamp?)?.toDate();
    final timeSlot = booking['timeSlot'] ?? '';
    final paymentStatus = booking['paymentStatus'] ?? 'unpaid';
    final qrVerified = booking['qrVerified'] ?? false;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.grey;
        statusLabel = 'pending_status'.tr;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusLabel = 'confirmed_status'.tr;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusLabel = 'in_progress_status'.tr;
        statusIcon = Icons.cut;
        break;
      case 'completed':
        statusColor = const Color(0xFF7B1FA2);
        statusLabel = 'service_done'.tr;
        statusIcon = Icons.done_all;
        break;
      case 'paid':
        statusColor = Colors.green;
        statusLabel = 'paid_status'.tr;
        statusIcon = Icons.payment;
        break;
      case 'verified':
        statusColor = const Color(0xFF00C853);
        statusLabel = 'verified_status'.tr;
        statusIcon = Icons.verified;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusLabel = 'cancelled_status'.tr;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'unknown'.tr;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Salon Name + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    salonName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date & Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.lightPinkColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 13, color: AppColors.primaryPink),
                  const SizedBox(width: 6),
                  Text(
                    date != null ? DateFormat('dd MMM yyyy').format(date) : 'N/A',
                    style: TextStyle(color: AppColors.primaryPink, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 13, color: AppColors.primaryPink),
                  const SizedBox(width: 6),
                  Text(
                    timeSlot,
                    style: TextStyle(color: AppColors.primaryPink, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Services
            if (services.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: services.map<Widget>((s) {
                  final name = s is Map ? (s['name'] ?? s['serviceName'] ?? '') : s.toString();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),

            // Price + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs. $totalPrice',
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                // QR / Verified button
                if (paymentStatus == 'paid' || status == 'paid' || status == 'verified')
                  qrVerified == true || status == 'verified'
                      ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text('Verified', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                      : TextButton.icon(
                    onPressed: () {
                      if (_isNavigating) return;
                      _isNavigating = true;
                      Get.to(() => QRScreen(
                        bookingId: bookingId,
                        ownerId: booking['ownerId'] ?? '',
                      ))?.then((_) {
                        if (mounted) _isNavigating = false;
                      });
                    },
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: Text('show_qr'.tr, style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryPink,
                      backgroundColor: AppColors.lightPink,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}