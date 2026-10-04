import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

class GameSession {
  GameSession({
    required List<Player> players,
    required Set<String> imposterPlayerIds,
    required this.secretWord,
  }) : players = List.unmodifiable(players),
       imposterPlayerIds = Set.unmodifiable(imposterPlayerIds);

  final List<Player> players;
  final Set<String> imposterPlayerIds;
  final WordEntry secretWord;

  bool isImposter(Player player) => imposterPlayerIds.contains(player.id);
}
