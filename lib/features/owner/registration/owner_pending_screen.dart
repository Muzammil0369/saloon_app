// lib/features/owner/registration/owner_pending_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/features/owner/owner_main_wrapper.dart';
import 'package:saloon_app/core/services/auth_service.dart';

class OwnerPendingScreen extends StatefulWidget {
  const OwnerPendingScreen({super.key});

  @override
  State<OwnerPendingScreen> createState() => _OwnerPendingScreenState();
}

class _OwnerPendingScreenState extends State<OwnerPendingScreen> {
  bool _isChecking = true;
  String _statusMessage = 'Checking status...';

  @override
  void initState() {
    super.initState();
    _checkOwnerStatus();
  }

  Future<void> _checkOwnerStatus() async {
    final uid = Get.find<AuthService>().uid;
    if (uid == null) return;

    try {
      // First check immediately
      final doc = await FirebaseFirestore.instance
          .collection('owners')
          .doc(uid)
          .get();

      if (doc.exists) {
        final status = doc.data()?['status'] as String?;
        print('OwnerPendingScreen: Status = $status');

        if (status == 'approved') {
          // ✅ Already approved! Redirect immediately
          print('OwnerPendingScreen: Already approved, redirecting to main');
          Get.offAll(() => const OwnerMainWrapper());
          return;
        } else {
          setState(() {
            _isChecking = false;
            _statusMessage = 'application_under_review'.tr;
          });
        }
      }

      // Listen for status changes in real-time
      FirebaseFirestore.instance
          .collection('owners')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final status = snapshot.data()?['status'] as String?;
          if (status == 'approved') {
            Get.offAll(() => const OwnerMainWrapper());
          }
        }
      });

    } catch (e) {
      print('OwnerPendingScreen error: $e');
      setState(() {
        _isChecking = false;
        _statusMessage = 'error_checking_status'.tr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isChecking
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text('verification_pending'.tr,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_statusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await Get.find<AuthService>().logout();
                Get.offAllNamed('/auth-gate');
              },
              child: Text('logout'.tr),
            ),
          ],
        ),
      ),
    );
  }
}