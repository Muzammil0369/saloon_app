import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class OwnerBusinessHoursScreen extends StatefulWidget {
  const OwnerBusinessHoursScreen({super.key});

  @override
  State<OwnerBusinessHoursScreen> createState() =>
      _OwnerBusinessHoursScreenState();
}

class _OwnerBusinessHoursScreenState extends State<OwnerBusinessHoursScreen> {
  String get _ownerId => Get.find<AuthService>().uid ?? '';

  TimeOfDay _openTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 20, minute: 0);

  // Dart's DateTime.weekday: 1 = Monday ... 7 = Sunday
  final Set<int> _workingDays = {1, 2, 3, 4, 5, 6, 7};
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _dayLabels = [
    {'day': 1, 'label': 'Mon'},
    {'day': 2, 'label': 'Tue'},
    {'day': 3, 'label': 'Wed'},
    {'day': 4, 'label': 'Thu'},
    {'day': 5, 'label': 'Fri'},
    {'day': 6, 'label': 'Sat'},
    {'day': 7, 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final doc = await FirebaseFirestore.instance
        .collection('owners')
        .doc(_ownerId)
        .get();
    final hours = doc.data()?['businessHours'] as Map<String, dynamic>?;

    if (hours != null) {
      final openParts = (hours['openTime'] as String? ?? '10:00').split(':');
      final closeParts = (hours['closeTime'] as String? ?? '20:00').split(':');
      setState(() {
        _openTime = TimeOfDay(
          hour: int.parse(openParts[0]),
          minute: int.parse(openParts[1]),
        );
        _closeTime = TimeOfDay(
          hour: int.parse(closeParts[0]),
          minute: int.parse(closeParts[1]),
        );
        _workingDays
          ..clear()
          ..addAll(
            (hours['workingDays'] as List?)?.map((e) => e as int) ??
                [1, 2, 3, 4, 5, 6, 7],
          );
      });
    }
    setState(() => _isLoading = false);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (picked != null) {
      setState(() => isOpen ? _openTime = picked : _closeTime = picked);
    }
  }

  Future<void> _save() async {
    if (_workingDays.isEmpty) {
      Get.snackbar('error'.tr, 'select_at_least_one_day'.tr);
      return;
    }

    final openMinutes = _openTime.hour * 60 + _openTime.minute;
    var closeMinutes = _closeTime.hour * 60 + _closeTime.minute;

    // FIX: midnight (12:00 AM) stores as hour=0, which looks "before" any
    // opening time earlier in the day — but a salon open 8 AM to 12 AM
    // (midnight) is a perfectly normal 16-hour day, not an error. Whenever
    // the picked closing time is at or before opening time, treat it as
    // rolling into the next day (add 24 hours) instead of rejecting it.
    // This also correctly handles closing times like 1 AM or 2 AM.
    if (closeMinutes <= openMinutes) {
      closeMinutes += 24 * 60;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(_ownerId)
          .update({
            'businessHours': {
              'openTime': _formatTime(_openTime),
              'closeTime': _formatTime(_closeTime),
              'workingDays': _workingDays.toList()..sort(),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
      Get.back();
      Get.snackbar('success'.tr, 'business_hours_updated'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_update_status'.tr);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'business_hours'.tr,
          style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'business_hours_explainer'.tr,
                    style: AppTextStyles.bodyMedium?.copyWith(
                      color: theme.mutedTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'opening_time'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny_outlined,
                            color: AppColors.primaryPink,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _openTime.format(context),
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'closing_time'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.nightlight_round,
                            color: AppColors.primaryPink,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _closeTime.format(context),
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'working_days'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dayLabels.map((d) {
                      final isSelected = _workingDays.contains(d['day']);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _workingDays.remove(d['day']);
                          } else {
                            _workingDays.add(d['day'] as int);
                          }
                        }),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryPink
                                : theme.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryPink
                                  : theme.borderColor,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (d['label'] as String).tr,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'save'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
