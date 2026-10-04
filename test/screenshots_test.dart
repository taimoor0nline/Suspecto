import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/app/app.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/play_screen.dart';

void main() {
  if (!const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) { return; }
  testWidgets('capture beta screens for visual review', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/screenshots/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    final store = AppStore();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: SuspectoApp(store: store)));
    await capture('01-home');
    await tester.scrollUntilVisible(find.text('Start game'), 120);
    await tester.tap(find.text('Start game'));
    await capture('02-player-setup');
    store.language = 'ar';
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: SuspectoApp(store: store)));
    await capture('03-arabic-home');
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: const MaterialApp(home: PlayScreen(
      players: [Player(id: 'a', name: 'Ali'), Player(id: 'b', name: 'Sara'), Player(id: 'c', name: 'Omar')],
      words: [WordEntry(value: 'Pizza', category: 'Food')], imposterCount: 1, discussionMinutes: 1,
    ))));
    await capture('04-private-card');
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
