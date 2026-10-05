import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';
import 'package:suspecto/features/game/presentation/play_screen.dart';
import 'package:suspecto/features/game/presentation/setup_screen.dart';
import 'package:suspecto/features/packs/data/word_pack_catalog.dart';
import 'package:suspecto/features/packs/domain/dealable_words.dart';

/// Deals a new pass-and-play round with the last saved setup, or opens setup
/// when there is no usable saved setup yet.
void quickStart(BuildContext context) {
  final navigator = Navigator.of(context);
  final store = StoreScope.maybeOf(context);
  void openSetup() => navigator
      .push(MaterialPageRoute<void>(builder: (_) => const SetupScreen()));
  if (store == null || store.lastPlayers.length < 3) {
    openSetup();
    return;
  }
  final allPacks = [...builtInPacks, ...store.customPacks];
  final saved = allPacks.where((p) => store.lastCategories.contains(p.id));
  final packs = saved.isEmpty ? builtInPacks : saved.toList();
  final deal = dealableWords(packs, store.lastOptions);
  if (deal.error != null) {
    openSetup();
    return;
  }
  final players = [
    for (final (i, name) in store.lastPlayers.indexed)
      Player(id: '$i', name: name),
  ];
  store.feedback();
  navigator.push(MaterialPageRoute<void>(
    builder: (_) => PlayScreen(
      players: players,
      words: deal.words,
      imposterCount:
          store.lastImposters.clamp(1, GameEngine.maxImposters(players.length)),
      discussionMinutes:
          [1, 3, 5].contains(store.lastMinutes) ? store.lastMinutes : 3,
      options: store.lastOptions,
    ),
  ));
}
