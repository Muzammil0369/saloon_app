import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/auth/screens/role_select_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/slide1.png",
      "title": "Book Top Salons",
      "description": "Discover top-rated salons near you and book appointments in seconds.",
    },
    {
      "image": "assets/slide2.png",
      "title": "Choose Your Time",
      "description": "Pick the perfect date and time slot. Cancel or reschedule anytime.",
    },
    {
      "image": "assets/slide3.png",
      "title": "Easy Payments",
      "description": "Pay via EasyPaisa, JazzCash or cash on visit. Safe and simple.",
    },
  ];

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildDot(int index, ThemeHelper theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 40 : 20,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primaryPink
            : theme.lightPinkColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.white.withOpacity(0.4)
                : AppColors.primaryPink.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (_, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image
                        Expanded(
                          child: Image.asset(
                            _pages[index]["image"]!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          _pages[index]["title"]!,
                          style: AppTextStyles.displayMedium?.copyWith(
                            color: theme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          _pages[index]["description"]!,
                          style: AppTextStyles.bodyMedium?.copyWith(
                            color: theme.mutedTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (index) => _buildDot(index, theme),
                ),
              ),

              const SizedBox(height: 32),

              // Button
              AppButton(
                label: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                onTap: _nextPage,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}