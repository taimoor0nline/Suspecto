import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/game_session.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/round_result.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/domain/services/ballot.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';
import 'package:suspecto/features/game/domain/services/scoring.dart';

enum RoundPhase { reveal, discussion, vote, tie, guess, result }

/// Runs one party's rounds: private reveal, timed discussion, private voting,
/// tie revotes, the imposters' last-chance guess and results. Scores
/// accumulate across rematches for the lifetime of the controller.
class RoundController extends ChangeNotifier {
  RoundController({
    required List<Player> players,
    required List<WordEntry> words,
    required this.imposterCount,
    required this.discussionMinutes,
    this.options = const GameOptions(),
    this.onCompleted,
    GameEngine? engine,
  })  : players = List.unmodifiable(players),
        words = List.unmodifiable(words),
        _engine = engine ?? GameEngine() {
    _deal();
  }

  final List<Player> players;
  final List<WordEntry> words;
  final int imposterCount;
  final int discussionMinutes;
  final GameOptions options;
  final void Function(RoundResult result)? onCompleted;
  final GameEngine _engine;

  late GameSession _session;
  late Ballot _ballot;
  late String _roundId;
  RoundPhase _phase = RoundPhase.reveal;
  int _index = 0;
  bool _cardVisible = false;
  bool _cardViewed = false;
  bool _voterReady = false;
  String? _selected;
  List<String> _suspects = const [];
  List<WordEntry> _guessOptions = const [];
  RoundResult? _result;
  final Map<String, int> _totals = {};
  int _roundsPlayed = 0;
  Timer? _timer;
  late int _remaining;
  DateTime? _deadline;

  GameSession get session => _session;
  Ballot get ballot => _ballot;
  RoundPhase get phase => _phase;
  int get index => _index;
  Player get currentPlayer => _session.players[_index];
  bool get isLastPlayer => _index == _session.players.length - 1;
  bool get cardVisible => _cardVisible;
  bool get cardViewed => _cardViewed;
  bool get voterReady => _voterReady;
  String? get selected => _selected;
  List<String> get suspects => _suspects;
  List<WordEntry> get guessOptions => _guessOptions;
  RoundResult? get result => _result;
  int get remainingSeconds => _remaining;
  int get roundsPlayed => _roundsPlayed;

  /// Session totals per player ID, highest first.
  List<MapEntry<Player, int>> get standings => [
        for (final p in players) MapEntry(p, _totals[p.id] ?? 0),
      ]..sort((a, b) => b.value.compareTo(a.value));

  void _deal() {
    _timer?.cancel();
    _roundId = DateTime.now().microsecondsSinceEpoch.toString();
    _session = _engine.createSession(
      players: players,
      words: words,
      imposterCount: imposterCount,
      mode: options.mode,
    );
    _ballot = Ballot(players.map((p) => p.id));
    _phase = RoundPhase.reveal;
    _index = 0;
    _cardVisible = false;
    _cardViewed = false;
    _voterReady = false;
    _selected = null;
    _suspects = const [];
    _guessOptions = const [];
    _result = null;
    _remaining = discussionMinutes * 60;
    _deadline = null;
  }

  void playAgain() {
    _deal();
    notifyListeners();
  }

  /// Hides anything private, e.g. when the app is backgrounded.
  void hidePrivate() {
    _cardVisible = false;
    _voterReady = false;
    _selected = null;
    notifyListeners();
  }

  void showCard(bool show) {
    if (_phase != RoundPhase.reveal || _cardVisible == show) {
      return;
    }
    _cardVisible = show;
    if (show) {
      _cardViewed = true;
    }
    notifyListeners();
  }

  void nextCard() {
    if (_phase != RoundPhase.reveal || !_cardViewed || _cardVisible) {
      return;
    }
    _cardViewed = false;
    if (isLastPlayer) {
      _phase = RoundPhase.discussion;
      _runTimer();
    } else {
      _index++;
    }
    notifyListeners();
  }

  void addDiscussionTime(Duration extra) {
    if (_phase != RoundPhase.discussion) {
      return;
    }
    _remaining += extra.inSeconds;
    _runTimer();
    notifyListeners();
  }

  void _runTimer() {
    _timer?.cancel();
    _deadline = DateTime.now().add(Duration(seconds: _remaining));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final seconds = _deadline!.difference(DateTime.now()).inSeconds;
      _remaining = seconds > 0 ? seconds : 0;
      if (_remaining == 0) {
        _timer?.cancel();
      }
      notifyListeners();
    });
  }

  void beginVoting() {
    _timer?.cancel();
    _phase = RoundPhase.vote;
    _index = 0;
    _selected = null;
    _voterReady = false;
    _ballot = Ballot(players.map((p) => p.id));
    notifyListeners();
  }

  void confirmVoter() {
    _voterReady = true;
    notifyListeners();
  }

  void select(String suspectId) {
    _selected = suspectId;
    notifyListeners();
  }

  void castVote() {
    final suspect = _selected;
    if (_phase != RoundPhase.vote || suspect == null) {
      return;
    }
    _ballot.vote(currentPlayer.id, suspect);
    _selected = null;
    _voterReady = false;
    if (!isLastPlayer) {
      _index++;
      notifyListeners();
      return;
    }
    final suspects = _ballot.suspects(imposterCount);
    if (suspects == null) {
      _phase = RoundPhase.tie;
      notifyListeners();
      return;
    }
    _suspects = suspects;
    final allCaught = suspects.every(_session.imposterPlayerIds.contains);
    if (allCaught && options.lastChanceGuess) {
      _guessOptions = _engine.guessOptions(_session, words);
      if (_guessOptions.isNotEmpty) {
        _phase = RoundPhase.guess;
        notifyListeners();
        return;
      }
    }
    _finish(stolen: false);
  }

  void submitGuess(WordEntry guess) {
    if (_phase != RoundPhase.guess) {
      return;
    }
    _finish(stolen: GameEngine.sameWord(guess, _session.secretWord));
  }

  void _finish({required bool stolen}) {
    final allCaught = _suspects.every(_session.imposterPlayerIds.contains);
    final points = Scoring.score(
      session: _session,
      votes: _ballot.votes,
      allCaught: allCaught,
      stolen: stolen,
    );
    points.forEach((id, value) => _totals[id] = (_totals[id] ?? 0) + value);
    _roundsPlayed++;
    _result = RoundResult(
      id: _roundId,
      session: _session,
      accusedIds: _suspects,
      stolen: stolen,
      points: points,
    );
    _phase = RoundPhase.result;
    notifyListeners();
    onCompleted?.call(_result!);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
