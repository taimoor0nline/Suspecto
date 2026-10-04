import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suspecto/features/game/domain/models/game_session.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/domain/services/ballot.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';

enum _Phase { reveal, discussion, vote, tie, result }

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.players,
    required this.words,
    required this.imposterCount,
    required this.discussionMinutes,
  });
  final List<Player> players;
  final List<WordEntry> words;
  final int imposterCount;
  final int discussionMinutes;
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with WidgetsBindingObserver {
  late GameSession _session;
  late Ballot _ballot;
  _Phase _phase = _Phase.reveal;
  int _index = 0;
  bool _visible = false;
  bool _viewed = false;
  bool _voterReady = false;
  String? _selected;
  List<String> _suspects = [];
  Timer? _timer;
  late int _remaining;
  DateTime? _deadline;
  late String _roundId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _newRound();
  }

  void _newRound() {
    _roundId = DateTime.now().microsecondsSinceEpoch.toString();
    _timer?.cancel();
    _session = GameEngine().createSession(
      players: widget.players,
      words: widget.words,
      imposterCount: widget.imposterCount,
    );
    _ballot = Ballot(_session.players.map((p) => p.id));
    _phase = _Phase.reveal;
    _index = 0;
    _visible = false;
    _viewed = false;
    _voterReady = false;
    _selected = null;
    _suspects = [];
    _remaining = widget.discussionMinutes * 60;
    _deadline = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setState(() {
        _visible = false;
        _voterReady = false;
        _selected = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _show(bool show) {
    if (show && !_visible) { StoreScope.maybeOf(context)?.feedback(reveal: true); }
    setState(() {
      _visible = show;
      if (show) {
        _viewed = true;
      }
    });
  }

  void _nextCard() {
    StoreScope.maybeOf(context)?.feedback();
    setState(() {
      _visible = false;
      _viewed = false;
      if (_index < _session.players.length - 1) {
        _index++;
      } else {
        _phase = _Phase.discussion;
        _deadline = DateTime.now().add(Duration(seconds: _remaining));
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          final seconds = _deadline!.difference(DateTime.now()).inSeconds;
          setState(() => _remaining = seconds > 0 ? seconds : 0);
          if (_remaining == 0) {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _beginVoting() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.vote;
      _index = 0;
      _selected = null;
      _voterReady = false;
      _ballot = Ballot(_session.players.map((p) => p.id));
    });
  }

  void _castVote() {
    StoreScope.maybeOf(context)?.feedback();
    _ballot.vote(_session.players[_index].id, _selected!);
    setState(() {
      _selected = null;
      _voterReady = false;
      if (_index < _session.players.length - 1) {
        _index++;
      } else {
        final suspects = _ballot.suspects(widget.imposterCount);
        if (suspects == null) {
          _phase = _Phase.tie;
        } else {
          _suspects = suspects;
          _phase = _Phase.result;
        }
      }
    });
    if (_phase == _Phase.result) {
      final store = StoreScope.maybeOf(context);
      if (store != null) {
        unawaited(store.recordRound(id: _roundId, word: _session.secretWord.value, category: _session.secretWord.category, players: _session.players.map((p) => p.name).toList(), imposters: _session.players.where(_session.isImposter).map((p) => p.name).toList(), accused: _session.players.where((p) => _suspects.contains(p.id)).map((p) => p.name).toList(), citizensWin: _suspects.every(_session.imposterPlayerIds.contains)));
      }
    }
  }

  Future<void> _exit() async {
    _show(false);
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = _session.players[_index];
    final citizensWin =
        _suspects.isNotEmpty &&
        _suspects.every(_session.imposterPlayerIds.contains);
    String title;
    String subtitle;
    List<Widget> children;
    switch (_phase) {
      case _Phase.reveal:
        title = 'Pass to ${player.name}';
        subtitle =
            'Card ${_index + 1} of ${_session.players.length}. Everyone else, look away.';
        children = [
          Listener(
            onPointerDown: (_) => _show(true),
            onPointerUp: (_) => _show(false),
            onPointerCancel: (_) => _show(false),
            child: Semantics(
              label: translate(context, 'Hold to reveal your secret card'),
              child: AnimatedContainer(
                  duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 160),
                constraints: const BoxConstraints(minHeight: 260),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _visible
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _visible ? Icons.visibility : Icons.fingerprint,
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    LocalText(
                      _visible
                          ? (_session.isImposter(player)
                                ? 'You are the imposter'
                                : _session.secretWord.value)
                          : 'Hold to reveal',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    LocalText(
                      _visible
                          ? (_session.isImposter(player)
                                ? 'Blend in. Listen to the clues. Bluff your way through.'
                                : 'Remember the word. Give a clue, but do not say it.')
                          : 'Release to hide your card.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _viewed && !_visible ? _nextCard : null,
            child: LocalText(
              _index == _session.players.length - 1
                  ? 'Start discussion'
                  : 'Hide & pass',
            ),
          ),
        ];
      case _Phase.discussion:
        title = 'Let the bluffing begin';
        subtitle =
            '${_session.players.first.name} starts. Give one clue each, then discuss who is bluffing. Keep the word secret.';
        children = [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.timer_outlined, size: 48),
                  const SizedBox(height: 16),
                  LocalText(
                    '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}',
                    style: theme.textTheme.displayLarge,
                  ),
                  LocalText(_remaining == 0 ? 'Time to vote!' : 'Discussion time'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _beginVoting,
            child: const LocalText('Start private voting'),
          ),
        ];
      case _Phase.vote:
        title = 'Pass to ${player.name}';
        subtitle =
            'Vote ${_index + 1} of ${_session.players.length}. Choose your suspect privately.';
        children = _voterReady
            ? [
                for (final candidate in _session.players.where(
                  (p) => p.id != player.id,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _selected = candidate.id),
                      icon: Icon(
                        _selected == candidate.id
                            ? Icons.check_circle
                            : Icons.person_outline,
                      ),
                      label: LocalText(candidate.name),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _selected == null ? null : _castVote,
                  child: const LocalText('Submit private vote'),
                ),
              ]
            : [
                const Icon(Icons.how_to_vote_outlined, size: 88),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => setState(() => _voterReady = true),
                  child: LocalText('I am ${player.name}'),
                ),
              ];
      case _Phase.tie:
        title = 'Too close to call';
        subtitle = 'The vote is tied at the cutoff. Discuss again, then everyone votes again. Roles stay secret.';
        children = [
          const Icon(Icons.balance, size: 88),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _beginVoting,
            child: const LocalText('Vote again'),
          ),
        ];
      case _Phase.result:
        title = citizensWin ? 'Caught in the act!' : 'The bluff worked!';
        subtitle = citizensWin
            ? 'The group caught every imposter.'
            : 'At least one imposter escaped. Imposters win this round.';
        children = [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    citizensWin ? Icons.emoji_events : Icons.theater_comedy,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const LocalText('THE SECRET WORD'),
                  LocalText(
                    _session.secretWord.value,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  LocalText(
                    'Imposters: ${_session.players.where(_session.isImposter).map((p) => p.name).join(', ')}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          LocalText('The votes', style: theme.textTheme.titleLarge),
          for (final p in _session.players)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: LocalText(p.name),
              subtitle: LocalText(
                _suspects.contains(p.id)
                    ? 'Accused by the group'
                    : 'Not accused',
              ),
              trailing: LocalText('${_ballot.counts[p.id]} votes'),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => setState(_newRound),
            child: const LocalText('Play again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const LocalText('Change players & settings'),
          ),
        ];
    }
    return GamePage(
      canPop: false,
      title: title,
      subtitle: subtitle,
      children: [
        ...children,
        if (_phase != _Phase.result) ...[
          const SizedBox(height: 20),
          TextButton(onPressed: _exit, child: const LocalText('End round')),
        ],
      ],
    );
  }
}
