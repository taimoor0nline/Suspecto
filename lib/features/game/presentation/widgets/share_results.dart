import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/services/party_awards.dart';
import 'package:suspecto/features/game/presentation/widgets/party_awards_card.dart';

/// Everything the shareable image shows, already translated for this phone.
class ResultSummary {
  const ResultSummary({
    required this.title,
    required this.secretLabel,
    required this.secret,
    required this.imposters,
    this.awards = const [],
    this.standings = const [],
  });

  final String title;
  final String secretLabel;
  final String secret;
  final String imposters;

  /// (emoji, title, player name, detail).
  final List<(String, String, String, String)> awards;

  /// (player name, points), best first.
  final List<(String, int)> standings;

  static ResultSummary build(
    BuildContext context, {
    required String title,
    required String secretLabel,
    required String secret,
    required String imposters,
    required List<PartyAward> awards,
    required String Function(String id) nameOf,
    required List<(String, int)> standings,
  }) =>
      ResultSummary(
        title: translate(context, title),
        secretLabel: translate(context, secretLabel),
        secret: secret,
        imposters: translate(context, imposters),
        awards: [
          for (final award in awards)
            switch (awardLabel(award)) {
              (final emoji, final label, final detail) => (
                  emoji,
                  translate(context, label),
                  nameOf(award.playerId),
                  translate(context, detail),
                ),
            },
        ],
        standings: standings.take(3).toList(),
      );
}

/// Opens a preview of the results image with a Share button.
class ShareResultsButton extends StatelessWidget {
  const ShareResultsButton({super.key, required this.summary});
  final ResultSummary Function(BuildContext context) summary;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _SharePreview(summary: summary(context)),
        ),
        icon: const Icon(Icons.ios_share_rounded),
        label: const LocalText('Share results'),
      );
}

class _SharePreview extends StatefulWidget {
  const _SharePreview({required this.summary});
  final ResultSummary summary;

  @override
  State<_SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<_SharePreview> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final caption = translate(context, 'Played Suspecto, the party word game.');
    try {
      final render = _boundary.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await SharePlus.instance.share(ShareParams(
        text: caption,
        files: [
          XFile.fromData(bytes!.buffer.asUint8List(), mimeType: 'image/png'),
        ],
        fileNameOverrides: const ['suspecto-results.png'],
        sharePositionOrigin: origin,
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            content: LocalText('Sharing is not available on this device.')));
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: RepaintBoundary(
                  key: _boundary,
                  child: ResultShareCard(summary: widget.summary),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: const Icon(Icons.ios_share_rounded),
                label: const LocalText('Share'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const LocalText('Close'),
              ),
            ],
          ),
        ),
      );
}

/// The branded results image. Fixed size so shared images look the same on
/// every phone.
class ResultShareCard extends StatelessWidget {
  const ResultShareCard({super.key, required this.summary});
  final ResultSummary summary;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final muted = Colors.white.withValues(alpha: 0.75);
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1B5C), Color(0xFF6C4DFF)],
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: white, fontSize: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/branding/suspecto-icon.png',
                      width: 32, height: 32),
                ),
                const SizedBox(width: 10),
                const Text('SUSPECTO',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 20),
            Text(summary.title,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text(summary.secretLabel,
                style: TextStyle(color: muted, letterSpacing: 1)),
            Text(summary.secret,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(summary.imposters, style: TextStyle(color: muted)),
            if (summary.awards.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final (emoji, title, name, detail) in summary.awards)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '$emoji  '),
                    TextSpan(
                        text: '$title: ',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: name),
                    TextSpan(
                        text: '  ·  $detail', style: TextStyle(color: muted)),
                  ])),
                ),
            ],
            if (summary.standings.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final (i, (name, points)) in summary.standings.indexed)
                Row(
                  children: [
                    Text(['🥇', '🥈', '🥉'][i]),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(name, overflow: TextOverflow.ellipsis)),
                    Text('$points',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
