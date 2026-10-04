import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suspecto/app/app.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/language_config.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/core/ui_translations.dart';
import 'package:suspecto/features/game/data/local/starter_words.dart';
import 'package:suspecto/features/game/data/local/word_translations.dart';

void main() {
  final starts = {'es': 'Empezar partida', 'fr': 'Commencer la partie',
    'ja': 'ゲームを始める', 'zh-Hans': '开始游戏', 'zh-Hant': '開始遊戲'};
  for (final code in starts.keys) {
    test('$code translates every word and preserves user identities', () {
      expect(wordTranslations[code]!.length, starterWords.length);
      for (final word in starterWords) {
        expect(wordTranslations[code]![word.value], isNotEmpty);
      }
      final identity = 'Pizza / Settings / 李 / Ali';
      expect(translateForLanguage(code, 'Pass to $identity'), contains(identity));
      expect(translateForLanguage(code, 'I am $identity'), contains(identity));
      expect(translateForLanguage(code, 'Imposters: $identity'), contains(identity));
      expect(translateForLanguage(code, 'untranslated fallback'),
          'untranslated fallback');
      expect(uiTranslations[code]!['Language'], isNotEmpty);
    });
    testWidgets('$code switches live and persists across reload', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = AppStore();
      await tester.pumpWidget(SuspectoApp(store: store));
      await tester.pumpAndSettle();
      await store.updateSettings(language: code);
      await tester.pumpAndSettle();
      expect(find.text(starts[code]!), findsOneWidget);
      expect(Directionality.of(tester.element(find.text(starts[code]!))),
          TextDirection.ltr);
      final reloaded = AppStore();
      await reloaded.load();
      expect(reloaded.language, code);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      reloaded.dispose();
    });
  }
  test('Chinese scripts are distinct supported locales', () {
    expect(defaultLanguageConfig.resolve('zh-Hans').locale.scriptCode, 'Hans');
    expect(defaultLanguageConfig.resolve('zh-Hant').locale.scriptCode, 'Hant');
    expect(wordTranslations['zh-Hans']!['Airplane'], '飞机');
    expect(wordTranslations['zh-Hant']!['Airplane'], '飛機');
  });
}
