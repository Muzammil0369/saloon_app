import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = 'mzappstudio@outlook.com';
  static const String _supportPhone = '+92 323 8605733';
  static const String _whatsappNumber = '92 323 8605733'; // no + or leading 0

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'help'.tr,
          style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor),
        ),
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
            // ── Quick actions ──
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.chat_bubble_rounded,
                    label: 'whatsapp_chat'.tr,
                    theme: theme,
                    onTap: () => _launch(
                      Uri.parse('https://wa.me/$_whatsappNumber'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    icon: Icons.call_rounded,
                    label: 'call_support'.tr,
                    theme: theme,
                    onTap: () => _launch(Uri(scheme: 'tel', path: _supportPhone)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text(
              'faq_title'.tr,
              style: AppTextStyles.headingSmall.copyWith(color: theme.textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'faq_subtitle'.tr,
              style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor),
            ),
            const SizedBox(height: 16),

            _faqTile(context,'faq_how_to_book'.tr, 'faq_how_to_book_answer'.tr, theme),
            _faqTile(context,'faq_advance_payment'.tr, 'faq_advance_payment_answer'.tr, theme),
            _faqTile(context,'faq_cancel_booking'.tr, 'faq_cancel_booking_answer'.tr, theme),
            _faqTile(context,'faq_escrow_release'.tr, 'faq_escrow_release_answer'.tr, theme),
            _faqTile(context,'faq_pay_cash'.tr, 'faq_pay_cash_answer'.tr, theme),
            _faqTile(context,'faq_salon_verified'.tr, 'faq_salon_verified_answer'.tr, theme),

            const SizedBox(height: 32),
            Text(
              'contact_us'.tr,
              style: AppTextStyles.headingSmall.copyWith(color: theme.textColor),
            ),
            const SizedBox(height: 16),

            _contactTile(
              Icons.email_outlined,
              'email_support'.tr,
              _supportEmail,
              theme,
              onTap: () => _launch(
                Uri(
                  scheme: 'mailto',
                  path: _supportEmail,
                  query: 'subject=Glambook Support Request',
                ),
              ),
            ),
            _contactTile(
              Icons.phone_outlined,
              'call_support'.tr,
              _supportPhone,
              theme,
              onTap: () => _launch(Uri(scheme: 'tel', path: _supportPhone)),
            ),
            _contactTile(
              Icons.chat_bubble_outline_rounded,
              'whatsapp_chat'.tr,
              '+92 323 8605733',
              theme,
              onTap: () => _launch(Uri.parse('https://wa.me/$_whatsappNumber')),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                'app_version'.trParams({'version': '1.0.0'}),
                style: AppTextStyles.caption?.copyWith(color: theme.mutedTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required ThemeHelper theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: theme.lightPinkColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryPink, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(BuildContext context, String q, String a, ThemeHelper theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              backgroundColor: theme.cardColor,
              collapsedBackgroundColor: theme.cardColor,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              iconColor: AppColors.primaryPink,
              collapsedIconColor: theme.mutedTextColor,
              title: Text(
                q,
                style: AppTextStyles.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    a,
                    style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactTile(
      IconData icon,
      String title,
      String val,
      ThemeHelper theme, {
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                  Text(
                    val,
                    style: AppTextStyles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.mutedTextColor, size: 20),
          ],
        ),
      ),
    );
  }
}
