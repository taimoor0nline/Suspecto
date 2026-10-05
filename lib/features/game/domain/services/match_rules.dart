/// Party-mode rules shared by pass-the-phone and multi-phone games.
class MatchRules {
  MatchRules._();

  /// The match winner's ID: the single leader once they reach [target].
  /// Null for endless play ([target] 0), before the target, or while tied at
  /// the top (play continues until one player leads).
  static String? champion(Map<String, int> totals, int target) {
    final leader = _top(totals);
    if (target <= 0 || leader == null || leader.$2 < target || leader.$3) {
      return null;
    }
    return leader.$1;
  }

  /// Players are tied at the top on or above [target].
  static bool tied(Map<String, int> totals, int target) {
    final leader = _top(totals);
    return target > 0 && leader != null && leader.$2 >= target && leader.$3;
  }

  /// (leader ID, best score, whether another player shares it).
  static (String, int, bool)? _top(Map<String, int> totals) {
    if (totals.isEmpty) {
      return null;
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.first;
    return (
      best.key,
      best.value,
      ranked.length > 1 && ranked[1].value == best.value,
    );
  }
}
