import 'dart:math';

import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/audio/sound_effects.dart';

/// Who won a round, which sets the celebration's colours and sound.
enum RoundTone { group, imposters, jester }

/// Plays the outcome sound once and rains confetti over [child]. The
/// confetti is skipped when the device asks for reduced motion.
class Celebration extends StatefulWidget {
  const Celebration({super.key, required this.tone, required this.child});

  final RoundTone tone;
  final Widget child;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800));
  late final List<_Particle> _particles;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final random = Random();
    final colors = switch (widget.tone) {
      RoundTone.group => const [
          Color(0xFF6C4DFF),
          Color(0xFFFFC233),
          Color(0xFF2EC4B6),
          Color(0xFFFF5D8F),
          Color(0xFF8BE04E),
        ],
      RoundTone.imposters => const [
          Color(0xFF2A1B5C),
          Color(0xFF6C4DFF),
          Color(0xFF9B8CFF),
          Color(0xFFC2F05A),
        ],
      RoundTone.jester => const [
          Color(0xFFFF5D8F),
          Color(0xFFFFC233),
          Color(0xFF2EC4B6),
          Color(0xFF6C4DFF),
        ],
    };
    _particles = List.generate(
      widget.tone == RoundTone.imposters ? 50 : 90,
      (_) => _Particle(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        speed: 0.55 + random.nextDouble() * 0.6,
        sway: (random.nextDouble() - 0.5) * 0.12,
        spin: (random.nextDouble() - 0.5) * 12,
        size: 6 + random.nextDouble() * 7,
        color: colors[random.nextInt(colors.length)],
        round: random.nextBool(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    StoreScope.maybeOf(context)?.playSound(switch (widget.tone) {
      RoundTone.group => Sfx.win,
      RoundTone.imposters => Sfx.imposters,
      RoundTone.jester => Sfx.jester,
    });
    if (!MediaQuery.of(context).disableAnimations) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => _controller.isAnimating
                      ? CustomPaint(
                          painter:
                              _ConfettiPainter(_particles, _controller.value))
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      );
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.sway,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  final double x, delay, speed, sway, spin, size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) {
        continue;
      }
      final dy = -0.1 + t * p.speed * 1.3;
      final dx = p.x + sin(t * 8 + p.x * 10) * p.sway;
      final fade = t > 0.8 ? (1 - t) / 0.2 : 1.0;
      paint.color = p.color.withValues(alpha: fade);
      canvas
        ..save()
        ..translate(dx * size.width, dy * size.height)
        ..rotate(t * p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.5),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

/// Ticks during the last 10 seconds and sounds an alarm with a strong
/// vibration when the discussion timer reaches zero.
class CountdownSounds extends StatefulWidget {
  const CountdownSounds(
      {super.key, required this.remainingSeconds, required this.child});

  final int remainingSeconds;
  final Widget child;

  @override
  State<CountdownSounds> createState() => _CountdownSoundsState();
}

class _CountdownSoundsState extends State<CountdownSounds> {
  @override
  void didUpdateWidget(CountdownSounds old) {
    super.didUpdateWidget(old);
    final now = widget.remainingSeconds;
    if (now == old.remainingSeconds || now > old.remainingSeconds) {
      return;
    }
    final store = StoreScope.maybeOf(context);
    if (now == 0) {
      store?.playSound(Sfx.timeup);
      store?.alert();
    } else if (now <= 10) {
      store?.playSound(Sfx.tick);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
