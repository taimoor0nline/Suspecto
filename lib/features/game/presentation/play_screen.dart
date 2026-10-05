import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/round_result.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/phases/discussion_phase.dart';
import 'package:suspecto/features/game/presentation/phases/guess_phase.dart';
import 'package:suspecto/features/game/presentation/phases/result_phase.dart';
import 'package:suspecto/features/game/presentation/phases/reveal_phase.dart';
import 'package:suspecto/features/game/presentation/phases/vote_phase.dart';

/// Hosts a party's rounds and routes each phase to its view.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.players,
    required this.words,
    required this.imposterCount,
    required this.discussionMinutes,
    this.options = const GameOptions(),
  });
  final List<Player> players;
  final List<WordEntry> words;
  final int imposterCount;
  final int discussionMinutes;
  final GameOptions options;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with WidgetsBindingObserver {
  late final RoundController _round = RoundController(
    players: widget.players,
    words: widget.words,
    imposterCount: widget.imposterCount,
    discussionMinutes: widget.discussionMinutes,
    options: widget.options,
    onCompleted: _record,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _round.hidePrivate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _round.dispose();
    super.dispose();
  }

  void _record(RoundResult result) {
    final store = StoreScope.maybeOf(context);
    if (store == null) {
      return;
    }
    final session = result.session;
    unawaited(store.recordRound(
      id: result.id,
      word: session.secretWord.value,
      category: session.secretWord.category,
      players: session.players.map((p) => p.name).toList(),
      imposters: session.imposters.map((p) => p.name).toList(),
      accused: result.accusedIds.map(result.nameOf).toList(),
      citizensWin: result.citizensWin,
      mode: result.mode.name,
      decoyWord: session.decoyWord?.value,
      customWord: session.secretWord.custom,
      stolen: result.stolen,
      points: {
        for (final entry in result.points.entries)
          result.nameOf(entry.key): entry.value,
      },
    ));
  }

  Future<void> _endRound() async {
    _round.hidePrivate();
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalText('End this round?'),
        content: const LocalText('Your current round will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalText('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const LocalText('End round'),
          ),
        ],
      ),
    );
    if (exit == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _round,
        builder: (context, _) => switch (_round.phase) {
          RoundPhase.reveal =>
            RevealPhase(round: _round, onEndRound: _endRound),
          RoundPhase.discussion =>
            DiscussionPhase(round: _round, onEndRound: _endRound),
          RoundPhase.vote => VotePhase(round: _round, onEndRound: _endRound),
          RoundPhase.tie => TiePhase(round: _round, onEndRound: _endRound),
          RoundPhase.guess => GuessPhase(round: _round, onEndRound: _endRound),
          RoundPhase.result =>
            ResultPhase(round: _round, onLeave: () => Navigator.pop(context)),
        },
      );
}
