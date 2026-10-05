import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/packs/data/word_pack_catalog.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';

/// Chips for choosing built-in and custom word packs.
class PackPicker extends StatelessWidget {
  const PackPicker({
    super.key,
    required this.packs,
    required this.selected,
    required this.onChanged,
    required this.onManage,
  });

  final List<WordPack> packs;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = packs.where((p) => p.custom).toList();
    Widget chip(WordPack pack) => FilterChip(
          avatar: pack.custom
              ? const Icon(Icons.edit_note, size: 18)
              : (packEmoji[pack.id] == null ? null : Text(packEmoji[pack.id]!)),
          label: pack.custom
              ? Text(pack.name)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalText(pack.name),
                    if (newPackIds.contains(pack.id)) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: LocalText('New',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onTertiary,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
          selected: selected.contains(pack.id),
          onSelected: (value) => onChanged(value
              ? {...selected, pack.id}
              : selected.where((id) => id != pack.id).toSet()),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child:
                    LocalText('Word packs', style: theme.textTheme.titleLarge)),
            TextButton(
              onPressed: () => onChanged(packs.map((p) => p.id).toSet()),
              child: const LocalText('All'),
            ),
            TextButton(
              onPressed: () => onChanged({}),
              child: const LocalText('None'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pack in packs.where((p) => !p.custom)) chip(pack)
          ],
        ),
        if (custom.isNotEmpty) ...[
          const SizedBox(height: 12),
          LocalText('Your packs', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final pack in custom) chip(pack)]),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onManage,
          icon: const Icon(Icons.library_add_outlined),
          label: const LocalText('Create & edit your packs'),
        ),
      ],
    );
  }
}
