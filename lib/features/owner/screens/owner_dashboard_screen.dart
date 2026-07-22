// lib/features/owner/screens/owner_dashboard_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';

import '../../../core/controllers/language_controller.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const OwnerDashboardScreen({super.key, required this.onTabChange});
  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  String get _ownerId => Get.find<AuthService>().uid ?? '';

  // Stream booking stats
  Stream<Map<String, int>> _getBookingStats() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: _ownerId)
        .snapshots()
        .map((snapshot) {
      int total = snapshot.docs.length;
      int completed = snapshot.docs.where((d) {
        final status = d['status'] as String? ?? '';
        return status == 'paid' || status == 'completed';
      }).length;
      int pending = snapshot.docs.where((d) {
        final status = d['status'] as String? ?? '';
        return status == 'pending' || status == 'confirmed';
      }).length;
      return {'total': total, 'completed': completed, 'pending': pending};
    });
  }

  // Stream earnings from transactions
  Stream<double> _getEarnings() {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('metadata.ownerId', isEqualTo: _ownerId)
        .where('type', whereIn: ['cash_payment', 'digital_payment', 'wallet_payment'])
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0.0).toDouble();
      }
      return total;
    });
  }

  // Stream commission owed
  Stream<double> _getCommissionOwed() {
    return FirebaseFirestore.instance
        .collection('wallets')
        .doc(_ownerId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0.0;
      final data = doc.data()!;
      return (data['commissionOwed'] ?? 0.0).toDouble();
    });
  }

  ImageProvider? _getProfileImage(Map<String, dynamic> data) {
    final ownerImage = data['logo'] ?? data['ownerProfileImage'];
    if (ownerImage != null && ownerImage.toString().isNotEmpty) {
      if (ownerImage.toString().startsWith('http')) return NetworkImage(ownerImage);
      if (ownerImage.toString().startsWith('data:image')) {
        try { final bytes = base64Decode(ownerImage.toString().split(',').last); return MemoryImage(bytes); } catch (_) {}
      }
    }
    final salonPhotos = data['salonPhotos'];
    if (salonPhotos != null && salonPhotos is List && salonPhotos.isNotEmpty) {
      final firstPhoto = salonPhotos[0].toString();
      if (firstPhoto.startsWith('http')) return NetworkImage(firstPhoto);
      if (firstPhoto.startsWith('data:image')) {
        try { final bytes = base64Decode(firstPhoto.split(',').last); return MemoryImage(bytes); } catch (_) {}
      }
    }
    return null;
  }

  bool _hasNoImage(Map<String, dynamic> data) {
    final ownerImage = data['ownerProfileImage'];
    final salonPhotos = data['salonPhotos'];
    return (ownerImage == null || ownerImage.toString().isEmpty) && (salonPhotos == null || salonPhotos is! List || salonPhotos.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('owners').doc(_ownerId).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final languageController = Get.find<LanguageController>();

              return Row(
                children: [
                  // Avatar
                  Container(
                    height: 48,
                    width: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryPink, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryPink,
                      backgroundImage: data != null ? _getProfileImage(data!) : null,
                      child: data == null || _hasNoImage(data!)
                          ? const Icon(Icons.storefront_rounded, size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ✅ FIXED: Salon Name & Address with Dynamic Translation
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Salon Name - Dynamically translated
                          Obx(() => Text(
                            languageController.languageCode == 'ur'
                                ? (data?['salonName_ur'] ?? data?['salonName'] ?? 'my_salon'.tr)
                                : (data?['salonName'] ?? 'my_salon'.tr),
                            style: AppTextStyles.headingLarge?.copyWith(
                              fontSize: 18,
                              color: theme.textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )),
                          // Address - Dynamically translated
                          Obx(() => Text(
                            languageController.languageCode == 'ur'
                                ? (data?['address_ur'] ?? data?['address'] ?? 'location'.tr)
                                : (data?['address'] ?? 'location'.tr),
                            style: AppTextStyles.taglineSmall?.copyWith(
                              color: theme.mutedTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      ),
                    ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: AppColors.success, size: 6),
                        const SizedBox(width: 4),
                        Text(
                          data?['isOpenNow'] == true ? 'open'.tr : 'closed'.tr,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards - Real-time
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings').where('ownerId', isEqualTo: _ownerId).snapshots(),
                builder: (context, bookingSnap) {
                  final totalBookings = bookingSnap.data?.docs.length ?? 0;
                  final completedBookings = bookingSnap.data?.docs.where((d) {
                    final s = d['status'] as String? ?? '';
                    return s == 'paid' || s == 'completed';
                  }).length ?? 0;

                  return StreamBuilder<double>(
                    stream: _getEarnings(),
                    builder: (context, earningsSnap) {
                      final earnings = earningsSnap.data ?? 0.0;

                      return Row(
                        children: [
                          _statCard('bookings'.tr, '$completedBookings/$totalBookings', Icons.calendar_month_rounded, theme, AppColors.primaryPink),
                          const SizedBox(width: 12),
                          _statCard('earnings'.tr, 'Rs. ${earnings.toStringAsFixed(0)}', Icons.payments_rounded, theme, Colors.green),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<double>(
                stream: _getCommissionOwed(),
                builder: (context, snapshot) {
                  final commission = snapshot.data ?? 0.0;
                  return SizedBox(
                    width: double.infinity, // Full width instead of Expanded
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [theme.softShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.money_off, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text('commission_owed'.tr, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Rs. ${commission.toStringAsFixed(0)}',
                              style: AppTextStyles.headingLarge.copyWith(color: theme.textColor, fontSize: 22)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Today's Summary
              Text("todays_summary".tr, style: AppTextStyles.headingLarge?.copyWith(fontSize: 16, color: theme.textColor)),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('ownerId', isEqualTo: _ownerId)
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                    .where('date', isLessThan: Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1)))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final todayBookings = snapshot.data!.docs;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [theme.softShadow]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _todayStat('today'.tr, '${todayBookings.length}'),
                        _todayStat('confirmed'.tr, '${todayBookings.where((d) => d['status'] == 'confirmed').length}'),
                        _todayStat('done'.tr, '${todayBookings.where((d) => d['status'] == 'paid' || d['status'] == 'completed').length}'),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Pending Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("pending_requests".tr, style: AppTextStyles.headingLarge?.copyWith(fontSize: 16, color: theme.textColor)),
                  GestureDetector(onTap: () => widget.onTabChange(1), child: Text('manage_all'.tr, style: AppTextStyles.linkText)),
                ],
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('ownerId', isEqualTo: _ownerId)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text('no_pending_requests'.tr, style: TextStyle(color: theme.mutedTextColor))),
                  );

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _appointmentCard(data, theme, docs[index].id);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, ThemeHelper theme, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [theme.softShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.headingLarge.copyWith(color: theme.textColor, fontSize: 22)),
          ],
        ),
      ),
    );
  }

  Widget _todayStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _appointmentCard(Map<String, dynamic> data, ThemeHelper theme, String docId) {
    final date = (data['date'] as Timestamp?)?.toDate();
    final time = data['timeSlot'] ?? '';
    final name = data['customerName'] ?? 'customer'.tr;
    final services = data['services'] as List? ?? [];
    final serviceName = services.isNotEmpty ? (services[0] is Map ? (services[0]['name'] ?? 'Service') : 'Service') : 'Service';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [theme.softShadow],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(time.split(' ').first, style: AppTextStyles.headingSmall?.copyWith(color: AppColors.primaryPink)),
            Text(time.split(' ').length > 1 ? time.split(' ')[1] : '', style: AppTextStyles.label?.copyWith(color: AppColors.primaryPink)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 2),
            Text(serviceName, style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
          ]),
        ),
        GestureDetector(
          onTap: () async {
            await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
              'status': 'confirmed',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            Get.snackbar('accepted'.tr, 'booking_confirmed'.tr, backgroundColor: AppColors.success, colorText: Colors.white);
          },
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_rounded, size: 18, color: AppColors.success),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
              'status': 'cancelled',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            Get.snackbar('rejected'.tr, 'booking_rejected'.tr, backgroundColor: Colors.redAccent, colorText: Colors.white);
          },
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.primaryPink),
          ),
        ),
      ]),
    );
  }
}