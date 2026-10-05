import 'package:flutter/material.dart';
import 'package:suspecto/features/packs/presentation/pack_qr_dialog.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';

/// Creates a custom pack, or edits/deletes [pack] when given.
class PackEditorScreen extends StatefulWidget {
  const PackEditorScreen({super.key, this.pack});
  final WordPack? pack;

  @override
  State<PackEditorScreen> createState() => _PackEditorScreenState();
}

class _PackEditorScreenState extends State<PackEditorScreen> {
  late final _name = TextEditingController(text: widget.pack?.name);
  late final _words =
      TextEditingController(text: widget.pack?.words.join('\n'));
  String? _error;

  @override
  void initState() {
    super.initState();
    _words.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _words.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = StoreScope.of(context);
    final words = WordPack.parseWords(_words.text);
    final error = WordPack.validate(
      name: _name.text,
      words: words,
      otherNames: store.customPacks
          .where((p) => p.id != widget.pack?.id)
          .map((p) => p.name),
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await store.savePack(WordPack.custom(
      id: widget.pack?.id ?? WordPack.newCustomId(),
      name: _name.text,
      words: words,
    ));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final store = StoreScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalText('Delete this pack?'),
        content: const LocalText('Its words will be removed from this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const LocalText('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const LocalText('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await store.deletePack(widget.pack!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = WordPack.parseWords(_words.text).length;
    return GamePage(
      title: widget.pack == null ? 'New word pack' : 'Edit word pack',
      subtitle: 'Add at least 3 words. Put each word on its own line.',
      children: [
        TextField(
          controller: _name,
          maxLength: WordPack.maxNameLength,
          textInputAction: TextInputAction.next,
          decoration:
              InputDecoration(labelText: translate(context, 'Pack name')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _words,
          minLines: 8,
          maxLines: 16,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: translate(context, 'Words'),
            alignLabelWithHint: true,
            helperText: translate(context, '$count words'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          LocalText(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const LocalText('Save pack'),
        ),
        if (widget.pack != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showPackQr(context, widget.pack!),
            icon: const Icon(Icons.qr_code_2),
            label: const LocalText('Share by QR code'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
            label: const LocalText('Delete pack'),
          ),
        ],
      ],
    );
  }
}
