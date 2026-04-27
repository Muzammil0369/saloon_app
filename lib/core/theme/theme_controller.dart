import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> mode =
  ValueNotifier(ThemeMode.system);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode') ?? 'system';
    mode.value = switch (saved) {
      'light' => ThemeMode.light,
      'dark'  => ThemeMode.dark,
      _       => ThemeMode.system,
    };
  }

  static Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = mode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    prefs.setString('themeMode', mode.value.name);
  }
}