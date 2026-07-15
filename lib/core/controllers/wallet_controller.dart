// lib/core/controllers/wallet_controller.dart
import 'package:get/get.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';

class WalletController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<WalletModel?> wallet = Rx<WalletModel?>(null);
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  final RxDouble balance = 0.0.obs;
  final RxDouble commissionOwed = 0.0.obs;

  String get userId => _authService.uid ?? '';
  String get userRole => _authService.userRole ?? 'customer';
  bool get isOwner => userRole == 'owner';
  bool get isCustomer => userRole == 'customer';

  @override
  void onInit() {
    super.onInit();
    loadWallet();
    loadTransactions();
  }

  Future<void> loadWallet() async {
    if (userId.isEmpty) return;

    isLoading.value = true;
    try {
      final walletData = await _paymentService.getOrCreateWallet(userId, userRole);
      wallet.value = walletData;
      balance.value = walletData.balance;
      commissionOwed.value = walletData.commissionOwed;
    } catch (e) {
      print('Error loading wallet: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void listenToWallet() {
    if (userId.isEmpty) return;

    _paymentService.streamWallet(userId).listen((walletData) {
      if (walletData != null) {
        wallet.value = walletData;
        balance.value = walletData.balance;
        commissionOwed.value = walletData.commissionOwed;
      }
    });
  }

  Future<void> loadTransactions() async {
    if (userId.isEmpty) return;

    try {
      _paymentService.streamUserTransactions(userId).listen((txns) {
        transactions.value = txns;
      });
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  // Top-up wallet (customer only)
  Future<bool> topUp(double amount, String paymentMethod) async {
    if (userId.isEmpty || !isCustomer) return false;

    isProcessing.value = true;
    try {
      final success = await _paymentService.topUpWallet(
        customerId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      if (success) {
        await loadWallet();
        Get.snackbar('Success', 'Wallet topped up successfully');
      } else {
        Get.snackbar('Error', 'Top-up failed. Please try again.');
      }

      return success;
    } catch (e) {
      Get.snackbar('Error', 'Top-up failed: $e');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  // Process withdrawal (owner only)
  Future<bool> withdraw(double amount, String paymentMethod, String accountDetails) async {
    if (userId.isEmpty || !isOwner) return false;

    isProcessing.value = true;
    try {
      final success = await _paymentService.processWithdrawal(
        ownerId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        accountDetails: accountDetails,
      );

      if (success) {
        await loadWallet();
        Get.snackbar('Success', 'Withdrawal request submitted');
      } else {
        Get.snackbar('Error', 'Withdrawal failed. Insufficient balance.');
      }

      return success;
    } catch (e) {
      Get.snackbar('Error', 'Withdrawal failed: $e');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  double get availableBalance => wallet.value?.availableBalance ?? 0.0;
  double get totalEarned => wallet.value?.totalEarned ?? 0.0;
  double get totalSpent => wallet.value?.totalSpent ?? 0.0;
  bool canPay(double amount) => wallet.value?.canPay(amount) ?? false;

  @override
  void onClose() {
    super.onClose();
  }
}