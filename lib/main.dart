import 'package:flutter/material.dart';
import 'package:saloon_app/core/theme/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/combine/combine_screens/onboarding_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:     AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,           // ← listens to controller
          home: const OnboardingScreen(),
        );
      },
    );
  }
}

