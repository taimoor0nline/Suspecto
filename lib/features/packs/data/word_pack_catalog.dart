import 'package:suspecto/features/game/data/local/starter_words.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';

/// Built-in packs, one per category in content order. Their IDs are the
/// category names, which keeps previously saved selections valid.
final List<WordPack> builtInPacks = List.unmodifiable([
  for (final category in starterWords.map((w) => w.category).toSet())
    WordPack(
      id: category,
      name: category,
      entries: starterWords.where((w) => w.category == category).toList(),
    ),
]);
