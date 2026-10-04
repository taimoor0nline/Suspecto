import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

class GameSession {
  const GameSession({
    required this.players,
    required this.imposterPlayerId,
    required this.secretWord,
  });

  final List<Player> players;
  final String imposterPlayerId;
  final WordEntry secretWord;

  bool isImposter(Player player) => player.id == imposterPlayerId;
}
