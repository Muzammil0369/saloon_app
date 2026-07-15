import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_documents_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

import 'owner_coworkers_screen.dart';

class OwnerServicesScreen extends StatefulWidget {
  final Map<String, dynamic> salonData;
  const OwnerServicesScreen({super.key, required this.salonData});

  @override
  State<OwnerServicesScreen> createState() => _OwnerServicesScreenState();
}

class _OwnerServicesScreenState extends State<OwnerServicesScreen> {
  final List<Map<String, String>> services = [
    {'name': 'Haircut', 'price': '500', 'duration': '30'},
    {'name': 'Beard Trim', 'price': '300', 'duration': '20'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('services'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressStepBar(totalSteps: 7, currentStep: 4),
              const SizedBox(height: 30),

              Text('your_menu'.tr + ' ✂️',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('list_services'.tr,
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),
              
              const SizedBox(height: 30),

              ...services.map((s) => _serviceCard(s, theme)),
              
              const SizedBox(height: 20),
              
              GestureDetector(
                onTap: () {
                  setState(() {
                    services.add({'name': 'New Service', 'price': '0', 'duration': '0'});
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryPink, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryPink),
                      const SizedBox(width: 8),
                      Text('add_new_service'.tr, style: AppTextStyles.buttonText?.copyWith(color: AppColors.primaryPink)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              AppButton(
                label: 'save_next'.tr,
                onTap: () {
                  final updatedSalonData = {
                    ...widget.salonData,
                    'services': services,
                  };
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerCoworkersScreen(salonData: updatedSalonData)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(Map<String, String> service, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service['name']!, style: AppTextStyles.headingSmall?.copyWith(color: theme.textColor)),
                const SizedBox(height: 4),
                Text('${'rs'.tr} ${service['price']} · ${service['duration']} ${'min'.tr}',
                  style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryPink),
            onPressed: () => _editService(service),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
            onPressed: () {
              setState(() => services.remove(service));
            },
          ),
        ],
      ),
    );
  }

  void _editService(Map<String, String> service) {
    final nameCtrl = TextEditingController(text: service['name']);
    final priceCtrl = TextEditingController(text: service['price']);
    final durCtrl = TextEditingController(text: service['duration']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = ThemeHelper(context);
        return Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('edit_service'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
              const SizedBox(height: 20),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'service_name'.tr)),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: InputDecoration(labelText: 'service_price'.tr)),
              const SizedBox(height: 12),
              TextField(controller: durCtrl, decoration: InputDecoration(labelText: 'service_duration'.tr)),
              const SizedBox(height: 20),
              // In OwnerServicesScreen, update the "Save & Next" button:
              AppButton(
                label: 'Save & Next',
                onTap: () {
                  // Add unique IDs to services
                  final servicesWithIds = services.map((s) => {
                    'id': s['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': s['name'],
                    'price': int.tryParse(s['price'] ?? '0') ?? 0,
                    'duration': int.tryParse(s['duration'] ?? '30') ?? 30,
                  }).toList();

                  final updatedSalonData = {
                    ...widget.salonData,
                    'services': servicesWithIds,
                  };
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => OwnerDocumentsScreen(salonData: updatedSalonData),
                  ));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
