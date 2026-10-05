import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suspecto/app/app.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/features/lan/domain/join_code.dart';
import 'package:suspecto/features/lan/domain/join_link.dart';
import 'package:suspecto/features/lan/domain/room_code.dart';
import 'package:suspecto/features/lan/presentation/join_screen.dart';

void main() {
  const wifi = JoinCode(host: '192.168.1.23', port: JoinCode.basePort + 3);
  const room = RoomCode('K7F2QD');
  final wifiChars = wifi.code.replaceAll('-', '');

  test('links round-trip and old QR codes still parse', () {
    expect(JoinLink.forRoom(room), 'suspecto://room/K7F2QD');
    expect(JoinLink.forWifi(wifi), 'suspecto://join/$wifiChars');
    expect(RoomCode.parse(room.qrData)!.code, room.code);
    expect(RoomCode.parse('suspecto:room:K7F2QD')!.code, room.code);
    final parsed = JoinCode.parse(wifi.qrData)!;
    expect((parsed.host, parsed.port), (wifi.host, wifi.port));
    expect(JoinCode.parse('suspecto:join:${wifi.code}')!.host, wifi.host);
  });

  test('links and the routes platforms derive from them', () {
    for (final link in [
      'suspecto://room/K7F2QD',
      'SUSPECTO://ROOM/k7f2qd',
      '/K7F2QD',
      '/room/K7F2QD',
    ]) {
      expect(JoinLink.parse(link), isA<RoomCode>(), reason: link);
    }
    for (final link in [
      'suspecto://join/$wifiChars',
      '/$wifiChars',
      '/join/$wifiChars',
    ]) {
      final code = JoinLink.parse(link);
      expect(code, isA<JoinCode>(), reason: link);
      expect((code! as JoinCode).host, wifi.host);
    }
    for (final link in [
      '',
      '/',
      'https://example.com/K7F2QD',
      'suspecto://room/K7F2QD/extra',
      '/settings/K7F2QD',
      'suspecto://room/NOPE',
    ]) {
      expect(JoinLink.parse(link), isNull, reason: link);
    }
  });

  testWidgets('a join link opens the join screen with the code filled in',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await tester.pumpWidget(SuspectoApp(store: store));
    await tester.pumpAndSettle();
    await tester.binding.handlePushRoute('/join/$wifiChars');
    await tester.pumpAndSettle();
    expect(find.byType(JoinScreen), findsOneWidget);
    expect(find.text(wifi.code), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.binding.handlePushRoute('/not-a-game');
    await tester.pumpAndSettle();
    expect(find.text("This link didn't work"), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
