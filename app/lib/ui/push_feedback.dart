import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A short settling motion and fading dust; SVG artwork stays unchanged.
class PushFeedback extends StatelessWidget {
  const PushFeedback({
    super.key,
    required this.progress,
    required this.direction,
    required this.onGoal,
    required this.child,
  });
  final Animation<double> progress;
  final Offset direction;
  final bool onGoal;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    child: child,
    builder: (_, sprite) {
      final t = progress.value;
      final settle = math.sin(t * math.pi);
      return CustomPaint(
        foregroundPainter: _PushParticles(t, direction, onGoal),
        child: Transform.rotate(
          angle: math.sin(t * math.pi * 2) * .018,
          child: Transform.scale(scale: 1 + settle * .035, child: sprite),
        ),
      );
    },
  );
}

class _PushParticles extends CustomPainter {
  _PushParticles(this.t, this.direction, this.onGoal);
  final double t;
  final Offset direction;
  final bool onGoal;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final side = Offset(-direction.dy, direction.dx);
    final tail = size.center(Offset.zero) - direction * size.shortestSide * .45;
    final paint = Paint()
      ..color = const Color(0xffeacb80).withValues(alpha: (1 - t) * .45);
    for (var i = 0; i < 4; i++) {
      final spread = (i - 1.5) * (2 + 5 * t);
      final center = tail + side * spread - direction * (2 + t * (6 + i * 2));
      canvas.drawCircle(center, (1.8 - .2 * i) * (1 - t), paint);
    }
    if (onGoal && t > .45) {
      final glow = (t - .45) / .55;
      canvas.drawCircle(
        size.center(Offset.zero),
        size.shortestSide * (.4 + .35 * glow),
        Paint()
          ..color = const Color(0xfff7dfab).withValues(alpha: .65 * (1 - glow))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1 - glow) + .3,
      );
    }
  }

  @override
  bool shouldRepaint(_PushParticles oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.direction != direction ||
      oldDelegate.onGoal != onGoal;
}
