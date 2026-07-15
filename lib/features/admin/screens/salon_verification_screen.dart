import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saloon_app/features/admin/theme/admin_colors.dart';
import 'package:saloon_app/features/admin/controllers/admin_controller.dart';
import 'package:saloon_app/features/admin/widgets/admin_scaffold.dart';

class SalonVerificationScreen extends StatelessWidget {
  const SalonVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();

    return AdminScaffold(
      title: "Salon Verification",
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('owners')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pendingOwners = snapshot.data!.docs;
          if (pendingOwners.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending verifications', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('New salon registrations will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: pendingOwners.length,
            itemBuilder: (context, index) {
              final data = pendingOwners[index].data() as Map<String, dynamic>;
              return _buildVerificationCard(context, adminController, pendingOwners[index].id, data);
            },
          );
        },
      ),
    );
  }

  // Helper to get image widget from any source
  Widget _getImageWidget(String? imagePath, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: width, height: height,
        color: Colors.grey.shade200,
        child: Icon(Icons.image, size: (width ?? 40) * 0.5, color: Colors.grey),
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, width: width, height: height, fit: fit,
          errorBuilder: (c, e, s) => Container(width: width, height: height, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)));
    }

    if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.contains(',') ? imagePath.split(',').last : imagePath;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, width: width, height: height, fit: fit,
            errorBuilder: (c, e, s) => Container(width: width, height: height, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)));
      } catch (e) {
        return Container(width: width, height: height, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey));
      }
    }

    return Container(width: width, height: height, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey));
  }

  Widget _buildVerificationCard(BuildContext context, AdminController controller, String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AdminColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.store, color: AdminColors.primary, size: 24),
        ),
        title: Text(
          data['salonName'] ?? 'Unknown Salon',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${data['fullName'] ?? data['ownerName'] ?? 'Unknown'}'),
            if (data['phoneNumber'] != null)
              Text('📞 ${data['phoneNumber']}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const Divider(),
          const SizedBox(height: 12),

          // ── OWNER INFO ──
          _sectionTitle('👤 Owner Information'),
          const SizedBox(height: 8),
          // Owner Profile Photo
          if (data['ownerProfileImage'] != null) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _getImageWidget(data['ownerProfileImage'], width: 120, height: 120),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _infoRow('Name', data['fullName'] ?? data['ownerName'] ?? 'N/A'),
          if (data['phoneNumber'] != null) _infoRow('Phone', data['phoneNumber']),
          _infoRow('Address', data['address'] ?? 'N/A'),

          if (data['phoneNumber'] != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _callOwner(data['phoneNumber']),
                icon: const Icon(Icons.call, size: 16),
                label: Text('Call ${data['phoneNumber']}'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── SERVICES ──
          if (data['services'] != null && (data['services'] as List).isNotEmpty) ...[
            _sectionTitle('💇 Services'),
            const SizedBox(height: 8),
            ...(data['services'] as List).map((service) {
              if (service is Map) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.cut, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('${service['name'] ?? 'Service'} - Rs. ${service['price'] ?? 0} (${service['duration'] ?? 0} min)',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }
              return const SizedBox();
            }),
            const SizedBox(height: 16),
          ],

          // ── CO-WORKERS ──
          if (data['workers'] != null && (data['workers'] as List).isNotEmpty) ...[
            _sectionTitle('👥 Co-Workers (${(data['workers'] as List).length})'),
            const SizedBox(height: 8),
            ...(data['workers'] as List).map((worker) {
              if (worker is Map) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      ClipOval(
                        child: _getImageWidget(worker['profileImage'], width: 40, height: 40),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(worker['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Father: ${worker['fatherName'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (worker['cnic'] != null && worker['cnic'].toString().isNotEmpty)
                              Text('CNIC: ${worker['cnic']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            }),
            const SizedBox(height: 16),
          ],

          // ── DOCUMENTS ──
          _sectionTitle('📄 Documents'),
          const SizedBox(height: 12),

          Row(
            children: [
              if (data['cnicFront'] != null) Expanded(child: _documentPreview('CNIC Front', data['cnicFront'], context)),
              if (data['cnicFront'] != null && data['cnicBack'] != null) const SizedBox(width: 10),
              if (data['cnicBack'] != null) Expanded(child: _documentPreview('CNIC Back', data['cnicBack'], context)),
            ],
          ),
          const SizedBox(height: 10),
          if (data['shopLicense'] != null) _documentPreview('Shop License', data['shopLicense'], context),
          const SizedBox(height: 10),
          if (data['shopOutsidePhoto'] != null) _documentPreview('Shop Outside', data['shopOutsidePhoto'], context),

          const SizedBox(height: 16),

          // ── SALON PHOTOS ──
          if (data['salonPhotos'] != null && (data['salonPhotos'] as List).isNotEmpty) ...[
            _sectionTitle('📸 Salon Photos (${(data['salonPhotos'] as List).length})'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: (data['salonPhotos'] as List).map((photo) {
                return GestureDetector(
                  onTap: () => _viewFullImage(photo.toString(), context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _getImageWidget(photo.toString(), width: 80, height: 80),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ── MAP ──
          if (data['lat'] != null && data['lng'] != null) ...[
            _sectionTitle('🗺️ Location'),
            const SizedBox(height: 4),
            Text('Lat: ${data['lat'].toStringAsFixed(6)}, Lng: ${data['lng'].toStringAsFixed(6)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openInMaps(data['lat'], data['lng']),
                icon: const Icon(Icons.map, size: 16),
                label: const Text('Open in Google Maps'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // ── APPROVE / REJECT ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.verifySalon(docId, true),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('APPROVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, controller, docId),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('REJECT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 60, child: Text('$label:', style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _documentPreview(String title, String imagePath, BuildContext context) {
    return GestureDetector(
      onTap: () => _viewFullImage(imagePath, context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Column(children: [
          ClipRRect(borderRadius: BorderRadius.circular(6), child: _getImageWidget(imagePath, height: 120, width: double.infinity)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const Text('Tap to view', style: TextStyle(fontSize: 9, color: Colors.grey)),
        ]),
      ),
    );
  }

  void _viewFullImage(String imagePath, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(child: _getImageWidget(imagePath, fit: BoxFit.contain)),
            Positioned(top: 8, right: 8,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callOwner(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) { await launchUrl(url); } else { Get.snackbar('Error', 'Could not launch phone call'); }
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) { await launchUrl(url); } else { Get.snackbar('Error', 'Could not open maps'); }
  }

  void _showRejectDialog(BuildContext context, AdminController controller, String docId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Salon?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Please provide a reason for rejection:'),
          const SizedBox(height: 12),
          TextField(controller: reasonCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'Reason for rejection...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { controller.verifySalon(docId, false); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Reject', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}