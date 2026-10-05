class WordEntry {
  const WordEntry({
    required this.value,
    required this.category,
    this.difficulty = 1,
    this.custom = false,
  });

  final String value;
  final String category;
  final int difficulty;

  /// User-created words and categories are shown exactly as typed and are
  /// never passed through translation.
  final bool custom;
}
