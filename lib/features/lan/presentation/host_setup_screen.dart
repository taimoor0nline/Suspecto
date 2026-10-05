import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/game/presentation/widgets/game_options_section.dart';
import 'package:suspecto/features/game/presentation/widgets/pack_picker.dart';
import 'package:suspecto/features/lan/application/lan_host_game.dart';
import 'package:suspecto/features/lan/application/lan_session.dart';
import 'package:suspecto/features/lan/data/lan_socket.dart';
import 'package:suspecto/features/lan/presentation/lan_game_screen.dart';
import 'package:suspecto/features/packs/data/word_pack_catalog.dart';
import 'package:suspecto/features/packs/domain/dealable_words.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';
import 'package:suspecto/features/packs/presentation/packs_screen.dart';

/// The host's name and rules; players are whoever joins the lobby.
class HostSetupScreen extends StatefulWidget {
  const HostSetupScreen({super.key});

  @override
  State<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends State<HostSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  Set<String> _packIds = builtInPacks.map((p) => p.id).toSet();
  int _imposters = 1;
  int _minutes = 3;
  GameOptions _options = const GameOptions();
  bool _restored = false;
  bool _starting = false;

  List<WordPack> get _packs => [
        ...builtInPacks,
        ...?StoreScope.maybeOf(context)?.customPacks,
      ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) {
      return;
    }
    _restored = true;
    final store = StoreScope.maybeOf(context);
    if (store == null) {
      return;
    }
    _name.text = store.lanName;
    final available = _packs.map((p) => p.id).toSet();
    final saved = store.lastCategories.where(available.contains).toSet();
    if (saved.isNotEmpty) {
      _packIds = saved;
    }
    _imposters = store.lastImposters.clamp(1, 3);
    _minutes = [1, 3, 5].contains(store.lastMinutes) ? store.lastMinutes : 3;
    _options = store.lastOptions;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _host() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final packs = _packs.where((p) => _packIds.contains(p.id)).toList();
    final deal = dealableWords(packs, _options);
    if (deal.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: LocalText(deal.error!)));
      return;
    }
    final store = StoreScope.maybeOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final unavailable = translate(context, 'Could not start the game.');
    setState(() => _starting = true);
    unawaited(store?.saveLanName(_name.text));
    try {
      final session = await HostSession.start(
        hostName: _name.text,
        config: LanGameConfig(
          imposterCount: _imposters,
          discussionMinutes: _minutes,
          options: _options,
          words: deal.words,
        ),
        onRoundComplete: (result) => unawaited(store?.recordResult(result)),
      );
      if (!mounted) {
        await session.leave();
        return;
      }
      await navigator.push(MaterialPageRoute<void>(
          builder: (_) => LanGameScreen(session: session)));
    } on LanException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: LocalText(e.message)));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(unavailable)));
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GamePage(
      title: 'Host a game',
      subtitle: 'Pick the rules. Friends join from their own phones.',
      children: [
        Form(
          key: _form,
          child: TextFormField(
            controller: _name,
            maxLength: 24,
            decoration: InputDecoration(
              labelText: translate(context, 'Your name'),
              counterText: '',
            ),
            validator: (value) => (value?.trim() ?? '').isEmpty
                ? translate(context, 'Enter a name')
                : null,
          ),
        ),
        const SizedBox(height: 24),
        LocalText('Imposters', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var n = 1; n <= 3; n++)
              ChoiceChip(
                label: LocalText('$n'),
                selected: _imposters == n,
                onSelected: (_) => setState(() => _imposters = n),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const LocalText(
            'Lowered automatically if too few players join (always fewer than half).'),
        const SizedBox(height: 24),
        GameOptionsSection(
          options: _options,
          onChanged: (options) => setState(() => _options = options),
        ),
        const SizedBox(height: 24),
        if (_options.mode != GameMode.questions) ...[
          PackPicker(
            packs: _packs,
            selected: _packIds,
            onChanged: (ids) => setState(() => _packIds = ids),
            onManage: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PacksScreen())),
          ),
          const SizedBox(height: 24),
        ],
        if (!_options.speedRound) ...[
          LocalText('Discussion time', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in [1, 3, 5])
                ChoiceChip(
                  label: LocalText('$n min'),
                  selected: _minutes == n,
                  onSelected: (_) => setState(() => _minutes = n),
                ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _starting ? null : _host,
          icon: _starting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.wifi_tethering),
          label: const LocalText('Open lobby'),
        ),
      ],
    );
  }
}
