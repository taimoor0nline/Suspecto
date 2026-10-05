/// A private ballot per player. Ties at the selection boundary require a revote.
class Ballot {
  Ballot(Iterable<String> playerIds) : _ids = Set.unmodifiable(playerIds);
  final Set<String> _ids;
  final Map<String, String> _votes = {};

  void vote(String voter, String suspect) {
    if (!_ids.contains(voter) || !_ids.contains(suspect) || voter == suspect) {
      throw ArgumentError('Choose another player in this game.');
    }
    if (_votes.containsKey(voter)) {
      throw StateError('Already voted.');
    }
    _votes[voter] = suspect;
  }

  /// Voter ID to suspect ID for every ballot cast so far.
  Map<String, String> get votes => Map.unmodifiable(_votes);

  Map<String, int> get counts {
    final result = {for (final id in _ids) id: 0};
    for (final suspect in _votes.values) {
      result[suspect] = result[suspect]! + 1;
    }
    return Map.unmodifiable(result);
  }

  List<String>? suspects(int count) {
    if (_votes.length != _ids.length) {
      throw StateError('Everyone must vote.');
    }
    if (count < 1 || count >= _ids.length) {
      throw ArgumentError('Invalid suspect count.');
    }
    final tally = counts;
    final ranked = _ids.toList()
      ..sort((a, b) => tally[b]!.compareTo(tally[a]!));
    if (tally[ranked[count - 1]] == tally[ranked[count]]) {
      return null;
    }
    return List.unmodifiable(ranked.take(count));
  }
}
