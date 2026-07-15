// lib/features/owner/screens/owner_staff_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/core/services/auth_service.dart';

class OwnerStaffScreen extends StatefulWidget {
  const OwnerStaffScreen({super.key});

  @override
  State<OwnerStaffScreen> createState() => _OwnerStaffScreenState();
}

class _OwnerStaffScreenState extends State<OwnerStaffScreen> {
  String get _ownerId => Get.find<AuthService>().uid ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('my_team'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('owners').doc(_ownerId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final workers = data['workers'] as List? ?? [];
          final hasCoworkers = data['hasCoworkers'] ?? false;

          if (!hasCoworkers || workers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: theme.mutedTextColor),
                  const SizedBox(height: 16),
                  Text('no_staff_members'.tr, style: TextStyle(fontSize: 18, color: theme.textColor)),
                  const SizedBox(height: 8),
                  Text('you_are_working_alone'.tr, style: TextStyle(color: theme.mutedTextColor)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: workers.length + 1, // +1 for owner (Ustad)
            itemBuilder: (context, index) {
              if (index == 0) {
                // Owner (Ustad) card
                return _buildStaffCard(
                  name: data['ownerName'] ?? data['fullName'] ?? 'owner'.tr,
                  role: 'ustad_owner'.tr,
                  phone: data['phoneNumber'] ?? 'N/A',
                  imageUrl: data['logo'] ?? data['ownerProfileImage'],
                  isOwner: true,
                  theme: theme,
                );
              }

              final worker = workers[index - 1] as Map<String, dynamic>;
              return _buildStaffCard(
                name: worker['name'] ?? 'Unknown',
                role: 'shagird_worker'.tr,
                fatherName: worker['fatherName'],
                cnic: worker['cnic'],
                imageUrl: worker['profileImage'],
                isOwner: false,
                theme: theme,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStaffCard({
    required String name,
    required String role,
    String? phone,
    String? fatherName,
    String? cnic,
    String? imageUrl,
    required bool isOwner,
    required ThemeHelper theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.softShadow],
        border: isOwner ? Border.all(color: AppColors.primaryPink, width: 2) : null,
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isOwner ? AppColors.primaryPink : theme.borderColor, width: 2),
              image: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? DecorationImage(
                image: _getImageProvider(imageUrl),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: imageUrl == null || imageUrl.toString().isEmpty
                ? Icon(
              isOwner ? Icons.star : Icons.person,
              size: 30,
              color: isOwner ? AppColors.primaryPink : theme.mutedTextColor,
            )
                : null,
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textColor)),
                    if (isOwner) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('ustad'.tr, style: TextStyle(fontSize: 10, color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(role, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                if (phone != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.phone, size: 12, color: theme.mutedTextColor),
                    const SizedBox(width: 4),
                    Text(phone, style: TextStyle(fontSize: 12, color: theme.mutedTextColor)),
                  ]),
                ],
                if (fatherName != null && fatherName.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('${'son_of'.tr}: $fatherName', style: TextStyle(fontSize: 11, color: theme.mutedTextColor)),
                ],
                if (cnic != null && cnic.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('${'cnic'.tr}: $cnic', style: TextStyle(fontSize: 11, color: theme.mutedTextColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http')) return NetworkImage(url);
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return MemoryImage(bytes);
      } catch (_) {}
    }
    return const AssetImage('assets/default_avatar.png');
  }
}