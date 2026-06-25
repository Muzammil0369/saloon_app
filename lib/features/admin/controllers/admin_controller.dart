import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';

class AdminController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stats
  var totalCustomers = 0.obs;
  var totalOwners = 0.obs;
  var totalAdmins = 0.obs;
  var pendingVerifications = 0.obs;
  var totalBookings = 0.obs;
  var totalRevenue = 0.0.obs;

  // Search
  var searchQuery = ''.obs;

  // Trends (Mock data for demonstration)
  var userTrend = "+12%".obs;
  var bookingTrend = "-5%".obs;
  var revenueTrend = "+24%".obs;

  @override
  void onInit() {
    super.onInit();
    _fetchStats();
  }

  // Settings Action
  void goToSettings() {
    Get.snackbar("Settings", "Settings functionality coming soon", snackPosition: SnackPosition.BOTTOM);
  }

  // Mock data for charts
  List<Map<String, dynamic>> getRevenueChartData() {
    return [
      {'day': 'Mon', 'amount': 1200.0},
      {'day': 'Tue', 'amount': 1500.0},
      {'day': 'Wed', 'amount': 1800.0},
      {'day': 'Thu', 'amount': 1400.0},
      {'day': 'Fri', 'amount': 2100.0},
      {'day': 'Sat', 'amount': 2500.0},
      {'day': 'Sun', 'amount': 1900.0},
    ];
  }

  void _fetchStats() {
    _getTotalCustomers();
    _getTotalOwners();
    _getTotalAdmins();
    _getPendingVerifications();
    _getTotalBookings();
    _getTotalRevenue();
  }

  Future<void> _getTotalCustomers() async {
    final snapshot = await _firestore.collection('users').where('role', isEqualTo: 'customer').get();
    totalCustomers.value = snapshot.docs.length;
  }

  Future<void> _getTotalOwners() async {
    final snapshot = await _firestore.collection('owners').get();
    totalOwners.value = snapshot.docs.length;
  }

  Future<void> _getTotalAdmins() async {
    final snapshot = await _firestore.collection('users').where('role', isEqualTo: 'admin').get();
    totalAdmins.value = snapshot.docs.length;
  }

  Future<void> _getPendingVerifications() async {
    final snapshot = await _firestore.collection('owners')
        .where('status', isEqualTo: 'pending')
        .get();
    pendingVerifications.value = snapshot.docs.length;
  }

  Future<void> _getTotalBookings() async {
    final snapshot = await _firestore.collection('bookings').get();
    totalBookings.value = snapshot.docs.length;
  }

  Future<void> _getTotalRevenue() async {
    // Assuming transactions collection holds amount
    final snapshot = await _firestore.collection('transactions').get();
    double revenue = 0;
    for (var doc in snapshot.docs) {
      revenue += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }
    totalRevenue.value = revenue;
  }

  // Admin Actions

  Future<String> _getCurrentAdminName() async {
    final uid = Get.find<AuthService>().uid;
    if (uid == null) return "Unknown Admin";
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['name'] ?? "Unknown Admin";
  }

  Future<void> verifySalon(String docId, bool approved) async {
    try {
      final adminName = await _getCurrentAdminName();
      await _firestore.collection('owners').doc(docId).update({
        'status': approved ? 'approved' : 'rejected',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('audit_logs').add({
        'action': approved ? 'APPROVE_SALON' : 'REJECT_SALON',
        'targetId': docId,
        'timestamp': FieldValue.serverTimestamp(),
        'adminId': Get.find<AuthService>().uid,
        'actorName': adminName,
      });
  // ... (rest of function unchanged)

      Get.snackbar(
        approved ? 'Salon Approved' : 'Salon Rejected',
        approved ? 'The salon has been successfully verified.' : 'The salon has been rejected.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: approved ? Colors.green : Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to verify salon: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> processWithdrawal(String docId, bool approved) async {
    try {
      final adminName = await _getCurrentAdminName();
      await _firestore.collection('withdrawal_requests').doc(docId).update({
        'status': approved ? 'approved' : 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('audit_logs').add({
        'action': approved ? 'APPROVE_WITHDRAWAL' : 'REJECT_WITHDRAWAL',
        'targetId': docId,
        'timestamp': FieldValue.serverTimestamp(),
        'adminId': Get.find<AuthService>().uid,
        'actorName': adminName,
      });

      Get.snackbar(
        approved ? 'Withdrawal Approved' : 'Withdrawal Rejected',
        approved ? 'The payout has been processed successfully.' : 'The withdrawal request has been rejected.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: approved ? Colors.green : Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process withdrawal: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
