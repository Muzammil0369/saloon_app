import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_gradients.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/auth/screens/login_screen.dart';
import 'package:saloon_app/features/customer/registration/customer_phone_screen.dart';
import 'package:saloon_app/features/owner/registration/owner_phone_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String _selectedLanguage = 'EN';

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Icon
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    'Salon Book',
                    style: AppTextStyles.displayLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Who are you?',
                    style: AppTextStyles.bodyLarge?.copyWith(
                      color: theme.mutedTextColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Customer Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerPhoneScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: theme.lightPinkColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 24,
                              color: AppColors.primaryPink,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "I'm a Customer",
                                  style: AppTextStyles.headingSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Book salons near you',
                                  style: AppTextStyles.taglineSmall?.copyWith(
                                    color: theme.mutedTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: theme.grey400(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Owner Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OwnerPhoneScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "I'm a Salon Owner",
                                  style: AppTextStyles.headingSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Register your salon',
                                  style: AppTextStyles.taglineSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: AppTextStyles.taglineSmall?.copyWith(
                          color: theme.mutedTextColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.linkText?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Language Toggle - Top Right
            Positioned(
              top: 12,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLanguage = _selectedLanguage == 'EN' ? 'UR' : 'EN';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.borderColor,
                      width: 1,
                    ),
                    boxShadow: [theme.softShadow],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language, size: 20, color: Colors.lightBlueAccent),
                      const SizedBox(width: 2),
                      Text(
                        _selectedLanguage,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: theme.textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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