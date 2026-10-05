import 'package:flutter/material.dart';
import 'package:suspecto/features/packs/domain/pack_code.dart';
import 'package:suspecto/core/widgets/scan_code_screen.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';
import 'package:suspecto/features/packs/presentation/pack_editor_screen.dart';

/// Lists the player's custom packs and opens the editor.
class PacksScreen extends StatelessWidget {
  const PacksScreen({super.key});

  void _open(BuildContext context, [WordPack? pack]) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PackEditorScreen(pack: pack)));

  /// Imports a pack shown as a QR code on another phone.
  Future<void> _scan(BuildContext context) async {
    final store = StoreScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final added = translate(context, 'Pack added');
    final scanned = await Navigator.of(context).push(
      MaterialPageRoute<({String name, List<String> words})>(
        builder: (_) =>
            const ScanCodeScreen<({String name, List<String> words})>(
          parse: PackCode.decode,
          hint: "Point the camera at the pack's QR code.",
        ),
      ),
    );
    if (scanned == null) {
      return;
    }
    final name =
        PackCode.uniqueName(scanned.name, store.customPacks.map((p) => p.name));
    await store.savePack(WordPack.custom(
        id: WordPack.newCustomId(), name: name, words: scanned.words));
    messenger.showSnackBar(SnackBar(content: Text('$added: $name')));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final packs = store.customPacks;
    final full = packs.length >= WordPack.maxCustomPacks;
    return GamePage(
      title: 'Your word packs',
      subtitle:
          'Make packs with inside jokes, family names or any theme. They stay on this device.',
      children: [
        if (packs.isEmpty) ...[
          const Icon(Icons.library_books_outlined, size: 80),
          const SizedBox(height: 16),
          LocalText('No custom packs yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const LocalText('Create one and pick it when you set up a game.',
              textAlign: TextAlign.center),
        ] else
          for (final pack in packs)
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(pack.name),
                subtitle: LocalText('${pack.entries.length} words'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, pack),
              ),
            ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: full ? null : () => _open(context),
          icon: const Icon(Icons.add),
          label: const LocalText('Create pack'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: full ? null : () => _scan(context),
          icon: const Icon(Icons.qr_code_scanner),
          label: const LocalText('Scan a pack'),
        ),
        if (full) ...[
          const SizedBox(height: 8),
          const LocalText('You can keep up to 50 custom packs.',
              textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
