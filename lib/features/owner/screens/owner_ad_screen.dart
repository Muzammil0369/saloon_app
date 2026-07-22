import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

import '../../../shared/widgets/ad_banner_card.dart';

const String _imgbbApiKey = '854c22d480dce931a496682c8cdbb164';

class OwnerAdScreen extends StatefulWidget {
  const OwnerAdScreen({super.key});

  @override
  State<OwnerAdScreen> createState() => _OwnerAdScreenState();
}

class _OwnerAdScreenState extends State<OwnerAdScreen> {
  String get _ownerId => Get.find<AuthService>().uid ?? '';

  final TextEditingController _offerTitleController = TextEditingController();
  double _percentOff = 20;
  int _durationDays = 7;
  String _templateId = 'pink_dark';
  String? _customBackgroundUrl;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  final Set<String> _selectedServiceNames = {};

  @override
  void dispose() {
    _offerTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadBackground() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {'image': base64Image},
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        setState(() {
          _customBackgroundUrl = decoded['data']['url'];
          _isUploadingImage = false;
        });
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      Get.snackbar('error'.tr, 'failed_upload_image'.tr);
    }
  }

  // Some service docs have price stored as a String instead of a number
  // (older data / manual edits) — this handles both without crashing.
  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  Future<void> _saveAd(Map<String, dynamic> ownerData, List<Map<String, dynamic>> services) async {
    if (_offerTitleController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'enter_offer_title'.tr);
      return;
    }
    if (_selectedServiceNames.isEmpty) {
      Get.snackbar('error'.tr, 'select_at_least_one_service'.tr);
      return;
    }

    setState(() => _isSaving = true);

    final selectedServices = services
        .where((s) => _selectedServiceNames.contains(s['name']))
        .map((s) => {'name': s['name'], 'price': _toNum(s['price'])})
        .toList();

    final num originalPrice = selectedServices.fold<num>(0, (sum, s) => sum + _toNum(s['price']));
    final num discountedPrice = (originalPrice * (1 - _percentOff / 100)).round();

    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: _durationDays));

    final adData = {
      'ownerId': _ownerId,
      'salonName': ownerData['salonName'] ?? 'Unnamed Salon',
      'logoUrl': ownerData['logo'] ?? ownerData['ownerProfileImage'],
      'templateId': _customBackgroundUrl == null ? _templateId : null,
      'backgroundImageUrl': _customBackgroundUrl,
      'offerTitle': _offerTitleController.text.trim(),
      'percentOff': _percentOff.round(),
      'selectedServices': selectedServices,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'durationDays': _durationDays,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'location': ownerData['location'],
      'rating': ownerData['rating'] ?? 0.0,
      'isActive': true,
      // Monetization hooks for later — unused today, kept so charging for ads
      // later doesn't need a schema migration.
      'isPaid': false,
      'paymentStatus': 'none',
      'amountCharged': null,
      'transactionId': null,
    };

    try {
      await FirebaseFirestore.instance.collection('ads').doc(_ownerId).set(adData);
      setState(() => _isSaving = false);
      Get.back();
      Get.snackbar('success'.tr, 'ad_published'.tr);
    } catch (e) {
      setState(() => _isSaving = false);
      Get.snackbar('error'.tr, '${'failed_to_book'.tr}: $e');
    }
  }

  Future<void> _deleteAd() async {
    await FirebaseFirestore.instance.collection('ads').doc(_ownerId).delete();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('ads_offers'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('owners').doc(_ownerId).snapshots(),
        builder: (context, ownerSnapshot) {
          if (!ownerSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));

          final ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final services = ((ownerData['services'] as List?) ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('ads').doc(_ownerId).snapshots(),
            builder: (context, adSnapshot) {
              final hasAd = adSnapshot.hasData && adSnapshot.data!.exists;
              final adData = hasAd ? adSnapshot.data!.data() as Map<String, dynamic> : null;

              if (hasAd && adData != null) {
                final expiresAt = (adData['expiresAt'] as Timestamp?)?.toDate();
                final daysLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : 0;

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('current_active_ad'.tr, style: AppTextStyles.headingMedium),
                      const SizedBox(height: 16),
                      AdBannerCard(ad: adData),
                      const SizedBox(height: 12),
                      Text(
                        daysLeft > 0 ? '${'expires_in_days'.tr}: $daysLeft' : 'expired'.tr,
                        style: TextStyle(color: theme.mutedTextColor),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _deleteAd,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('remove_ad'.tr, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // No active ad — show the creation form
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('create_new_ad'.tr, style: AppTextStyles.headingMedium),
                    const SizedBox(height: 20),

                    // Live preview
                    AdBannerCard(
                      ad: {
                        'salonName': ownerData['salonName'] ?? 'Unnamed Salon',
                        'logoUrl': ownerData['logo'],
                        'templateId': _templateId,
                        'backgroundImageUrl': _customBackgroundUrl,
                        'offerTitle': _offerTitleController.text.trim().isEmpty ? 'offer_title_placeholder'.tr : _offerTitleController.text.trim(),
                        'percentOff': _percentOff.round(),
                      },
                    ),
                    const SizedBox(height: 24),

                    Text('offer_title'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _offerTitleController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'offer_title_hint'.tr,
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('${'percent_off_label'.tr}: ${_percentOff.round()}%', style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor)),
                    Slider(
                      value: _percentOff,
                      min: 5,
                      max: 70,
                      divisions: 13,
                      activeColor: AppColors.primaryPink,
                      label: '${_percentOff.round()}%',
                      onChanged: (v) => setState(() => _percentOff = v),
                    ),
                    const SizedBox(height: 12),

                    Text('select_services_for_offer'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor)),
                    const SizedBox(height: 8),
                    if (services.isEmpty)
                      Text('add_services_first'.tr, style: TextStyle(color: theme.mutedTextColor))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: services.map((s) {
                          final name = s['name'] ?? '';
                          final isSelected = _selectedServiceNames.contains(name);
                          return FilterChip(
                            label: Text('$name (${'rs'.tr} ${s['price']})'),
                            selected: isSelected,
                            selectedColor: AppColors.primaryPink.withOpacity(0.15),
                            checkmarkColor: AppColors.primaryPink,
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                _selectedServiceNames.add(name);
                              } else {
                                _selectedServiceNames.remove(name);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),

                    Text('ad_duration'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor)),
                    const SizedBox(height: 8),
                    Row(
                      children: [3, 7, 14].map((days) {
                        final isSelected = _durationDays == days;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text('$days ${'days'.tr}'),
                            selected: isSelected,
                            selectedColor: AppColors.primaryPink,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : theme.textColor, fontWeight: FontWeight.w600),
                            onSelected: (_) => setState(() => _durationDays = days),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    Text('background_style'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...AdTemplates.templates.keys.map((id) {
                          final isSelected = _customBackgroundUrl == null && _templateId == id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _templateId = id;
                                _customBackgroundUrl = null;
                              }),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AdTemplates.get(id),
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: theme.textColor, width: 3) : null,
                                ),
                              ),
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAndUploadBackground,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _customBackgroundUrl != null ? theme.textColor : theme.borderColor,
                                width: _customBackgroundUrl != null ? 3 : 1,
                              ),
                            ),
                            child: _isUploadingImage
                                ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink))
                                : Icon(Icons.add_photo_alternate_outlined, color: AppColors.primaryPink, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveAd(ownerData, services),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('publish_ad'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}