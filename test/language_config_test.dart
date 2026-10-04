import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suspecto/app/app.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/language_config.dart';
import 'package:suspecto/features/settings/presentation/settings_screen.dart';

void main() {
  final englishOnly = LanguageConfig(const [
    AppLanguage(code: 'en', name: 'English', enabled: true),
    AppLanguage(code: 'ar', name: 'العربية', enabled: false,
        direction: TextDirection.rtl),
  ]);

  test('disabled saved language falls back to English', () async {
    SharedPreferences.setMockInitialValues({
      'suspecto.v1': jsonEncode({'language': 'ar'})
    });
    final store = AppStore(languageConfig: englishOnly);
    await store.load();
    expect(store.language, 'en');
    await store.updateSettings(language: 'ar');
    expect(store.language, 'en');
    await store.updateSettings(language: 'unknown');
    expect(store.language, 'en');
  });

  test('catalog requires an enabled English fallback and unique codes', () {
    expect(() => LanguageConfig(const []), throwsArgumentError);
    expect(() => LanguageConfig(const [
      AppLanguage(code: 'en', name: 'English', enabled: true),
      AppLanguage(code: 'en', name: 'Duplicate', enabled: false),
    ]), throwsArgumentError);
    expect(englishOnly.resolve('zh-Hans').code, 'en');
    expect(defaultLanguageConfig.resolve('ar').direction, TextDirection.rtl);
  });

  testWidgets('settings and supported locales exclude disabled languages',
      (tester) async {
    final store = AppStore(languageConfig: englishOnly);
    await tester.pumpWidget(SuspectoApp(store: store));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales, [const Locale('en')]);
    await tester.pumpWidget(StoreScope(store: store,
      child: const MaterialApp(home: SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsNothing);
    expect(find.text('Español'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
