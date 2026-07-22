import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/controllers/user_controller.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class RateSalonScreen extends StatefulWidget {
  final String bookingId;
  final String ownerId;
  final String salonName;

  const RateSalonScreen({
    super.key,
    required this.bookingId,
    required this.ownerId,
    required this.salonName,
  });

  @override
  State<RateSalonScreen> createState() => _RateSalonScreenState();
}

class _RateSalonScreenState extends State<RateSalonScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      Get.snackbar('error'.tr, 'please_select_rating'.tr);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final customerId = Get.find<AuthService>().uid ?? '';
      final customerName = Get.find<UserController>().userName.value;
      final firestore = FirebaseFirestore.instance;

      // 1. Write the review document
      await firestore.collection('reviews').add({
        'ownerId': widget.ownerId,
        'customerId': customerId,
        'customerName': customerName,
        'bookingId': widget.bookingId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Mark this booking as reviewed so the button doesn't show again
      await firestore.collection('bookings').doc(widget.bookingId).update({
        'reviewed': true,
      });

      // 3. Recalculate the salon's average rating from all its reviews
      final reviewsSnapshot = await firestore
          .collection('reviews')
          .where('ownerId', isEqualTo: widget.ownerId)
          .get();

      final ratings = reviewsSnapshot.docs
          .map((d) => (d.data()['rating'] ?? 0).toDouble())
          .toList();

      final double average = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      await firestore.collection('owners').doc(widget.ownerId).update({
        'rating': double.parse(average.toStringAsFixed(1)),
        'reviewCount': ratings.length,
      });

      // 4. Notify the owner that they received a new review
      await firestore.collection('notifications').add({
        'userId': widget.ownerId,
        'title': 'new_review_received'.tr,
        'body': '$customerName ${'rated_your_salon'.tr} $_rating ${'stars'.tr}',
        'type': 'review',
        'bookingId': widget.bookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isSubmitting = false);
      Get.back(result: true);
      Get.snackbar('success'.tr, 'review_submitted'.tr);
    } catch (e) {
      setState(() => _isSubmitting = false);
      Get.snackbar('error'.tr, 'failed_submit_review'.tr + ': $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('rate_salon'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.salonName,
              style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor),
            ),
            const SizedBox(height: 8),
            Text('rate_your_experience'.tr, style: TextStyle(color: theme.mutedTextColor)),
            const SizedBox(height: 24),

            // Star selector
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = starValue),
                    icon: Icon(
                      starValue <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            Text('write_a_review'.tr, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                hintText: 'review_hint'.tr,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : Text('submit_review'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}