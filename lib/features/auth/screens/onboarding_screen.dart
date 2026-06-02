import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/auth/screens/role_select_screen.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/features/customer/customer_main_wrapper.dart';
import 'package:saloon_app/features/owner/owner_main_wrapper.dart';
import 'package:saloon_app/features/owner/registration/owner_pending_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;

  late AnimationController _slideController;

  final List<Map<String, dynamic>> _pages = [
    {
      "image": "assets/slide1.png",
      "icon": Icons.content_cut_rounded,
      "title": "Book Top Salons",
      "description": "Discover top-rated salons near you\nand book appointments in seconds.",
    },
    {
      "image": "assets/slide2.png",
      "icon": Icons.calendar_month_rounded,
      "title": "Choose Your Time",
      "description": "Pick the perfect date and time slot.\nCancel or reschedule anytime.",
    },
    {
      "image": "assets/slide3.png",
      "icon": Icons.wallet_rounded,
      "title": "Easy Payments",
      "description": "Pay via EasyPaisa, JazzCash or cash.\nSafe, simple, and secure.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _checkFirstSeen();
  }

  Future<void> _checkFirstSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool seen = (prefs.getBool('seen_onboarding') ?? false);
    
    // Check if user is already logged in
    final authService = Get.find<AuthService>();
    if (authService.isLoggedIn) {
      await _navigateBasedOnRole();
      return;
    }

    if (seen) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectScreen()),
      );
    }
  }

  Future<void> _navigateBasedOnRole() async {
    final authService = Get.find<AuthService>();
    final dbService = Get.find<DatabaseService>();
    
    final userDoc = await dbService.getUserProfile(authService.uid!);
    
    if (!userDoc.exists) {
      // Should ideally not happen if they are logged in, but just in case
      // maybe route to RoleSelect or a setup screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectScreen()),
      );
      return;
    }

    final data = userDoc.data() as Map<String, dynamic>;
    final role = data['role'] as String?;

    if (!mounted) return;

    if (role == 'customer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomerMainWrapper()),
      );
    } else if (role == 'owner') {
      final status = data['status'] as String?;
      if (status == 'approved') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OwnerMainWrapper()),
        );
      } else {
        // Pending or other
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OwnerPendingScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectScreen()),
      );
    }
  }

  Future<void> _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _onFinish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Top Row: Logo + Skip ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryPink, AppColors.darkPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.content_cut_rounded,
                        color: Colors.white, size: 20),
                  ),
                  // Skip
                  GestureDetector(
                    onTap: _onFinish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.mutedTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Page View ──
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _slideController.reset();
                    _slideController.forward();
                  },
                  itemBuilder: (_, index) {
                    final page = _pages[index];
                    return AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        final slideValue = _currentPage == index
                            ? _slideController.value
                            : 0.0;
                        return Opacity(
                          opacity: _currentPage == index ? 1.0 : 0.0,
                          child: Transform.translate(
                            offset: Offset(
                                0, 30 * (1 - (_currentPage == index ? slideValue : 0))),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ── Image ──
                                Container(
                                  height: size.height * 0.32,
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPink
                                            .withOpacity(0.15),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.asset(
                                      page["image"],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.lightPink,
                                                  AppColors.lightPink
                                                      .withOpacity(0.5),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Icon(
                                              page["icon"],
                                              size: 80,
                                              color: AppColors.primaryPink,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 48),

                                // ── Title ──
                                Text(
                                  page["title"],
                                  style: AppTextStyles.displayMedium?.copyWith(
                                    color: theme.textColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 16),

                                // ── Description ──
                                Text(
                                  page["description"],
                                  style: AppTextStyles.bodyLarge?.copyWith(
                                    color: theme.mutedTextColor,
                                    height: 1.6,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Bottom Section ──
              Column(
                children: [
                  // ── Dots ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryPink
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Button ──
                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryPink, AppColors.darkPink],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}