import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Back button
              // GestureDetector(
              //   onTap: () => Navigator.pop(context),
              //   child: Container(
              //     width: 38, height: 38,
              //     decoration: BoxDecoration(
              //       color: AppColors.lightPink,
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: const Icon(Icons.arrow_back_ios_new_rounded,
              //         size: 16, color: AppColors.primaryPink),
              //   ),
              // ),

              const SizedBox(height: 24),

              // Title
              Text('Welcome Back! 👋', style: AppTextStyles.displayMedium),
              const SizedBox(height: 6),
              Text('Sign in to your account', style: AppTextStyles.bodySmall),

              const SizedBox(height: 28),

              // Login / Sign Up toggle
              Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _tabButton('Login', _isLogin, () {
                      setState(() => _isLogin = true);
                    }),
                    const SizedBox(width: 5,),
                    _tabButton('Sign Up', !_isLogin, () {
                      setState(() => _isLogin = false);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Phone field
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.mutedText, size: 20),
                ),
              ),

              const SizedBox(height: 12),

              // Name field — only on Sign Up
              if (!_isLogin) ...[
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.mutedText, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Password field
              TextField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.mutedText, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.mutedText,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Forgot password — login only
              if (_isLogin) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text('Forgot Password?',
                        style: AppTextStyles.linkText),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Primary button
              AppButton(
                label: _isLogin ? 'Sign In' : 'Create Account',
                onTap: () {},
              ),

              const SizedBox(height: 18),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: AppTextStyles.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 18),

              // Google button
              AppButton(
                label: 'Continue with Google',
                onTap: () {},
                isOutline: true,
                icon: Image.asset('assets/google_icon.png',
                    width: 18, height: 18),
              ),

              const SizedBox(height: 28),

              // Owner login
              Center(
                child: Column(
                  children: [
                    Text('Are you a salon owner?',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {},
                      child: Text('Login as Owner →',
                          style: AppTextStyles.linkText),
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

  Widget _tabButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [BoxShadow(
                color: AppColors.primaryPink.withOpacity(0.12),
                blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primaryPink : AppColors.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}