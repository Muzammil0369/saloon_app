// // lib/shared/screens/wallet_screen.dart
// // Replace with real-time Firestore data
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:saloon_app/core/theme/app_colors.dart';
// import 'package:saloon_app/core/services/auth_service.dart';
//
// class WalletScreen extends StatelessWidget {
//   const WalletScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final userId = Get.find<AuthService>().uid ?? '';
//
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text('My Wallet'),
//         backgroundColor: Colors.white,
//       ),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: FirebaseFirestore.instance.collection('wallets').doc(userId).snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData || !snapshot.data!.exists) {
//             return const Center(child: Text('No wallet found'));
//           }
//
//           final data = snapshot.data!.data() as Map<String, dynamic>;
//           final balance = (data['balance'] ?? 0.0).toDouble();
//           final totalSpent = (data['totalSpent'] ?? 0.0).toDouble();
//
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 // Balance Card
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [AppColors.primaryPink, Color(0xFFA0204A)],
//                     ),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Column(
//                     children: [
//                       const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
//                       const SizedBox(height: 8),
//                       Text('Rs. ${balance.toStringAsFixed(0)}',
//                           style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Stats Row
//                 Row(
//                   children: [
//                     Expanded(child: _statCard('Total Spent', 'Rs. ${totalSpent.toStringAsFixed(0)}', Colors.blue)),
//                     const SizedBox(width: 12),
//                     Expanded(child: _statCard('Bookings', '0', Colors.green)),
//                   ],
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _statCard(String title, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         children: [
//           Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
//           Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }