import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/game_session.dart';

/// A finished round, ready to be shown and saved to history.
class RoundResult {
  const RoundResult({
    required this.id,
    required this.session,
    required this.accusedIds,
    required this.stolen,
    required this.points,
  });

  final String id;
  final GameSession session;
  final List<String> accusedIds;

  /// Caught imposters guessed the secret word and took the win.
  final bool stolen;

  /// Points per player ID for this round.
  final Map<String, int> points;

  GameMode get mode => session.mode;

  bool get allCaught =>
      accusedIds.isNotEmpty &&
      accusedIds.every(session.imposterPlayerIds.contains);

  bool get citizensWin => allCaught && !stolen;

  String nameOf(String id) =>
      session.players.firstWhere((p) => p.id == id).name;
}
