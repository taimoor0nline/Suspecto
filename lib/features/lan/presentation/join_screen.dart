import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suspecto/features/lan/domain/room_code.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/core/widgets/scan_code_screen.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/lan/application/lan_session.dart';
import 'package:suspecto/features/lan/domain/join_code.dart';
import 'package:suspecto/features/lan/presentation/lan_game_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, this.online = false});

  /// Join an online room by room code instead of a Wi-Fi join code.
  final bool online;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _restored = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_restored) {
      _restored = true;
      _name.text = StoreScope.maybeOf(context)?.lanName ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  /// A [RoomCode] online, otherwise a Wi-Fi [JoinCode].
  Object? _parse(String text) =>
      widget.online ? RoomCode.parse(text) : JoinCode.parse(text);

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<Object>(MaterialPageRoute(
      builder: (_) => ScanCodeScreen<Object>(
        parse: _parse,
        hint: "Point the camera at the QR code on the host's phone.",
      ),
    ));
    if (code != null && mounted) {
      _code.text = switch (code) {
        JoinCode(:final code) => code,
        RoomCode(:final code) => code,
        _ => '',
      };
      if (_name.text.trim().isNotEmpty) {
        _join();
      }
    }
  }

  void _join() {
    if (!_form.currentState!.validate()) {
      return;
    }
    final store = StoreScope.maybeOf(context);
    unawaited(store?.saveLanName(_name.text));
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LanGameScreen(
        session: switch (_parse(_code.text)) {
          final RoomCode room =>
            ClientSession.online(name: _name.text.trim(), room: room),
          final code => ClientSession.wifi(
              name: _name.text.trim(), code: code! as JoinCode),
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => GamePage(
        title: widget.online ? 'Join an online game' : 'Join a game',
        subtitle: widget.online
            ? "Type or scan the room code on the host's phone. Works from anywhere with internet."
            : 'Connect to the same Wi-Fi as the host, or to their hotspot, then scan their QR code.',
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 24,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: translate(context, 'Your name'),
                    counterText: '',
                  ),
                  validator: (value) => (value?.trim() ?? '').isEmpty
                      ? translate(context, 'Enter a name')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: translate(
                        context, widget.online ? 'Room code' : 'Join code'),
                  ),
                  validator: (value) => _parse(value ?? '') == null
                      ? translate(context, 'Check the code on the host phone.')
                      : null,
                  onFieldSubmitted: (_) => _join(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const LocalText('Scan QR code'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _join,
            icon: const Icon(Icons.login_rounded),
            label: const LocalText('Join with code'),
          ),
        ],
      );
}
