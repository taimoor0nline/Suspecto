import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/audio/sound_effects.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/presentation/widgets/drawing_canvas.dart';
import 'package:suspecto/features/game/presentation/widgets/round_widgets.dart';
import 'package:suspecto/features/game/presentation/widgets/secret_card.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';
import 'package:suspecto/features/lan/application/lan_host_game.dart';
import 'package:suspecto/features/lan/application/lan_session.dart';
import 'package:suspecto/features/lan/domain/lan_view.dart';
import 'package:suspecto/features/lan/presentation/widgets/lan_widgets.dart';

/// Common inputs for the in-round views.
abstract class LanRoundView extends StatelessWidget {
  const LanRoundView({super.key, required this.session, required this.onLeave});
  final LanSession session;
  final VoidCallback onLeave;

  LanView get view => session.view!;
  bool get reconnecting => session.status == LanStatus.reconnecting;

  String progress(LanView view) {
    final players = view.roundPlayers;
    return '${players.where((p) => p.done).length} of ${players.length} ready';
  }
}

/// Everyone looks at their own card at the same time.
class LanRevealView extends LanRoundView {
  const LanRevealView({
    super.key,
    required super.session,
    required super.onLeave,
    required this.cardVisible,
    required this.onHold,
  });

  final bool cardVisible;
  final ValueChanged<bool> onHold;

  @override
  Widget build(BuildContext context) {
    final view = this.view;
    final card = view.card!;
    final seen = view.me?.done ?? false;
    return LanPage(
      view: view,
      onLeave: onLeave,
      reconnecting: reconnecting,
      title: 'Your secret card',
      subtitle: 'Make sure nobody can see your screen.',
      children: [
        SecretCard(
          ownerName: view.me?.name,
          visible: cardVisible,
          onHold: (show) {
            if (show && !cardVisible) {
              StoreScope.maybeOf(context)?.feedback(reveal: true);
            }
            onHold(show);
          },
          word: card.word?.entry,
          hint: card.hint?.entry,
          question: view.mode == GameMode.questions,
          jester: card.jester,
          accompliceOf: card.accompliceOf?.map(view.nameOf).join(', '),
          clearedName:
              card.clearedId == null ? null : view.nameOf(card.clearedId!),
        ),
        const SizedBox(height: 24),
        if (!seen)
          FilledButton(
            onPressed: () {
              StoreScope.maybeOf(context)?.feedback();
              session.send(LanAction.seen);
            },
            child: const LocalText("I've seen my card"),
          )
        else
          WaitingNote(progress(view)),
        if (view.isHost) ...[
          const SizedBox(height: 8),
          LanPlayerList(
              view: view, players: view.roundPlayers, showProgress: true),
          TextButton(
            onPressed: () => session.send(LanAction.discuss),
            child: const LocalText('Start discussion now'),
          ),
        ],
      ],
    );
  }
}

class LanDiscussionView extends LanRoundView {
  const LanDiscussionView(
      {super.key, required super.session, required super.onLeave});

  @override
  Widget build(BuildContext context) {
    final view = this.view;
    final questions = view.mode == GameMode.questions;
    final starter = view.nameOf(view.starterId ?? '');
    return LanPage(
      view: view,
      onLeave: onLeave,
      reconnecting: reconnecting,
      title: questions ? 'Answer time' : 'Let the bluffing begin',
      subtitle: questions
          ? '$starter answers first. Everyone answers their question out loud, then discuss whose answer did not fit.'
          : view.strokes.isNotEmpty
              ? 'Look at the drawing together. Whose lines look like a bluff? Keep the word secret.'
              : '$starter starts. Give one clue each, then discuss who is bluffing. Keep the word secret.',
      children: [
        DiscussionTimerCard(
            remainingSeconds: view.remainingSeconds,
            mode: view.mode,
            speedRound: view.speedRound),
        if (view.strokes.isNotEmpty) ...[
          const SizedBox(height: 16),
          DrawingCanvas(players: lanPlayers(view), strokes: view.strokes),
        ],
        if (questions) ...[
          const SizedBox(height: 16),
          QuestionRevealCard(
            question: view.revealedQuestion?.entry,
            onReveal: view.isHost
                ? () => session.send(LanAction.revealQuestion)
                : null,
          ),
        ],
        const SizedBox(height: 24),
        if (view.isHost) ...[
          FilledButton(
            onPressed: () => session.send(LanAction.startVote),
            child: const LocalText('Start voting on every phone'),
          ),
          TextButton.icon(
            onPressed: () => session.send(LanAction.addTime),
            icon: const Icon(Icons.more_time),
            label: const LocalText('Add 1 minute'),
          ),
        ] else
          const WaitingNote('The host will start the vote.'),
      ],
    );
  }
}

/// Everyone votes on their own phone at the same time.
class LanVoteView extends StatefulWidget {
  const LanVoteView({super.key, required this.session, required this.onLeave});
  final LanSession session;
  final VoidCallback onLeave;

  @override
  State<LanVoteView> createState() => _LanVoteViewState();
}

class _LanVoteViewState extends State<LanVoteView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final view = session.view!;
    final voted = view.myVote != null;
    final players = view.roundPlayers;
    return LanPage(
      view: view,
      onLeave: widget.onLeave,
      reconnecting: session.status == LanStatus.reconnecting,
      title: voted ? 'Vote locked in' : 'Who is the imposter?',
      subtitle: voted
          ? 'Waiting for everyone else to vote.'
          : 'Choose your suspect. Your vote stays private.',
      children: voted
          ? [
              WaitingNote(
                  '${players.where((p) => p.done).length} of ${players.length} ready'),
              LanPlayerList(view: view, players: players, showProgress: true),
            ]
          : [
              for (final candidate in players.where((p) => p.id != view.you))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _selected = candidate.id),
                    icon: Icon(_selected == candidate.id
                        ? Icons.check_circle
                        : Icons.person_outline),
                    label: Text(candidate.name),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _selected == null
                    ? null
                    : () {
                        StoreScope.maybeOf(context)?.feedback(sound: Sfx.vote);
                        session.send(LanAction.vote, {'suspect': _selected});
                      },
                child: const LocalText('Submit private vote'),
              ),
            ],
    );
  }
}

class LanTieView extends LanRoundView {
  const LanTieView({super.key, required super.session, required super.onLeave});

  @override
  Widget build(BuildContext context) => LanPage(
        view: view,
        onLeave: onLeave,
        reconnecting: reconnecting,
        title: 'Too close to call',
        subtitle:
            'The vote is tied at the cutoff. Discuss again, then everyone votes again. Roles stay secret.',
        children: [
          const Icon(Icons.balance, size: 88),
          const SizedBox(height: 24),
          if (view.isHost)
            FilledButton(
              onPressed: () => session.send(LanAction.startVote),
              child: const LocalText('Vote again'),
            )
          else
            const WaitingNote('The host will start the vote.'),
        ],
      );
}

class LanGuessView extends StatefulWidget {
  const LanGuessView({super.key, required this.session, required this.onLeave});
  final LanSession session;
  final VoidCallback onLeave;

  @override
  State<LanGuessView> createState() => _LanGuessViewState();
}

class _LanGuessViewState extends State<LanGuessView> {
  int? _guess;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final view = session.view!;
    final names = view.guesserIds.map(view.nameOf).join(', ');
    return LanPage(
      view: view,
      onLeave: widget.onLeave,
      reconnecting: session.status == LanStatus.reconnecting,
      title: 'Last chance!',
      subtitle: 'Caught: $names. Guess the secret word to steal the win.',
      children: [
        const Icon(Icons.psychology_alt_outlined, size: 72),
        const SizedBox(height: 16),
        if (view.canGuess) ...[
          for (final (i, option) in view.guessOptions.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _guess = i),
                icon: Icon(_guess == i
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked),
                label: WordText(option.entry),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _guess == null
                ? null
                : () {
                    StoreScope.maybeOf(context)?.feedback(reveal: true);
                    session.send(LanAction.guess, {'index': _guess});
                  },
            child: const LocalText('Lock in guess'),
          ),
        ] else
          const WaitingNote('The imposters are guessing the word…'),
      ],
    );
  }
}

/// Shown to players who joined while a round was already being played.
class LanSitOutView extends LanRoundView {
  const LanSitOutView(
      {super.key, required super.session, required super.onLeave});

  @override
  Widget build(BuildContext context) => LanPage(
        view: view,
        onLeave: onLeave,
        reconnecting: reconnecting,
        title: 'Sit this one out',
        subtitle: "A round is in progress. You'll be dealt in next round.",
        children: [
          const Icon(Icons.event_seat_outlined, size: 88),
          const SizedBox(height: 16),
          LanPlayerList(view: view),
        ],
      );
}

/// Round players as game [Player]s, for shared widgets such as the canvas.
List<Player> lanPlayers(LanView view) => [
      for (final p in view.players) Player(id: p.id, name: p.name),
    ];

/// Drawing round: the drawer sketches one line on their own phone and sends
/// it when done; everyone else watches the drawing grow.
class LanDrawingView extends StatefulWidget {
  const LanDrawingView(
      {super.key, required this.session, required this.onLeave});
  final LanSession session;
  final VoidCallback onLeave;

  @override
  State<LanDrawingView> createState() => _LanDrawingViewState();
}

class _LanDrawingViewState extends State<LanDrawingView> {
  List<Offset>? _pen;
  List<Offset>? _line;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final view = session.view!;
    final mine = view.myTurnToDraw && !_sent;
    final drawer = view.player(view.drawerId);
    final me = Player(id: view.you, name: view.me?.name ?? '');
    final drawing = _pen ?? _line;
    return LanPage(
      view: view,
      onLeave: widget.onLeave,
      reconnecting: session.status == LanStatus.reconnecting,
      title: mine ? 'Your turn to draw' : '${drawer?.name ?? '?'} is drawing',
      subtitle:
          'Line ${view.drawTurn + 1} of ${view.drawTurns}. Add one line to the drawing. No letters or numbers!',
      children: [
        DrawingCanvas(
          players: lanPlayers(view),
          strokes: view.strokes,
          pen: mine ? drawing : null,
          penPlayer: me,
          onPenDown:
              mine && _line == null ? (p) => setState(() => _pen = [p]) : null,
          onPenMove: (p) => setState(() =>
              _pen?.add(Offset(p.dx.clamp(0.0, 1.0), p.dy.clamp(0.0, 1.0)))),
          onPenUp: () => setState(() {
            _line = _pen;
            _pen = null;
          }),
        ),
        const SizedBox(height: 12),
        if (mine) ...[
          TextButton.icon(
            onPressed:
                _line == null ? null : () => setState(() => _line = null),
            icon: const Icon(Icons.undo),
            label: const LocalText('Redo my line'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _line == null
                ? null
                : () {
                    StoreScope.maybeOf(context)?.feedback();
                    session.send(LanAction.draw, {'xy': encodePoints(_line!)});
                    setState(() => _sent = true);
                  },
            child: const LocalText('Done'),
          ),
        ] else
          WaitingNote(view.myTurnToDraw
              ? 'Sending your line…'
              : 'Watch the drawing. Your turn is coming.'),
        if (view.isHost && !view.myTurnToDraw)
          TextButton(
            onPressed: () => session.send(LanAction.skipDraw),
            child: const LocalText('Skip this turn'),
          ),
      ],
    );
  }
}
