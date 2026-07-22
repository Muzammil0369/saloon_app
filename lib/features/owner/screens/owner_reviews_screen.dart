import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class OwnerReviewsScreen extends StatelessWidget {
  final String ownerId;

  const OwnerReviewsScreen({super.key, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final dbService = Get.find<DatabaseService>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('reviews_ratings'.tr, style: AppTextStyles.headingLarge?.copyWith(fontSize: 17,color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getSalonReviews(ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border_rounded, size: 64, color: theme.mutedTextColor),
                  const SizedBox(height: 16),
                  Text('no_reviews_yet'.tr, style: TextStyle(color: theme.mutedTextColor)),
                ],
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              final rating = (data['rating'] ?? 0).toInt();
              final comment = data['comment'] ?? '';
              final customerName = data['customerName'] ?? 'Customer';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: theme.cardColor,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            customerName,
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor),
                          ),
                          if (createdAt != null)
                            Text(
                              DateFormat('dd MMM yyyy').format(createdAt),
                              style: TextStyle(color: theme.mutedTextColor, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 18,
                        )),
                      ),
                      if (comment.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(comment, style: TextStyle(color: theme.textColor)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}