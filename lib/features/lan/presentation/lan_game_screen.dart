import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/lan/application/lan_session.dart';
import 'package:suspecto/features/lan/domain/lan_view.dart';
import 'package:suspecto/features/lan/presentation/views/lobby_view.dart';
import 'package:suspecto/features/lan/presentation/views/result_view.dart';
import 'package:suspecto/features/lan/presentation/views/round_views.dart';
import 'package:suspecto/features/lan/presentation/widgets/reactions.dart';

/// Shows a multi-phone game on this phone, host or guest. Owns [session] and
/// leaves the game when closed.
class LanGameScreen extends StatefulWidget {
  const LanGameScreen({super.key, required this.session});
  final LanSession session;

  @override
  State<LanGameScreen> createState() => _LanGameScreenState();
}

class _LanGameScreenState extends State<LanGameScreen>
    with WidgetsBindingObserver {
  bool _cardVisible = false;
  String _step = '';

  LanSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_onChange);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _cardVisible) {
      setState(() => _cardVisible = false);
    }
  }

  void _onChange() {
    final view = _session.view;
    final step = '${view?.phase.name}-${view?.round}';
    if (step != _step) {
      _step = step;
      _cardVisible = false;
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onChange);
    unawaited(_session.leave().whenComplete(_session.dispose));
    super.dispose();
  }

  Future<void> _leave() async {
    setState(() => _cardVisible = false);
    final host = _session.view?.isHost ?? false;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            LocalText(host ? 'End the game for everyone?' : 'Leave this game?'),
        content: LocalText(host
            ? 'Every phone will be disconnected.'
            : 'You can rejoin with the same name and code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalText('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: LocalText(host ? 'End game' : 'Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final view = session.view;
    if (session.status == LanStatus.closed) {
      return GamePage(
        title: 'Game over',
        subtitle: session.closedReason ?? 'The host ended the game.',
        children: [
          const Icon(Icons.wifi_off_rounded, size: 88),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const LocalText('Back'),
          ),
        ],
      );
    }
    if (view == null) {
      return GamePage(
        title: 'Joining game…',
        subtitle: 'Stay on the same Wi-Fi or hotspot as the host.',
        children: [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const LocalText('Cancel'),
          ),
        ],
      );
    }
    final inRound = view.me?.inRound ?? false;
    return ReactionScope(
      session: session,
      child: Stack(
        children: [
          _phaseView(view, inRound),
          Positioned.fill(child: ReactionOverlay(session: session)),
        ],
      ),
    );
  }

  Widget _phaseView(LanView view, bool inRound) {
    final session = _session;
    return switch (view.phase) {
      LanPhase.lobby => LobbyView(session: session, onLeave: _leave),
      LanPhase.result => LanResultView(session: session, onLeave: _leave),
      _ when !inRound => LanSitOutView(session: session, onLeave: _leave),
      LanPhase.reveal => LanRevealView(
          session: session,
          onLeave: _leave,
          cardVisible: _cardVisible,
          onHold: (show) => setState(() => _cardVisible = show),
        ),
      LanPhase.drawing => LanDrawingView(
          key: ValueKey('draw-${view.round}-${view.drawTurn}'),
          session: session,
          onLeave: _leave),
      LanPhase.discussion =>
        LanDiscussionView(session: session, onLeave: _leave),
      LanPhase.vote => LanVoteView(
          key: ValueKey('vote-${view.round}-${view.myVote}'),
          session: session,
          onLeave: _leave),
      LanPhase.tie => LanTieView(session: session, onLeave: _leave),
      LanPhase.guess => LanGuessView(
          key: ValueKey('guess-${view.round}'),
          session: session,
          onLeave: _leave),
    };
  }
}
