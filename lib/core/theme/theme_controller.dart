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
    final saved = prefs.getString('themeMode') ?? 'light';
    isDarkMode.value = saved == 'dark';
    themeMode.value = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    themeMode.value = isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
  }

  void _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', themeMode.value.name);
  }
}