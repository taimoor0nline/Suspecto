import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';

/// The words a round can deal from the chosen [packs] at the chosen
/// difficulty, or an English error to show. Question mode needs no words.
({List<WordEntry> words, String? error}) dealableWords(
    List<WordPack> packs, GameOptions options) {
  if (options.mode == GameMode.questions) {
    return (words: const [], error: null);
  }
  if (packs.isEmpty) {
    return (words: const [], error: 'Choose at least one category.');
  }
  final words =
      options.difficulty.filter([for (final pack in packs) ...pack.entries]);
  return words.isEmpty
      ? (
          words: const [],
          error: 'No words in these packs match that difficulty.'
        )
      : (words: words, error: null);
}
