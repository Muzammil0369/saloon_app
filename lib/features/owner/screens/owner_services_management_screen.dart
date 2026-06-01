import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';

class OwnerServicesManagementScreen extends StatefulWidget {
  const OwnerServicesManagementScreen({super.key});

  @override
  State<OwnerServicesManagementScreen> createState() => _OwnerServicesManagementScreenState();
}

class _OwnerServicesManagementScreenState extends State<OwnerServicesManagementScreen> {
  final List<Map<String, String>> _services = [
    {'name': 'Classic Haircut', 'price': '500', 'duration': '30'},
    {'name': 'Beard Trim', 'price': '300', 'duration': '20'},
    {'name': 'Facial Spa', 'price': '1200', 'duration': '45'},
  ];

  void _showAddServiceModal({Map<String, String>? existingService, int? index}) {
    final nameCtrl = TextEditingController(text: existingService?['name'] ?? '');
    final priceCtrl = TextEditingController(text: existingService?['price'] ?? '');
    final durCtrl = TextEditingController(text: existingService?['duration'] ?? '');

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
              Text(existingService == null ? 'Add Service' : 'Edit Service', 
                style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
              const SizedBox(height: 24),
              _buildField('Service Name', 'e.g. Hair Coloring', nameCtrl, theme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Price (Rs.)', '500', priceCtrl, theme, isNum: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Duration (Min)', '30', durCtrl, theme, isNum: true)),
                ],
              ),
              const SizedBox(height: 32),
              AppButton(
                label: existingService == null ? 'Add to Menu' : 'Save Changes',
                onTap: () {
                  if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                  setState(() {
                    final data = {
                      'name': nameCtrl.text,
                      'price': priceCtrl.text,
                      'duration': durCtrl.text,
                    };
                    if (index == null) {
                      _services.add(data);
                    } else {
                      _services[index] = data;
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, ThemeHelper theme, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: theme.lightPinkColor, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: ctrl,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('Service Menu', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _services.isEmpty 
      ? Center(child: Text('No services added yet', style: TextStyle(color: theme.mutedTextColor)))
      : ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final s = _services[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name']!, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                      Text('Rs. ${s['price']} · ${s['duration']} min', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primaryPink, size: 20),
                  onPressed: () => _showAddServiceModal(existingService: s, index: index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => setState(() => _services.removeAt(index)),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceModal(),
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
