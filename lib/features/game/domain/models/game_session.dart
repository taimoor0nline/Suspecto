import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

class GameSession {
  GameSession({
    required List<Player> players,
    required Set<String> imposterPlayerIds,
    required this.secretWord,
    this.decoyWord,
    GameMode? mode,
    this.jesterId,
    this.accompliceId,
    this.detectiveId,
    this.detectiveClearId,
    String? startingPlayerId,
  })  : players = List.unmodifiable(players),
        imposterPlayerIds = Set.unmodifiable(imposterPlayerIds),
        mode = mode ??
            (decoyWord == null ? GameMode.classic : GameMode.undercover),
        startingPlayerId = startingPlayerId ?? players.first.id;

  final List<Player> players;
  final Set<String> imposterPlayerIds;

  /// The word, or in question mode the question, that innocent players get.
  final WordEntry secretWord;

  /// What imposters get in undercover and question modes; null in classic.
  final WordEntry? decoyWord;

  final GameMode mode;

  /// The innocent player who wins alone if voted out, when that role is on.
  final String? jesterId;

  /// The innocent player who knows the imposters and wins with them.
  final String? accompliceId;

  /// The innocent player who learns that [detectiveClearId] is innocent.
  final String? detectiveId;

  /// The player the Detective knows is not an imposter.
  final String? detectiveClearId;

  /// The player who gives the first clue or answer.
  final String startingPlayerId;

  bool isImposter(Player player) => imposterPlayerIds.contains(player.id);

  bool isJester(Player player) => player.id == jesterId;

  bool isAccomplice(Player player) => player.id == accompliceId;

  bool isDetective(Player player) => player.id == detectiveId;

  List<Player> get imposters => players.where(isImposter).toList();

  Player? get jester => players.where((p) => p.id == jesterId).firstOrNull;

  Player? get accomplice =>
      players.where((p) => p.id == accompliceId).firstOrNull;

  Player? get detective =>
      players.where((p) => p.id == detectiveId).firstOrNull;

  Player? get detectiveClear =>
      players.where((p) => p.id == detectiveClearId).firstOrNull;

  Player get startingPlayer =>
      players.firstWhere((p) => p.id == startingPlayerId);

  /// The word shown on [player]'s card, or null for a classic imposter.
  WordEntry? wordFor(Player player) =>
      isImposter(player) ? decoyWord : secretWord;
}
