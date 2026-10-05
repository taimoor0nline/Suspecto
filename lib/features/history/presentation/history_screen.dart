import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _clear(BuildContext context, AppStore store) async {
    final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const LocalText('Clear all history?'),
                content: const LocalText(
                    'This deletes saved rounds and player stats from this device.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const LocalText('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const LocalText('Clear'))
                ]));
    if (clear == true) {
      await store.clearHistory();
    }
  }

  /// Saved words from custom packs are shown as typed, never translated.
  static Widget _word(Map<String, dynamic> round, String key,
          {TextStyle? style}) =>
      round['customWord'] == true
          ? Text(round[key] as String, style: style)
          : LocalText(round[key] as String, style: style);

  String _outcome(Map<String, dynamic> round) => round['jesterWin'] == true
      ? 'The Jester won'
      : round['citizensWin'] == true
          ? 'Citizens won'
          : round['stolen'] == true
              ? 'Imposters stole the win'
              : 'Imposters won';

  /// Saved mode labels; classic rounds show no label.
  static const _modeLabels = {
    'undercover': 'Undercover',
    'questions': 'Questions',
  };

  void _details(BuildContext context, Map<String, dynamic> round) {
    final points = (round['points'] as Map?) ?? const {};
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: _word(round, 'word'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalText(_outcome(round)),
                    if (round['decoyWord'] is String) ...[
                      const SizedBox(height: 8),
                      LocalText(round['mode'] == 'questions'
                          ? "THE IMPOSTERS' QUESTION"
                          : "THE IMPOSTERS' WORD"),
                      _word(round, 'decoyWord',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 8),
                    LocalText(
                        'Imposters: ${(round['imposters'] as List).join(', ')}'),
                    if (round['jester'] is String)
                      LocalText('Jester: ${round['jester']}'),
                    if (points.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final entry in points.entries)
                        if ((entry.value as int) > 0)
                          LocalText('${entry.key}: +${entry.value} pts'),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const LocalText('Close'))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    const heading = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
    final stats = store.stats.entries.toList()
      ..sort((a, b) {
        final byPoints = b.value.points.compareTo(a.value.points);
        return byPoints != 0 ? byPoints : b.value.wins.compareTo(a.value.wins);
      });
    return GamePage(
        title: 'Your party story',
        subtitle: 'Last 200 completed rounds on this device.',
        children: [
          if (store.history.isEmpty) ...[
            const Icon(Icons.history_rounded, size: 80),
            const SizedBox(height: 20),
            const LocalText('No rounds yet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const LocalText('Finish a game to start your story.'),
          ] else ...[
            const LocalText('Leaderboard', style: heading),
            for (final (rank, entry) in stats.indexed)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                      backgroundColor: rank == 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: rank == 0
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      child: rank == 0
                          ? const Icon(Icons.emoji_events, size: 20)
                          : Text(entry.key.isEmpty
                              ? '?'
                              : entry.key.characters.first)),
                  title: Text(entry.key),
                  subtitle: LocalText(
                      '${entry.value.played} rounds • ${entry.value.wins} wins • ${entry.value.imposterRounds} imposter roles'),
                  trailing: LocalText('${entry.value.points} pts',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))),
            const SizedBox(height: 24),
            const LocalText('Completed rounds', style: heading),
            for (final round in store.history)
              Card(
                  child: ListTile(
                leading: Icon(round['citizensWin'] == true
                    ? Icons.verified_outlined
                    : Icons.theater_comedy_outlined),
                title: _word(round, 'word'),
                subtitle: Text(
                    '${translate(context, _outcome(round))}${_modeLabels.containsKey(round['mode']) ? ' • ${translate(context, _modeLabels[round['mode']]!)}' : ''}\n${MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(round['date'] as String).toLocal())} • ${(round['players'] as List).join(', ')}'),
                isThreeLine: true,
                onTap: () => _details(context, round),
              )),
            const SizedBox(height: 20),
            OutlinedButton.icon(
                onPressed: () => _clear(context, store),
                icon: const Icon(Icons.delete_outline),
                label: const LocalText('Clear history')),
          ],
        ]);
  }
}
