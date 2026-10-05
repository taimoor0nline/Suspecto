import 'dart:async';

import 'package:suspecto/features/game/data/local/question_pairs.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/game_session.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/round_result.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/domain/services/ballot.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';
import 'package:suspecto/features/game/domain/services/party_awards.dart';
import 'package:suspecto/features/game/domain/services/scoring.dart';
import 'package:suspecto/features/lan/domain/lan_view.dart';

/// Settings the host chose before opening the lobby.
class LanGameConfig {
  const LanGameConfig({
    required this.imposterCount,
    required this.discussionMinutes,
    required this.options,
    required this.words,
    this.questions = questionPairs,
  });

  final int imposterCount;
  final int discussionMinutes;
  final GameOptions options;
  final List<WordEntry> words;
  final List<(WordEntry, WordEntry)> questions;
}

class _Member {
  _Member({required this.id, required this.name, required this.token});
  final String id;
  final String name;
  String token;
  bool connected = true;
}

/// Messages a phone can send. Host-only actions are ignored from other phones.
abstract final class LanAction {
  static const seen = 'seen';
  static const vote = 'vote';
  static const guess = 'guess';
  static const leave = 'leave';
  // Host only.
  static const start = 'start';
  static const discuss = 'discuss';
  static const addTime = 'addTime';
  static const revealQuestion = 'revealQuestion';
  static const startVote = 'startVote';
  static const lobby = 'lobby';
  static const kick = 'kick';
}

/// The authoritative multi-phone game, run on the host phone. It is
/// transport-agnostic: the host session feeds it joins and actions, and sends
/// each phone [viewFor] that phone, which never includes other players' roles.
///
/// Unlike pass-and-play, every phone reveals and votes at the same time.
class LanHostGame {
  LanHostGame({
    required String hostName,
    required this.config,
    GameEngine? engine,
    this.onChanged,
    this.onRoundComplete,
    this.onKicked,
  }) : _engine = engine ?? GameEngine() {
    _members.add(_Member(id: hostId, name: hostName.trim(), token: hostId));
  }

  static const hostId = 'h';
  static const maxPlayers = 20;

  final LanGameConfig config;
  final GameEngine _engine;
  final void Function()? onChanged;
  final void Function(RoundResult result)? onRoundComplete;
  final void Function(String playerId)? onKicked;

  final List<_Member> _members = [];
  int _nextId = 1;
  LanPhase _phase = LanPhase.lobby;
  int _round = 0;
  GameSession? _session;
  Ballot? _ballot;
  final Set<String> _seen = {};
  List<WordEntry> _guessOptions = const [];
  List<String> _accused = const [];
  RoundResult? _result;
  final Map<String, int> _totals = {};
  final List<RoundResult> _history = [];
  bool _questionRevealed = false;
  Timer? _timer;
  int _remaining = 0;
  DateTime? _deadline;

  LanPhase get phase => _phase;

  int get connectedCount => _members.where((m) => m.connected).length;

  _Member? _member(String id) {
    for (final m in _members) {
      if (m.id == id) {
        return m;
      }
    }
    return null;
  }

  bool _inRound(String id) => _session?.players.any((p) => p.id == id) ?? false;

  bool get _betweenRounds =>
      _phase == LanPhase.lobby || _phase == LanPhase.result;

  /// Admits a phone. Returns the player ID, or an English error to show.
  /// A known [token] (or the name of a disconnected player) rejoins as the
  /// same player, keeping their role and score.
  ({String? id, String? error}) join({
    required String name,
    required String token,
  }) {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 24) {
      return (id: null, error: 'Enter a name');
    }
    for (final m in _members) {
      if (m.id != hostId && m.token == token) {
        m.connected = true;
        _changed();
        return (id: m.id, error: null);
      }
    }
    for (final m in _members) {
      if (m.name.toLowerCase() == clean.toLowerCase()) {
        if (m.connected || m.id == hostId) {
          return (id: null, error: 'That name is already taken.');
        }
        m
          ..token = token
          ..connected = true;
        _changed();
        return (id: m.id, error: null);
      }
    }
    if (!_betweenRounds) {
      return (
        id: null,
        error: 'A round is in progress. Try again when it ends.'
      );
    }
    if (_members.length >= maxPlayers) {
      return (id: null, error: 'This game is full.');
    }
    final member = _Member(id: 'p${_nextId++}', name: clean, token: token);
    _members.add(member);
    _changed();
    return (id: member.id, error: null);
  }

  /// The phone's connection dropped; it may come back with the same token.
  void disconnected(String id) {
    final member = _member(id);
    if (member == null || id == hostId) {
      return;
    }
    member.connected = false;
    _changed();
  }

  void handle(String from, String type,
      [Map<String, Object?> data = const {}]) {
    final isHost = from == hostId;
    switch (type) {
      case LanAction.seen:
        if (_phase == LanPhase.reveal && _inRound(from) && _seen.add(from)) {
          if (_session!.players.every((p) => _seen.contains(p.id))) {
            _startDiscussion();
          }
          _changed();
        }
      case LanAction.vote:
        _vote(from, data['suspect']);
      case LanAction.guess:
        _guess(from, data['index']);
      case LanAction.leave:
        _leave(from);
      case LanAction.start when isHost && _betweenRounds:
        _startRound();
      case LanAction.discuss when isHost && _phase == LanPhase.reveal:
        _startDiscussion();
        _changed();
      case LanAction.revealQuestion
          when isHost && _phase == LanPhase.discussion:
        _questionRevealed = true;
        _changed();
      case LanAction.addTime when isHost && _phase == LanPhase.discussion:
        _remaining += 60;
        _runTimer();
        _changed();
      case LanAction.startVote
          when isHost &&
              (_phase == LanPhase.discussion || _phase == LanPhase.tie):
        _timer?.cancel();
        _ballot = Ballot(_session!.players.map((p) => p.id));
        _phase = LanPhase.vote;
        _changed();
      case LanAction.lobby when isHost:
        _timer?.cancel();
        _session = null;
        _result = null;
        _phase = LanPhase.lobby;
        _changed();
      case LanAction.kick when isHost && _betweenRounds:
        final id = data['id'];
        if (id is String && id != hostId && _member(id) != null) {
          _members.removeWhere((m) => m.id == id);
          onKicked?.call(id);
          _changed();
        }
    }
  }

  void _leave(String id) {
    if (id == hostId) {
      return;
    }
    if (_betweenRounds) {
      _members.removeWhere((m) => m.id == id);
      _changed();
    } else {
      disconnected(id);
    }
  }

  bool get canStart => _betweenRounds && connectedCount >= 3;

  void _startRound() {
    final players = [
      for (final m in _members)
        if (m.connected) Player(id: m.id, name: m.name),
    ];
    if (players.length < 3) {
      return;
    }
    _timer?.cancel();
    _session = _engine.createSession(
      players: players,
      words: config.words,
      imposterCount: config.imposterCount
          .clamp(1, GameEngine.maxImposters(players.length)),
      mode: config.options.mode,
      questions: config.questions,
      jester: config.options.jester,
    );
    _ballot = Ballot(players.map((p) => p.id));
    _seen.clear();
    _questionRevealed = false;
    _guessOptions = const [];
    _accused = const [];
    _result = null;
    _remaining = config.discussionMinutes * 60;
    _round++;
    _phase = LanPhase.reveal;
    _changed();
  }

  void _startDiscussion() {
    _phase = LanPhase.discussion;
    _runTimer();
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
      _changed();
    });
  }

  void _vote(String from, Object? suspect) {
    final ballot = _ballot;
    if (_phase != LanPhase.vote ||
        ballot == null ||
        suspect is! String ||
        ballot.votes.containsKey(from)) {
      return;
    }
    try {
      ballot.vote(from, suspect);
    } on ArgumentError {
      return;
    }
    final session = _session!;
    if (ballot.votes.length < session.players.length) {
      _changed();
      return;
    }
    final suspects = ballot.suspects(session.imposterPlayerIds.length);
    if (suspects == null) {
      _phase = LanPhase.tie;
      _changed();
      return;
    }
    _accused = suspects;
    final allCaught = suspects.every(session.imposterPlayerIds.contains);
    if (allCaught &&
        config.options.lastChanceGuess &&
        session.mode != GameMode.questions) {
      _guessOptions = _engine.guessOptions(session, config.words);
      if (_guessOptions.isNotEmpty) {
        _phase = LanPhase.guess;
        _changed();
        return;
      }
    }
    _finish(stolen: false);
  }

  void _guess(String from, Object? index) {
    final session = _session;
    if (_phase != LanPhase.guess ||
        session == null ||
        !session.imposterPlayerIds.contains(from) ||
        index is! int ||
        index < 0 ||
        index >= _guessOptions.length) {
      return;
    }
    _finish(
        stolen: GameEngine.sameWord(_guessOptions[index], session.secretWord));
  }

  void _finish({required bool stolen}) {
    final session = _session!;
    final points = Scoring.score(
      session: session,
      votes: _ballot!.votes,
      accusedIds: _accused,
      stolen: stolen,
    );
    points.forEach((id, value) => _totals[id] = (_totals[id] ?? 0) + value);
    _result = RoundResult(
      id: '${DateTime.now().microsecondsSinceEpoch}-$_round',
      session: session,
      accusedIds: _accused,
      stolen: stolen,
      points: points,
      votes: _ballot!.votes,
    );
    _history.add(_result!);
    _phase = LanPhase.result;
    _changed();
    onRoundComplete?.call(_result!);
  }

  void _changed() => onChanged?.call();

  /// The game as [playerId] may see it.
  LanView viewFor(String playerId) {
    final session = _session;
    final player = session?.players.where((p) => p.id == playerId).firstOrNull;
    final playing = _phase != LanPhase.lobby && player != null;
    LanCard? card;
    if (playing && _phase != LanPhase.result) {
      final word = session!.wordFor(player);
      card = LanCard(
        word: word == null ? null : LanWord.from(word),
        hint: word == null &&
                session.mode == GameMode.classic &&
                config.options.imposterHint
            ? LanWord(session.secretWord.category,
                custom: session.secretWord.custom)
            : null,
        jester: session.isJester(player),
      );
    }
    final result = _result;
    return LanView(
      phase: _phase,
      you: playerId,
      isHost: playerId == hostId,
      round: _round,
      mode: config.options.mode,
      imposterCount: config.imposterCount,
      players: [
        for (final m in _members)
          LanPlayerView(
            id: m.id,
            name: m.name,
            isHost: m.id == hostId,
            connected: m.connected,
            inRound: _phase != LanPhase.lobby && _inRound(m.id),
            done: switch (_phase) {
              LanPhase.reveal => _seen.contains(m.id),
              LanPhase.vote => _ballot?.votes.containsKey(m.id) ?? false,
              _ => false,
            },
          ),
      ],
      card: card,
      revealedQuestion: _questionRevealed &&
              _phase == LanPhase.discussion &&
              session?.mode == GameMode.questions
          ? LanWord.from(session!.secretWord)
          : null,
      starterId: session?.startingPlayerId,
      remainingSeconds: _remaining,
      myVote: _phase == LanPhase.vote ? _ballot?.votes[playerId] : null,
      guessOptions: _phase == LanPhase.guess
          ? [for (final w in _guessOptions) LanWord.from(w)]
          : const [],
      guesserIds: _phase == LanPhase.guess
          ? session!.imposterPlayerIds.toList()
          : const [],
      result: _phase == LanPhase.result && result != null
          ? LanResult(
              secret: LanWord.from(session!.secretWord),
              decoy: session.decoyWord == null
                  ? null
                  : LanWord.from(session.decoyWord!),
              imposterIds: session.imposterPlayerIds.toList(),
              accusedIds: result.accusedIds,
              votes: _ballot!.counts,
              points: result.points,
              citizensWin: result.citizensWin,
              stolen: result.stolen,
              jesterId: session.jesterId,
              jesterWin: result.jesterWin,
            )
          : null,
      scores: Map.of(_totals),
      awards:
          _phase == LanPhase.result ? PartyAwards.compute(_history) : const [],
    );
  }

  void dispose() => _timer?.cancel();
}
