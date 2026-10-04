import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/app/app.dart';
import 'package:suspecto/core/app_store.dart';

void main() {
  testWidgets('Arabic ballots preserve user-entered player identities', (tester) async {
    final store = AppStore()..language = 'ar';
    await tester.pumpWidget(StoreScope(store: store, child: const MaterialApp(home: PlayScreen(
      players: [Player(id: 'a', name: 'Pizza'), Player(id: 'b', name: 'Settings'), Player(id: 'c', name: 'Ali')],
      words: [WordEntry(value: 'Pizza', category: 'Food')], imposterCount: 1, discussionMinutes: 1,
    ))));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      final gesture = await tester.startGesture(tester.getCenter(find.text('اضغط باستمرار للكشف')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      final next = find.text(i == 2 ? 'ابدأ النقاش' : 'إخفاء وتمرير');
      await tester.scrollUntilVisible(next, 120);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(find.text('ابدأ التصويت السري'), 120);
    await tester.tap(find.text('ابدأ التصويت السري'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أنا Pizza'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('الإعدادات'), findsNothing);
    expect(find.text('Ali'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
  testWidgets('Arabic home uses translated content and right-to-left layout', (tester) async {
    final store = AppStore()..language = 'ar';
    await tester.pumpWidget(SuspectoApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('لا تثق بأحد.\nاشك في الجميع.'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('لا تثق بأحد.\nاشك في الجميع.'))), TextDirection.rtl);
    expect(tester.takeException(), isNull);
    store.dispose();
  });
}
