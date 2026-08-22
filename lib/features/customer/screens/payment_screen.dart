// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:saloon_app/core/theme/app_colors.dart';
// import 'package:saloon_app/core/theme/app_gradients.dart';
// import 'package:saloon_app/core/theme/app_text_styles.dart';
// import 'package:saloon_app/core/theme/theme_helper.dart';
// import 'package:saloon_app/core/constants/app_radius.dart';
// import 'package:saloon_app/features/customer/screens/success_screen.dart';
//
// class PaymentScreen extends StatefulWidget {
//   final Map<String, dynamic> bookingData;
//
//   const PaymentScreen({super.key, required this.bookingData,});
//
//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }
//
// class _PaymentScreenState extends State<PaymentScreen> {
//   String _selectedMethod = 'easypaisa';
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = ThemeHelper(context);
//     final salon = widget.bookingData['salon'];
//     final date = widget.bookingData['date'] as DateTime;
//     final time = widget.bookingData['time'];
//     final staff = widget.bookingData['staff'];
//
//     // Mock calculations
//     const double totalAmount = 1500.0;
//     const double advanceAmount = totalAmount * 0.5;
//
//     return Scaffold(
//       backgroundColor: theme.backgroundColor,
//       appBar: AppBar(
//         title: Text('payment'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: theme.cardColor,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: theme.borderColor),
//             ),
//             child: Icon(Icons.arrow_back_rounded, color: theme.textColor, size: 20),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── Booking Summary Card ──
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: theme.cardColor,
//                 borderRadius: BorderRadius.circular(AppRadius.xxl),
//                 boxShadow: [theme.softShadow],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         height: 60, width: 60,
//                         decoration: BoxDecoration(
//                           color: theme.lightPinkColor,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Icon(Icons.storefront_rounded, color: AppColors.primaryPink),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(salon['name'], style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor)),
//                             Text(salon['distance'], style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 16),
//                     child: Divider(),
//                   ),
//                   _summaryRow(Icons.calendar_today_rounded, 'date'.tr, '${date.day} ${_getMonth(date.month)}, ${date.year}', theme),
//                   const SizedBox(height: 12),
//                   _summaryRow(Icons.access_time_rounded, 'time'.tr, time, theme),
//                   const SizedBox(height: 12),
//                   _summaryRow(Icons.person_outline_rounded, 'staff_info'.tr, staff['name'], theme),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 32),
//
//             // ── Price Breakdown ──
//             Text('price_details'.tr, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: theme.cardColor,
//                 borderRadius: BorderRadius.circular(AppRadius.lg),
//                 border: Border.all(color: theme.borderColor),
//               ),
//               child: Column(
//                 children: [
//                   _priceRow('service_total'.tr, 'Rs. $totalAmount', false, theme),
//                   const SizedBox(height: 12),
//                   _priceRow('advance_payment'.tr, 'Rs. $advanceAmount', true, theme),
//                   const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     child: Divider(),
//                   ),
//                   _priceRow('payable_now'.tr, 'Rs. $advanceAmount', true, theme, isTotal: true),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 32),
//
//             // ── Payment Methods ──
//             Text('payment_method'.tr, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
//             const SizedBox(height: 16),
//             _methodTile('easypaisa', 'EasyPaisa', 'assets/google.png', theme),
//             const SizedBox(height: 12),
//             _methodTile('jazzcash', 'JazzCash', 'assets/google.png', theme),
//             const SizedBox(height: 12),
//             _methodTile('wallet', 'app_wallet'.tr, null, theme, icon: Icons.account_balance_wallet_rounded),
//
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: theme.cardColor,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, -5),
//             ),
//           ],
//         ),
//         child: GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const SuccessScreen(
//                 bookingId: 'PENDING-PAYMENT',
//                 dateTime: 'N/A',
//               )),
//             );
//           },
//           child: Container(
//             height: 56,
//             decoration: BoxDecoration(
//               gradient: AppGradients.primary,
//               borderRadius: BorderRadius.circular(AppRadius.button),
//             ),
//             child: Center(
//               child: Text(
//                 '${'pay'.tr} Rs. $advanceAmount',
//                 style: AppTextStyles.buttonText?.copyWith(fontSize: 16),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _summaryRow(IconData icon, String label, String value, ThemeHelper theme) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: theme.mutedTextColor),
//         const SizedBox(width: 8),
//         Text(label, style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor)),
//         const Spacer(),
//         Text(value, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
//       ],
//     );
//   }
//
//   Widget _priceRow(String label, String amount, bool isPink, ThemeHelper theme, {bool isTotal = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: isTotal
//               ? AppTextStyles.headingSmall.copyWith(color: theme.textColor)
//               : AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor),
//         ),
//         Text(
//           amount,
//           style: isTotal
//               ? AppTextStyles.headingMedium?.copyWith(color: AppColors.primaryPink)
//               : AppTextStyles.bodyMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: isPink ? AppColors.primaryPink : theme.textColor,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _methodTile(String id, String name, String? asset, ThemeHelper theme, {IconData? icon}) {
//     final isSelected = _selectedMethod == id;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedMethod = id),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primaryPink.withOpacity(0.05) : theme.cardColor,
//           borderRadius: BorderRadius.circular(AppRadius.lg),
//           border: Border.all(
//             color: isSelected ? AppColors.primaryPink : theme.borderColor,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               height: 40, width: 40,
//               decoration: BoxDecoration(
//                 color: theme.lightPinkColor,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: asset != null
//                   ? Padding(padding: const EdgeInsets.all(8), child: Image.asset(asset))
//                   : Icon(icon, color: AppColors.primaryPink, size: 20),
//             ),
//             const SizedBox(width: 16),
//             Text(
//               name,
//               style: AppTextStyles.bodyLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.textColor,
//               ),
//             ),
//             const Spacer(),
//             Container(
//               height: 20, width: 20,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: isSelected ? AppColors.primaryPink : theme.borderColor,
//                   width: isSelected ? 6 : 2,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _getMonth(int month) {
//     const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     return months[month - 1];
//   }
// }