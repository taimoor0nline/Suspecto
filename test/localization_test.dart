import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/app/app.dart';
import 'package:suspecto/core/app_store.dart';

void main() {
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
