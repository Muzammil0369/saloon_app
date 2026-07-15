import 'package:get/get.dart';
import 'translation_service.dart';

class DynamicTranslationService extends GetxService {
  final TranslationService _translationService = Get.find<TranslationService>();

  /// Translates user input fields from English to Urdu
  /// Used during registration and profile updates
  Future<Map<String, String>> translateUserInput({
    required Map<String, String> fields,
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'en') {
      return fields; // No translation needed for English
    }

    final Map<String, String> translatedFields = {};

    for (var entry in fields.entries) {
      if (entry.value.isNotEmpty) {
        final translated = await _translationService.translateEnToUr(entry.value);
        translatedFields[entry.key] = translated;
      } else {
        translatedFields[entry.key] = entry.value;
      }
    }

    return translatedFields;
  }

  /// Batch translate multiple fields
  Future<Map<String, String>> batchTranslate({
    required Map<String, String> fields,
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'en') {
      return fields;
    }

    final results = <String, String>{};
    for (var entry in fields.entries) {
      if (entry.value.isNotEmpty) {
        final translated = await _translationService.translateEnToUr(entry.value);
        results[entry.key] = translated;
      } else {
        results[entry.key] = entry.value;
      }
    }
    return results;
  }
}