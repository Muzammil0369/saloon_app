import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController.forward();
    _checkFirstSeen();
  }

  Future<void> _checkFirstSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool seen = (prefs.getBool('seen_onboarding') ?? false);

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
        curve: Curves.easeOutBack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final size = MediaQuery.of(context).size;
    final double progress = (_currentPage + 1) / _pages.length;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Top Row: Elegant Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Far Left: Logo Container
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ClipOval(
                        child: Container(
                          height: 44,
                          width: 44,
                          color: Colors.white, // Optional: background color
                          child: Image.asset(
                            'assets/app_icon.png',
                            fit: BoxFit.cover, // This crops the image to fill the circle
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Center: App Name (Perfectly Centered)
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Text(
                        'SALONIFY',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        style: AppTextStyles.displayMedium.copyWith(
                          color: theme.textColor,   // ← was missing, so it fell back to a dark-on-dark default
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),

                  // 3. Far Right: Tiny Skip Button
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _onFinish,
                        behavior: HitTestBehavior.opaque, // Expands the tap area for easy clicking
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: theme.mutedTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5, // Ultra-sleek, small aesthetic
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Main Carousel Content ──
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
                        final val = _currentPage == index ? _slideController.value : 0.0;
                        return Opacity(
                          opacity: _currentPage == index ? val : 0.0,
                          child: Transform.scale(
                            scale: 0.9 + (0.1 * val),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Sleek Floating Image Frame
                                Container(
                                  height: size.height * 0.35,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    image: DecorationImage(
                                      image: AssetImage(page["image"]),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPink.withOpacity(0.1),
                                        blurRadius: 40,
                                        offset: const Offset(0, 20),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 44),
                                Text(
                                  page["title"],
                                  style: GoogleFonts.syne(
                                    fontSize: 20, fontWeight: FontWeight.w800,
                                    color: theme.textColor, height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page["description"],
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: theme.mutedTextColor,
                                    fontSize: 14,
                                    height: 1.6,
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

              // ── Modern Floating Navigation Button with Circle Progress ──
              Container(
                padding: const EdgeInsets.only(bottom: 24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular Progress Track
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor: AppColors.border.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                      ),
                    ),
                    // Central Action Button
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              key: ValueKey<int>(_currentPage),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}