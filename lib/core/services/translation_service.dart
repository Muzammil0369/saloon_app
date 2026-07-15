import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Add this import

class TranslationService extends GetxService {
  static const String _apiUrl = 'https://translate.googleapis.com/translate?sl=en&tl=ur&client=gt';

  /// Translates English text to Urdu.
  /// Since we are in a prototype phase, we use the Google Translate free endpoint.
  Future<String> translateEnToUr(String text) async {
    if (text.isEmpty) return '';
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl&q=${Uri.encodeComponent(text)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The response is a nested list: [[translatedText, null, null, ...]]
        return data[0][0] as String;
      } else {
        debugPrint('Translation API error: ${response.statusCode}');
        return text; // Fallback to original text
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      return text; // Fallback to original text
    }
  }

  /// Translates Urdu text to English (for reverse direction if needed)
  Future<String> translateUrToEn(String text) async {
    if (text.isEmpty) return '';
    try {
      final response = await http.get(
        Uri.parse('https://translate.googleapis.com/translate?sl=ur&tl=en&client=gt&q=${Uri.encodeComponent(text)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data[0][0] as String;
      } else {
        debugPrint('Translation API error: ${response.statusCode}');
        return text;
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }
}