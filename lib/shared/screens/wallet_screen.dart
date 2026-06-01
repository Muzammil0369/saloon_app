import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/constants/app_radius.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('Wallet', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Balance', style: AppTextStyles.label.copyWith(color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 8),
                  Text('Rs. 4,500.00', style: AppTextStyles.displayLarge?.copyWith(color: Colors.white, fontSize: 32)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _actionButton(Icons.add_rounded, 'Top Up', Colors.white.withOpacity(0.2), () => _showTopUp(context)),
                      const SizedBox(width: 12),
                      _actionButton(Icons.arrow_upward_rounded, 'Withdraw', Colors.white.withOpacity(0.2), () {}),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Transaction History ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
                Text('See All', style: AppTextStyles.linkText),
              ],
            ),
            const SizedBox(height: 16),
            _transactionItem('Advanced Booking', 'Oct 24, 2026', '- Rs. 750', true, theme),
            _transactionItem('Wallet Top Up', 'Oct 22, 2026', '+ Rs. 2,000', false, theme),
            _transactionItem('Haircut Payment', 'Oct 15, 2026', '- Rs. 500', true, theme),
            _transactionItem('Refund Received', 'Oct 10, 2026', '+ Rs. 300', false, theme),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.buttonText),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopUp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = ThemeHelper(context);
        return Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Up Wallet', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
              const SizedBox(height: 8),
              Text('Enter amount to add to your balance', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: theme.lightPinkColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderColor),
                ),
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.headingMedium?.copyWith(color: theme.textColor),
                  decoration: InputDecoration(
                    prefixText: 'Rs. ',
                    hintText: '1,000',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Confirm Top Up',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _transactionItem(String title, String date, String amount, bool isDebit, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDebit ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
              color: isDebit ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                Text(date, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDebit ? theme.textColor : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
