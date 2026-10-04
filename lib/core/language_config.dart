import 'package:flutter/material.dart';

/// Bundled language availability. Changes take effect in the next app build.
class AppLanguage {
  const AppLanguage({required this.code, required this.name,
    required this.enabled, this.direction = TextDirection.ltr});
  final String code;
  final String name;
  final bool enabled;
  final TextDirection direction;

  Locale get locale {
    final parts = code.split('-');
    return Locale.fromSubtags(languageCode: parts.first,
        scriptCode: parts.length > 1 ? parts[1] : null);
  }
}

class LanguageConfig {
  LanguageConfig(List<AppLanguage> languages)
      : languages = List.unmodifiable(languages) {
    if (languages.map((item) => item.code).toSet().length != languages.length ||
        !languages.any((item) => item.code == 'en' && item.enabled)) {
      throw ArgumentError('Languages must have unique codes and enabled English.');
    }
  }
  final List<AppLanguage> languages;
  List<AppLanguage> get enabled =>
      languages.where((item) => item.enabled).toList(growable: false);
  AppLanguage resolve(String? code) => enabled.firstWhere(
      (item) => item.code == code,
      orElse: () => enabled.firstWhere((item) => item.code == 'en'));
}

final defaultLanguageConfig = LanguageConfig(const [
  AppLanguage(code: 'en', name: 'English', enabled: true),
  AppLanguage(code: 'ar', name: 'العربية', enabled: true,
      direction: TextDirection.rtl),
  // Enable only after UI and word translations have been added and reviewed.
  AppLanguage(code: 'es', name: 'Español', enabled: false),
  AppLanguage(code: 'fr', name: 'Français', enabled: false),
  AppLanguage(code: 'ja', name: '日本語', enabled: false),
  AppLanguage(code: 'zh-Hans', name: '简体中文', enabled: false),
  AppLanguage(code: 'zh-Hant', name: '繁體中文', enabled: false),
]);
