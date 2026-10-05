import 'dart:math';

import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/lan/application/lan_host_game.dart';
import 'package:suspecto/features/lan/application/lan_session.dart';
import 'package:suspecto/features/lan/domain/lan_view.dart';

/// Gives multi-phone pages the session to send reactions with.
class ReactionScope extends InheritedWidget {
  const ReactionScope({super.key, required this.session, required super.child});
  final LanSession session;

  static LanSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReactionScope>()?.session;

  @override
  bool updateShouldNotify(ReactionScope old) => old.session != session;
}

/// One-tap emoji reactions that pop up on every phone.
class ReactionBar extends StatelessWidget {
  const ReactionBar({super.key, required this.session});
  final LanSession session;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final (i, emoji) in lanReactionEmoji.indexed)
            IconButton(
              tooltip: translate(context, 'React'),
              onPressed: () {
                StoreScope.maybeOf(context)?.feedback();
                session.send(LanAction.react, {'e': i});
              },
              icon: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
        ],
      );
}

/// Floats each new reaction up the screen with the sender's name, then
/// fades it out. Reactions already in the first view are not replayed.
class ReactionOverlay extends StatefulWidget {
  const ReactionOverlay({super.key, required this.session});
  final LanSession session;

  @override
  State<ReactionOverlay> createState() => _ReactionOverlayState();
}

class _Bubble {
  _Bubble(this.reaction, this.name, this.x, this.key);
  final LanReaction reaction;
  final String name;

  /// Horizontal position, 0–1.
  final double x;
  final Key key;
}

class _ReactionOverlayState extends State<ReactionOverlay> {
  static const _life = Duration(milliseconds: 2400);
  static const _maxBubbles = 8;
  final _random = Random();
  final List<_Bubble> _bubbles = [];
  int? _lastSeq;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onChange);
    _lastSeq = _maxSeq(widget.session.view);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onChange);
    super.dispose();
  }

  static int? _maxSeq(LanView? view) => view == null || view.reactions.isEmpty
      ? null
      : view.reactions.map((r) => r.seq).reduce(max);

  void _onChange() {
    final view = widget.session.view;
    if (view == null) {
      return;
    }
    final fresh = [
      for (final r in view.reactions)
        if (_lastSeq == null || r.seq > _lastSeq!) r,
    ];
    if (fresh.isEmpty) {
      return;
    }
    _lastSeq = _maxSeq(view);
    setState(() {
      for (final r in fresh) {
        final bubble = _Bubble(r, view.nameOf(r.playerId),
            0.1 + _random.nextDouble() * 0.8, UniqueKey());
        _bubbles.add(bubble);
        Future.delayed(_life, () {
          if (mounted) {
            setState(() => _bubbles.remove(bubble));
          }
        });
      }
      while (_bubbles.length > _maxBubbles) {
        _bubbles.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final theme = Theme.of(context);
    // Above the page's Scaffold, so it brings its own text styling.
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              for (final b in _bubbles)
                TweenAnimationBuilder<double>(
                  key: b.key,
                  tween: Tween(begin: 0, end: 1),
                  duration: _life,
                  builder: (context, t, child) => Positioned(
                    left: b.x * (box.maxWidth - 72),
                    bottom:
                        96 + (reduceMotion ? 0.3 : t) * box.maxHeight * 0.45,
                    child: Opacity(
                      opacity: t < 0.7 ? 1 : (1 - t) / 0.3,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(blurRadius: 8, color: Color(0x33000000)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lanReactionEmoji[b.reaction.emoji],
                            style: const TextStyle(fontSize: 36)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            b.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
