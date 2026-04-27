import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/features/combine/combine_screens/login_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';

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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // void _goToLogin() {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (_) => const LoginScreen()),
  //   );
  // }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 20 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primaryPink
            : AppColors.mutedText,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ was missing — memory leak fix
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // const SizedBox(height: 32),
              //
              // // Logo + tagline
              // Text('SalonApp', style: AppTextStyles.displayLarge),
              // const SizedBox(height: 6),
              // Text(
              //   'Salon Booking Made Easy',
              //   style: AppTextStyles.bodySmall,
              // ),
              //
              // const SizedBox(height: 24),

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
                          style: AppTextStyles.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          _pages[index]["description"]!,
                          style: AppTextStyles.bodyMedium,
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
                      (index) => _buildDot(index),
                ),
              ),

              const SizedBox(height: 32),

              // Button
              AppButton(
                label: _currentPage == _pages.length - 1
                    ? 'Get Started 🎉'
                    : 'Next',
                onTap: _nextPage,
              ),

              const SizedBox(height: 14),

              // Already have account
              // GestureDetector(
              //   onTap: _goToLogin,
              //   child: Text(
              //     'I already have an account',
              //     style: AppTextStyles.bodySmall.copyWith(
              //       decoration: TextDecoration.underline,
              //     ),
              //   ),
              // ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}