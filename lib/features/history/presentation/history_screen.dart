import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  Future<void> _clear(BuildContext context, AppStore store) async {
    final clear = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const LocalText('Clear all history?'), content: const LocalText('This deletes saved rounds and player stats from this device.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const LocalText('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const LocalText('Clear'))]));
    if (clear == true) { await store.clearHistory(); }
  }
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final stats = store.stats.entries.toList()..sort((a, b) => b.value.wins.compareTo(a.value.wins));
    return GamePage(title: 'Your party story', subtitle: 'Last 200 completed rounds on this device.', children: [
      if (store.history.isEmpty) ...[
        const Icon(Icons.history_rounded, size: 80), const SizedBox(height: 20),
        const LocalText('No rounds yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const LocalText('Finish a game to start your story.'),
      ] else ...[
        const LocalText('Player stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        for (final entry in stats) ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text(entry.key.isEmpty ? '?' : entry.key.characters.first)), title: Text(entry.key), subtitle: Text(StoreScope.of(context).language == 'ar' ? '${entry.value.played} جولات • ${entry.value.imposterRounds} أدوار مخادع' : '${entry.value.played} rounds • ${entry.value.imposterRounds} imposter roles'), trailing: Text(StoreScope.of(context).language == 'ar' ? '${entry.value.wins} فوز' : '${entry.value.wins} wins')),
        const SizedBox(height: 24),
        const LocalText('Completed rounds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        for (final round in store.history) Card(child: ListTile(
          leading: Icon(round['citizensWin'] == true ? Icons.verified_outlined : Icons.theater_comedy_outlined),
          title: LocalText(round['word'] as String),
          subtitle: Text('${translate(context, round['citizensWin'] == true ? 'Citizens won' : 'Imposters won')}\n${MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(round['date'] as String).toLocal())} • ${(round['players'] as List).join(', ')}'),
          isThreeLine: true,
          onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(title: LocalText(round['word'] as String), content: LocalText('Imposters: ${(round['imposters'] as List).join(', ')}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const LocalText('Close'))])),
        )),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: () => _clear(context, store), icon: const Icon(Icons.delete_outline), label: const LocalText('Clear history')),
      ],
    ]);
  }
}
