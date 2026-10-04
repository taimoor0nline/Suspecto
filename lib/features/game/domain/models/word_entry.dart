class WordEntry {
  const WordEntry({
    required this.value,
    required this.category,
    this.difficulty = 1,
  });

  final String value;
  final String category;
  final int difficulty;
}
