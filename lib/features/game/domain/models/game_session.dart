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

  /// The player who gives the first clue or answer.
  final String startingPlayerId;

  bool isImposter(Player player) => imposterPlayerIds.contains(player.id);

  bool isJester(Player player) => player.id == jesterId;

  List<Player> get imposters => players.where(isImposter).toList();

  Player? get jester => players.where((p) => p.id == jesterId).firstOrNull;

  Player get startingPlayer =>
      players.firstWhere((p) => p.id == startingPlayerId);

  /// The word shown on [player]'s card, or null for a classic imposter.
  WordEntry? wordFor(Player player) =>
      isImposter(player) ? decoyWord : secretWord;
}
