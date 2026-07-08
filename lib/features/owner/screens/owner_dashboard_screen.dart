import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const OwnerDashboardScreen({super.key, required this.onTabChange});
  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final ownerId = Get.find<AuthService>().uid;

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('owners').doc(ownerId).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            return Row(
              children: [
                Container(
                  height: 48, width: 48,
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data?['salonName'] ?? 'My Salon', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
                      Text(data?['address'] ?? 'Location', style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Icon(Icons.circle, color: AppColors.success, size: 6),
                    const SizedBox(width: 4),
                    Text(data?['isOpenNow'] == true ? 'Open' : 'Closed', style: AppTextStyles.label.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                  ]),
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
              // Stats Strip
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('owners').doc(ownerId).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  
                  return Row(
                    children: [
                      _statCard('Bookings', (data?['totalBookings'] ?? 0).toString(), Icons.calendar_month_rounded, theme),
                      const SizedBox(width: 12),
                      _statCard('Revenue', '${data?['walletBalance'] ?? 0}', Icons.payments_rounded, theme),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // Pending Requests Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Pending Requests", style: AppTextStyles.headingLarge?.copyWith(fontSize: 16, color: theme.textColor)),
                  GestureDetector(onTap: () => widget.onTabChange(1), child: Text('Manage All', style: AppTextStyles.linkText)),
                ],
              ),
              const SizedBox(height: 12),

              // Booking Stream
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('ownerId', isEqualTo: ownerId)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                  
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Text('No pending requests');

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

  Widget _statCard(String title, String value, IconData icon, ThemeHelper theme) {
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
                Icon(icon, color: AppColors.primaryPink, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.headingLarge.copyWith(color: theme.textColor)),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(children: [
      Text(value, style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
      const SizedBox(height: 4),
      Text(label, style: AppTextStyles.label.copyWith(color: Colors.white70)),
    ]);
  }

  Widget _appointmentCard(Map<String, dynamic> data, ThemeHelper theme, String docId) {
    final date = (data['date'] as Timestamp).toDate();
    final time = data['timeSlot'] ?? '';
    final name = data['customerName'] ?? 'Customer';
    final service = (data['services'] as List).isNotEmpty ? data['services'][0]['name'] : 'Service';

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
            Text(time.split(' ')[0], style: AppTextStyles.headingSmall?.copyWith(color: AppColors.primaryPink)),
            Text(time.split(' ')[1], style: AppTextStyles.label?.copyWith(color: AppColors.primaryPink)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 2),
            Text(service, style: AppTextStyles.taglineSmall?.copyWith(color: theme.mutedTextColor)),
          ]),
        ),
        GestureDetector(
          onTap: () async {
            await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': 'confirmed'});
            Get.snackbar('Accepted', 'Booking confirmed!', backgroundColor: AppColors.success, colorText: Colors.white);
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
            await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': 'cancelled'});
            Get.snackbar('Rejected', 'Booking rejected', backgroundColor: Colors.redAccent, colorText: Colors.white);
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
