import 'package:get/get.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import 'wallet_controller.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final AuthService _authService = Get.find<AuthService>();
  final WalletController _walletController = Get.find<WalletController>();

  final RxBool isPaymentProcessing = false.obs;
  final RxString paymentStatus = ''.obs;
  final RxString selectedPaymentMethod = 'cash'.obs;

  // Payment methods available at salon
  final List<Map<String, dynamic>> salonPaymentMethods = [
    {'name': 'Cash', 'icon': 'money', 'id': 'cash', 'description': 'Pay cash at salon'},
    {'name': 'EasyPaisa', 'icon': 'easypaisa', 'id': 'easypaisa', 'description': 'Send via EasyPaisa'},
    {'name': 'JazzCash', 'icon': 'jazzcash', 'id': 'jazzcash', 'description': 'Send via JazzCash'},
  ];

  // Process payment at salon (called by owner after service)
  Future<bool> processSalonPayment({
    required String customerId,
    required String ownerId,
    required String bookingId,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    isPaymentProcessing.value = true;
    paymentStatus.value = 'processing';

    try {
      bool success = false;

      switch (paymentMethod) {
        case 'cash':
          success = await _paymentService.processCashPayment(
            customerId: customerId,
            ownerId: ownerId,
            bookingId: bookingId,
            totalAmount: totalAmount,
          );
          break;
        case 'easypaisa':
        case 'jazzcash':
          success = await _paymentService.processDigitalPayment(
            customerId: customerId,
            ownerId: ownerId,
            bookingId: bookingId,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
          );
          break;
        case 'wallet':
          if (!_walletController.canPay(totalAmount)) {
            paymentStatus.value = 'insufficient_balance';
            Get.snackbar(
              'Insufficient Balance',
              'Customer wallet balance is too low.',
              snackPosition: SnackPosition.BOTTOM,
            );
            return false;
          }
          success = await _paymentService.processWalletPayment(
            customerId: customerId,
            ownerId: ownerId,
            bookingId: bookingId,
            totalAmount: totalAmount,
          );
          break;
        default:
          success = false;
      }

      if (success) {
        paymentStatus.value = 'completed';
        await _walletController.loadWallet();
        Get.snackbar(
          'Payment Confirmed',
          'Booking marked as PAID.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        paymentStatus.value = 'failed';
        Get.snackbar('Payment Failed', 'Please try again.', snackPosition: SnackPosition.BOTTOM);
      }

      return success;
    } catch (e) {
      paymentStatus.value = 'error';
      print('Payment error: $e');
      return false;
    } finally {
      isPaymentProcessing.value = false;
    }
  }

  // Calculate payment breakdown for display
  Map<String, double> calculatePaymentBreakdown(double totalAmount, {double commissionRate = 15.0}) {
    final commissionAmount = totalAmount * (commissionRate / 100);
    final ownerGets = totalAmount - commissionAmount;

    return {
      'totalAmount': totalAmount,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'ownerGets': ownerGets,
    };
  }

  @override
  void onClose() {
    super.onClose();
  }
}