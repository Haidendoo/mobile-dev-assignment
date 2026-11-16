// Run from app/: flutter test tool/render_push_preview.dart --no-pub
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:forest_sokoban/domain/puzzle.dart';
import 'package:forest_sokoban/ui/figma_board.dart';

import '../test/support.dart';

void main() {
  testWidgets('capture movement and altar feedback from the live board', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(277, 202);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final level = testLevels().first;
    var state = level.initial;
    final key = GlobalKey();
    Widget scene() => MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: FigmaBoard(level: level, board: state, onMove: (_) {}),
      ),
    );
    Future<void> capture(String name) => tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('../docs/a02/push-previews');
      await dir.create(recursive: true);
      await File('${dir.path}/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(scene());
    await tester.pumpAndSettle();
    state = GameRules.moveBoard(level, state, Direction.right)!;
    await tester.pumpWidget(scene());
    await tester.pump(const Duration(milliseconds: 70));
    await capture('push-midway');
    await tester.pumpAndSettle();
    state = GameRules.moveBoard(level, state, Direction.right)!;
    await tester.pumpWidget(scene());
    await tester.pump(const Duration(milliseconds: 210));
    await capture('altar-glow');
    await tester.pumpAndSettle();
  });
}
