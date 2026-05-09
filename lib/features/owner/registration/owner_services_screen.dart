import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_review_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/progress_step_bar.dart';

class OwnerServicesScreen extends StatefulWidget {
  const OwnerServicesScreen({super.key});
  @override
  State<OwnerServicesScreen> createState() => _OwnerServicesScreenState();
}

class _OwnerServicesScreenState extends State<OwnerServicesScreen> {
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  List<Map<String, String>> services = [];

  @override
  void dispose() {
    _serviceNameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addService() {
    if (_serviceNameController.text.isNotEmpty && _priceController.text.isNotEmpty && _durationController.text.isNotEmpty) {
      setState(() {
        services.add({'name': _serviceNameController.text, 'price': _priceController.text, 'duration': _durationController.text});
        _serviceNameController.clear(); _priceController.clear(); _durationController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Services & Hours', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, bottom: 8),
            child: Container(
              decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.arrow_back, color: theme.textColor),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressStepBar(totalSteps: 5, currentStep: 5),
                const SizedBox(height: 30),
                Text('Your Services', style: AppTextStyles.displayLarge?.copyWith(color: theme.textColor)),
                const SizedBox(height: 8),
                Text('Add at least one service to continue', style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(flex: 2, child: TextField(controller: _serviceNameController, style: TextStyle(color: theme.textColor), decoration: InputDecoration(hintText: 'Service name', hintStyle: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.borderColor))))),
                        const SizedBox(width: 8),
                        Expanded(flex: 1, child: TextField(controller: _priceController, keyboardType: TextInputType.number, style: TextStyle(color: theme.textColor), decoration: InputDecoration(hintText: 'Rs.', hintStyle: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.borderColor))))),
                      ]),
                      const SizedBox(height: 12),
                      TextField(controller: _durationController, style: TextStyle(color: theme.textColor), decoration: InputDecoration(hintText: 'Duration (e.g. 30 min)', hintStyle: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.borderColor)))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...services.map((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.grey100(), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Expanded(flex: 2, child: Text(service['name']!, style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor))),
                      Expanded(flex: 1, child: Text('Rs. ${service['price']}', style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor))),
                      Expanded(flex: 2, child: Text(service['duration']!, style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor))),
                    ]),
                  ),
                )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _addService,
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: theme.borderColor), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: AppColors.primaryPink, size: 20), const SizedBox(width: 8), Text('Add Another Service', style: AppTextStyles.taglinePink)]),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Working Hours', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18)),
                  child: Column(children: [
                    _buildHourRow('Mon – Fri', '9:00 AM – 9:00 PM', theme),
                    const SizedBox(height: 12), Divider(height: 1, color: theme.borderColor), const SizedBox(height: 12),
                    _buildHourRow('Saturday', '10:00 AM – 8:00 PM', theme),
                    const SizedBox(height: 12), Divider(height: 1, color: theme.borderColor), const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Sunday', style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor)),
                      Text('Closed', style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 50),
                AppButton(label: 'Submit for Review', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerReviewScreen()));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourRow(String day, String time, ThemeHelper theme) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(day, style: AppTextStyles.bodyMedium?.copyWith(color: theme.textColor)),
      Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryPink)),
    ]);
  }
}