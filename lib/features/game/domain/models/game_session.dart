import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

class GameSession {
  GameSession({
    required List<Player> players,
    required Set<String> imposterPlayerIds,
    required this.secretWord,
    this.decoyWord,
    String? startingPlayerId,
  })  : players = List.unmodifiable(players),
        imposterPlayerIds = Set.unmodifiable(imposterPlayerIds),
        startingPlayerId = startingPlayerId ?? players.first.id;

  final List<Player> players;
  final Set<String> imposterPlayerIds;
  final WordEntry secretWord;

  /// The word imposters receive in undercover mode; null in classic mode.
  final WordEntry? decoyWord;

  /// The player who gives the first clue.
  final String startingPlayerId;

  GameMode get mode =>
      decoyWord == null ? GameMode.classic : GameMode.undercover;

  bool isImposter(Player player) => imposterPlayerIds.contains(player.id);

  List<Player> get imposters => players.where(isImposter).toList();

  Player get startingPlayer =>
      players.firstWhere((p) => p.id == startingPlayerId);

  /// The word shown on [player]'s card, or null for a classic imposter.
  WordEntry? wordFor(Player player) =>
      isImposter(player) ? decoyWord : secretWord;
}
