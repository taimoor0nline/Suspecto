import 'package:suspecto/features/game/domain/models/word_entry.dart';

/// A selectable collection of words. Built-in packs are compiled into the app;
/// custom packs are created by players and stored on the device.
class WordPack {
  WordPack({
    required this.id,
    required this.name,
    required List<WordEntry> entries,
    this.custom = false,
  }) : entries = List.unmodifiable(entries);

  /// Builds a custom pack from typed words. Call [validate] first.
  factory WordPack.custom({
    required String id,
    required String name,
    required Iterable<String> words,
  }) {
    final cleanName = name.trim();
    return WordPack(
      id: id,
      name: cleanName,
      custom: true,
      entries: [
        for (final word in normalizeWords(words))
          WordEntry(value: word, category: cleanName, custom: true),
      ],
    );
  }

  static const customPrefix = 'custom:';
  static const minWords = 3;
  static const maxWords = 200;
  static const maxNameLength = 24;
  static const maxWordLength = 32;
  static const maxCustomPacks = 50;

  final String id;
  final String name;
  final List<WordEntry> entries;
  final bool custom;

  List<String> get words => entries.map((e) => e.value).toList();

  static String newCustomId() =>
      '$customPrefix${DateTime.now().microsecondsSinceEpoch}';

  /// Trims, drops blanks and removes case-insensitive duplicates, keeping order.
  static List<String> normalizeWords(Iterable<String> words) {
    final seen = <String>{};
    return [
      for (final word in words.map((w) => w.trim()))
        if (word.isNotEmpty && seen.add(word.toLowerCase())) word,
    ];
  }

  /// Splits editor input on new lines and commas.
  static List<String> parseWords(String text) =>
      normalizeWords(text.split(RegExp(r'[\n,،]')));

  /// Returns an English error message (translated by the UI), or null.
  static String? validate({
    required String name,
    required List<String> words,
    Iterable<String> otherNames = const [],
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return 'Name your pack';
    }
    if (cleanName.length > maxNameLength) {
      return 'Pack names can be up to 24 characters.';
    }
    if (otherNames
        .any((n) => n.trim().toLowerCase() == cleanName.toLowerCase())) {
      return 'You already have a pack with this name.';
    }
    if (words.length < minWords) {
      return 'Add at least 3 different words.';
    }
    if (words.length > maxWords) {
      return 'Packs can hold up to 200 words.';
    }
    if (words.any((w) => w.length > maxWordLength)) {
      return 'Words can be up to 32 characters.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'words': words};

  /// Parses a saved custom pack, returning null if it is malformed.
  static WordPack? fromJson(Object? json) {
    if (json is! Map ||
        json['id'] is! String ||
        !(json['id'] as String).startsWith(customPrefix) ||
        json['name'] is! String ||
        json['words'] is! List) {
      return null;
    }
    final rawWords = json['words'] as List;
    if (!rawWords.every((w) => w is String)) {
      return null;
    }
    final words = normalizeWords(rawWords.cast<String>());
    if (validate(name: json['name'] as String, words: words) != null) {
      return null;
    }
    return WordPack.custom(
      id: json['id'] as String,
      name: json['name'] as String,
      words: words,
    );
  }
}
