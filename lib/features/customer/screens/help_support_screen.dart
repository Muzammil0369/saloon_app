import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('help'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('faq_title'.tr, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
            const SizedBox(height: 16),
            _faqTile('faq_how_to_book'.tr, 'faq_how_to_book_answer'.tr, theme),
            _faqTile('faq_advance_payment'.tr, 'faq_advance_payment_answer'.tr, theme),
            _faqTile('faq_cancel_booking'.tr, 'faq_cancel_booking_answer'.tr, theme),

            const SizedBox(height: 32),
            Text('contact_us'.tr, style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
            const SizedBox(height: 16),
            _contactTile(Icons.email_outlined, 'email_support'.tr, 'support@glambook.pk', theme),
            _contactTile(Icons.phone_outlined, 'call_support'.tr, '+92 321 0000000', theme),
            _contactTile(Icons.chat_bubble_outline_rounded, 'whatsapp_chat'.tr, '+92 321 1111111', theme),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(String q, String a, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: ExpansionTile(
        title: Text(q, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(a, style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor)),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(IconData icon, String title, String val, ThemeHelper theme) {
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
            decoration: BoxDecoration(color: theme.lightPinkColor, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              Text(val, style: AppTextStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
            ],
          ),
        ],
      ),
    );
  }
}