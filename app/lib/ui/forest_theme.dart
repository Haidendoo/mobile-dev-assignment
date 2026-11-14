import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

const forest = Color(0xFF173C32);
const pine = Color(0xFF244C3E);
const cream = Color(0xFFFFF2CC);
const gold = Color(0xFFE7C477);

ThemeData forestTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: gold,
    brightness: Brightness.dark,
    surface: forest,
  ),
  scaffoldBackgroundColor: forest,
  textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: cream,
    displayColor: cream,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF705735),
      foregroundColor: cream,
      disabledBackgroundColor: const Color(0xFF33473A),
      disabledForegroundColor: const Color(0xFFB2B8A9),
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      side: const BorderSide(color: gold, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: cream,
      minimumSize: const Size(48, 48),
    ),
  ),
);

class ForestBackdrop extends StatelessWidget {
  const ForestBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF315C43), Color(0xFF102A28)],
      ),
    ),
    child: CustomPaint(painter: _ForestPainter(), child: child),
  );
}

class _ForestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(41);
    for (var i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 18 + random.nextDouble() * 35;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = i.isEven
              ? const Color(0x332C7551)
              : const Color(0x33122825),
      );
    }
    for (var i = 0; i < 24; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        1.5,
        Paint()..color = const Color(0x6688D9A0),
      );
    }
  }

  @override
  bool shouldRepaint(_ForestPainter oldDelegate) => false;
}

class ForestPanel extends StatelessWidget {
  const ForestPanel({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: const Color(0xF0183029),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: gold, width: 1.5),
    ),
    child: child,
  );
}
