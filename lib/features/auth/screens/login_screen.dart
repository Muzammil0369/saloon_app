import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/owner_main_wrapper.dart';
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
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Title
              Text('Welcome \nBack! 👋',
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 38,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text('Sign in to your account',
                style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor),
              ),

              const SizedBox(height: 28),

              // Login / Sign Up toggle
              Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.lightPinkColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _tabButton('Login', _isLogin, () {
                      setState(() => _isLogin = true);
                    }, theme),
                    const SizedBox(width: 5),
                    _tabButton('Sign Up', !_isLogin, () {
                      setState(() => _isLogin = false);
                    }, theme),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Phone field
              TextField(
                keyboardType: TextInputType.phone,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: TextStyle(color: theme.mutedTextColor),
                  prefixIcon: Icon(Icons.phone_outlined, color: theme.mutedTextColor, size: 20),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Name field — only on Sign Up
              if (!_isLogin) ...[
                TextField(
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(color: theme.mutedTextColor),
                    prefixIcon: Icon(Icons.person_outline, color: theme.mutedTextColor, size: 20),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Password field
              TextField(
                obscureText: _obscurePassword,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: theme.mutedTextColor),
                  prefixIcon: Icon(Icons.lock_outline, color: theme.mutedTextColor, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: theme.mutedTextColor,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.borderColor),
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
                    child: Text('Forgot Password?', style: AppTextStyles.linkText),
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
                  Expanded(child: Divider(color: theme.borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor)),
                  ),
                  Expanded(child: Divider(color: theme.borderColor)),
                ],
              ),

              const SizedBox(height: 18),

              // Google button
              Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/google.png', height: 26),
                    const SizedBox(width: 4),
                    Text(
                      'Continue with Google',
                      style: AppTextStyles.buttonText?.copyWith(color: theme.textColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Owner login
              Center(
                child: Column(
                  children: [
                    Text('Are you a salon owner?',
                      style: AppTextStyles.bodySmall?.copyWith(color: theme.mutedTextColor),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OwnerMainWrapper()),
                        );
                      },
                      child: Text('Login as Owner →', style: AppTextStyles.linkText),
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

  Widget _tabButton(String label, bool isActive, VoidCallback onTap, ThemeHelper theme) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primaryPink : theme.mutedTextColor,
            ),
          ),
        ),
      ),
    );
  }
}