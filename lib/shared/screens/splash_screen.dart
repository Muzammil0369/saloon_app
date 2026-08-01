import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Controller set for exactly 3 seconds to manage the splash duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Fade-in animations for logo and text elements
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Subtle scale animation for the central logo (pop effect)
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Start filling the bar and fade elements
    _controller.forward();

    // 2. Navigate away seamlessly once the animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Replace with your actual home/auth page route name
        Get.offNamed('/auth-gate');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Brand primary background color matching your exact tone
      backgroundColor: const Color(0xFFA0204A),
      body: SafeArea(
        child: Stack(
          children: [
            // ─── Centered Logo Component ───
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipOval(
                              child: Container(
                                height: 180,
                                width: 180,
                                color: Colors.white, // Optional: background color
                                child: Image.asset(
                                  'assets/app_icon.png',
                                  fit: BoxFit.cover, // This crops the image to fill the circle
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── Bottom Info, Slogan & Loading Bar ───
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stylized Syne App Name Heading
                          Text(
                            'SALONIFY',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tagline Slogan utilizing readable DM Sans styling
                          Text(
                            'Where Beauty Meets Convenience',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.tagline.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Perfect Smooth Left-To-Right Loading Bar
                          SizedBox(
                            width: 150, // Ideal width to look clean and neat on all phone screens
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10), // Clean rounded ends
                              child: LinearProgressIndicator(
                                value: _controller.value, // Smoothly filled from 0.0 to 1.0 by controller
                                backgroundColor: Colors.white.withOpacity(0.15), // Dim background track
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // Solid white loading progress
                                minHeight: 4, // Ultra-sleek thickness
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}