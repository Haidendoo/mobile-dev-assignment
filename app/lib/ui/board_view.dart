import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../domain/puzzle.dart';
import 'forest_theme.dart';

class BoardView extends StatelessWidget {
  const BoardView({super.key, required this.level, required this.board});
  final Level level;
  final Board board;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${level.name}. Player at column ${board.player.x + 1}, '
        'row ${board.player.y + 1}. '
        '${board.crates.where(level.goals.contains).length} of '
        '${level.goals.length} altars restored.',
    child: Center(
      child: AspectRatio(
        aspectRatio: level.width / level.height,
        child: CustomPaint(painter: BoardPainter(level, board)),
      ),
    ),
  );
}

class BoardPainter extends CustomPainter {
  BoardPainter(this.level, this.board);
  final Level level;
  final Board board;
  @override
  void paint(Canvas canvas, Size size) {
    final cell = math.min(size.width / level.width, size.height / level.height);
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final p = Cell(x, y);
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell).deflate(1);
        final wall = level.walls.contains(p);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * .08)),
          Paint()
            ..color = wall
                ? const Color(0xFF506F64)
                : ((x + y).isEven
                      ? const Color(0xFF6C8561)
                      : const Color(0xFF667E5B)),
        );
        if (wall) {
          canvas.drawRect(
            Rect.fromLTWH(
              rect.left + 2,
              rect.top + 2,
              rect.width - 4,
              cell * .14,
            ),
            Paint()..color = const Color(0xFF9BAE8C),
          );
          canvas.drawLine(
            Offset(rect.left + cell * .5, rect.top + cell * .3),
            Offset(rect.left + cell * .5, rect.bottom - 2),
            Paint()
              ..color = const Color(0xFF3D584F)
              ..strokeWidth = 2,
          );
        } else if (level.goals.contains(p)) {
          final c = rect.center;
          canvas.drawCircle(
            c,
            cell * .35,
            Paint()..color = const Color(0x55FFE597),
          );
          final diamond = Path()
            ..moveTo(c.dx, c.dy - cell * .25)
            ..lineTo(c.dx + cell * .25, c.dy)
            ..lineTo(c.dx, c.dy + cell * .25)
            ..lineTo(c.dx - cell * .25, c.dy)
            ..close();
          canvas.drawPath(diamond, Paint()..color = gold);
          canvas.drawCircle(c, cell * .08, Paint()..color = forest);
        }
      }
    }
    for (final crate in board.crates) {
      final onGoal = level.goals.contains(crate);
      final rect = Rect.fromLTWH(
        crate.x * cell,
        crate.y * cell,
        cell,
        cell,
      ).deflate(cell * .13);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * .08)),
        Paint()
          ..color = onGoal ? const Color(0xFFBFE29A) : const Color(0xFFA47B45),
      );
      final border = Paint()
        ..color = const Color(0xFF4B3A27)
        ..strokeWidth = cell * .065
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * .08)),
        border,
      );
      canvas.drawLine(
        Offset(rect.left + cell * .1, rect.center.dy),
        Offset(rect.right - cell * .1, rect.center.dy),
        border,
      );
      if (onGoal) {
        final check = Path()
          ..moveTo(rect.center.dx - cell * .15, rect.center.dy)
          ..lineTo(rect.center.dx - cell * .03, rect.center.dy + cell * .12)
          ..lineTo(rect.center.dx + cell * .18, rect.center.dy - cell * .15);
        canvas.drawPath(
          check,
          Paint()
            ..color = forest
            ..strokeWidth = cell * .07
            ..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawCircle(rect.center, cell * .08, Paint()..color = gold);
      }
    }
    final center = Offset(
      (board.player.x + .5) * cell,
      (board.player.y + .5) * cell,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, cell * .23),
        width: cell * .55,
        height: cell * .18,
      ),
      Paint()..color = const Color(0x44302721),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, cell * .1),
          width: cell * .4,
          height: cell * .42,
        ),
        Radius.circular(cell * .12),
      ),
      Paint()..color = const Color(0xFF244E36),
    );
    canvas.drawCircle(
      center.translate(0, -cell * .1),
      cell * .24,
      Paint()..color = const Color(0xFF285E3C),
    );
    canvas.drawCircle(
      center.translate(0, -cell * .08),
      cell * .17,
      Paint()..color = cream,
    );
    for (final dx in [-.065, .065]) {
      canvas.drawCircle(
        center.translate(cell * dx, -cell * .1),
        cell * .025,
        Paint()..color = forest,
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      oldDelegate.board != board || oldDelegate.level != level;
}
