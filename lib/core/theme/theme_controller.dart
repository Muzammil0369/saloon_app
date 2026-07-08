import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  var themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user has explicitly saved a theme preference
    final saved = prefs.getString('themeMode');
    
    if (saved != null) {
      isDarkMode.value = saved == 'dark';
      themeMode.value = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } else {
      // First launch: detect system theme
      final brightness = Get.isPlatformDarkMode;
      isDarkMode.value = brightness;
      themeMode.value = brightness ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
  }

  void _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', themeMode.value.name);
  }
}