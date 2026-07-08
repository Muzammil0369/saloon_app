import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import '../../../core/services/auth_service.dart';

class OwnerServicesManagementScreen extends StatefulWidget {
  const OwnerServicesManagementScreen({super.key});

  @override
  State<OwnerServicesManagementScreen> createState() => _OwnerServicesManagementScreenState();
}

class _OwnerServicesManagementScreenState extends State<OwnerServicesManagementScreen> {
  bool _isLoading = false;

  String get _ownerId => Get.find<AuthService>().uid!;

  // Stream owner data from Firestore
  Stream<Map<String, dynamic>> _getOwnerData() {
    return FirebaseFirestore.instance
        .collection('owners')
        .doc(_ownerId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  // Get current services list
  List<Map<String, dynamic>> _getServices(Map<String, dynamic>? ownerData) {
    if (ownerData == null) return [];
    final services = ownerData['services'];
    if (services == null || services is! List) return [];

    return services
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // Save services to Firestore
  Future<void> _saveServices(List<Map<String, dynamic>> services) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(_ownerId)
          .update({'services': services});
      Get.snackbar('Success', 'Services updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save services');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showServiceModal({
    Map<String, dynamic>? existingService,
    int? index,
    List<Map<String, dynamic>>? allServices,
  }) {
    final nameCtrl = TextEditingController(text: existingService?['name'] ?? '');
    final priceCtrl = TextEditingController(text: (existingService?['price'] ?? '').toString());
    final durCtrl = TextEditingController(text: (existingService?['duration'] ?? '').toString());

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
              Text(
                existingService == null ? 'Add Service' : 'Edit Service',
                style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor),
              ),
              const SizedBox(height: 24),
              _buildField('Service Name', 'e.g. Classic Haircut', nameCtrl, theme),
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

                  final newService = <String, dynamic>{
                    'name': nameCtrl.text.trim(),
                    'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
                    'duration': int.tryParse(durCtrl.text.trim()) ?? 30,
                  };

                  List<Map<String, dynamic>> updatedServices = allServices != null
                      ? List<Map<String, dynamic>>.from(allServices)
                      : [];

                  if (index == null || index >= updatedServices.length) {
                    // Add new
                    newService['id'] = DateTime.now().millisecondsSinceEpoch.toString();
                    updatedServices.add(newService);
                  } else {
                    // Update existing - keep the ID
                    newService['id'] = existingService?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
                    updatedServices[index] = newService;
                  }

                  _saveServices(updatedServices);
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
          decoration: BoxDecoration(
            color: theme.lightPinkColor,
            borderRadius: BorderRadius.circular(12),
          ),
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
          onPressed: () => Get.back(),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _getOwnerData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
          }

          final services = _getServices(snapshot.data);

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa_outlined, size: 64, color: theme.mutedTextColor),
                  const SizedBox(height: 12),
                  Text('No services added yet', style: TextStyle(color: theme.mutedTextColor)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
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
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lightPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.content_cut, color: AppColors.primaryPink, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'] ?? 'Unnamed',
                            style: AppTextStyles.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            'Rs. ${s['price']} · ${s['duration']} min',
                            style: AppTextStyles.label.copyWith(color: theme.mutedTextColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primaryPink, size: 20),
                      onPressed: () => _showServiceModal(
                        existingService: s,
                        index: index,
                        allServices: services,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        final updatedServices = List<Map<String, dynamic>>.from(services)..removeAt(index);
                        _saveServices(updatedServices);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<Map<String, dynamic>>(
        stream: _getOwnerData(),
        builder: (context, snapshot) {
          // Explicitly type the list
          final List<Map<String, dynamic>> services = snapshot.hasData
              ? _getServices(snapshot.data)
              : <Map<String, dynamic>>[];

          return FloatingActionButton(
            onPressed: () => _showServiceModal(allServices: services),
            backgroundColor: AppColors.primaryPink,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          );
        },
      ),
    );
  }
}