import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';

class OwnerGalleryManagementScreen extends StatefulWidget {
  const OwnerGalleryManagementScreen({super.key});

  @override
  State<OwnerGalleryManagementScreen> createState() => _OwnerGalleryManagementScreenState();
}

class _OwnerGalleryManagementScreenState extends State<OwnerGalleryManagementScreen> {
  final List<String> _images = [
    'assets/slide1.png',
    'assets/slide2.png',
    'assets/slide3.png',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('Salon Gallery', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photos', style: AppTextStyles.headingSmall.copyWith(color: theme.textColor)),
            const SizedBox(height: 8),
            Text('Showcase your best work and salon interior', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
            const SizedBox(height: 24),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _images.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () {
                       setState(() => _images.add('assets/slide1.png'));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.lightPinkColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryPink, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_rounded, color: AppColors.primaryPink, size: 32),
                          const SizedBox(height: 8),
                          Text('Add Photo', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }

                final img = _images[index - 1];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(index - 1)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
