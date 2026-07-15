import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  static const String _prefKey = 'app_language';

  // ✅ Add this - observable locale
  var currentLocale = const Locale('en', 'US').obs;

  var languageCode = 'en'.obs;

  // Store current route to restore after language change
  String? _currentRoute;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_prefKey) ?? 'en';
    languageCode.value = savedLanguage;
    currentLocale.value = savedLanguage == 'ur'
        ? const Locale('ur', 'PK')
        : const Locale('en', 'US');
    Get.updateLocale(currentLocale.value);
  }

  Future<void> switchLanguage(String code) async {
    if (languageCode.value == code) return;

    // Save current route before language change
    _currentRoute = Get.currentRoute;

    languageCode.value = code;
    await _saveLanguagePreference(code);

    // ✅ Update locale
    currentLocale.value = code == 'ur'
        ? const Locale('ur', 'PK')
        : const Locale('en', 'US');

    await Get.updateLocale(currentLocale.value);

    // Navigate back to the same page
    if (_currentRoute != null && _currentRoute!.isNotEmpty) {
      Get.offAllNamed(_currentRoute!);
    }
  }

  Future<void> _saveLanguagePreference(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }

  bool get isUrdu => languageCode.value == 'ur';
  bool get isEnglish => languageCode.value == 'en';
}