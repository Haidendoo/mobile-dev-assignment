import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:forest_sokoban/domain/puzzle.dart';
import 'package:forest_sokoban/ui/figma_board.dart';
import 'package:forest_sokoban/ui/campaign_app.dart';
import 'package:forest_sokoban/viewmodels/campaign_view_model.dart';

import 'support.dart';

void main() {
  final level = testLevels().first;
  final crate = find.byWidgetPredicate(
    (w) =>
        w is SvgPicture &&
        w.bytesLoader is SvgAssetLoader &&
        (w.bytesLoader as SvgAssetLoader).assetName.endsWith(
          '7ef2a194-810a-4a1a-af56-ac44566b1f90.svg',
        ),
  );
  Widget board(Board state, {bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Center(
        child: SizedBox(
          width: 277,
          height: 202,
          child: FigmaBoard(level: level, board: state, onMove: (_) {}),
        ),
      ),
    ),
  );

  testWidgets('pushed crate slides between cells and Undo slides it back', (
    tester,
  ) async {
    await tester.pumpWidget(board(level.initial));
    await tester.pumpAndSettle();
    final start = tester.getTopLeft(crate).dx;
    const cell = 263 / 7;
    final moved = GameRules.moveBoard(level, level.initial, Direction.right)!;
    await tester.pumpWidget(board(moved));
    await tester.pump(const Duration(milliseconds: 70));
    final mid = tester.getTopLeft(crate).dx;
    expect(mid, greaterThan(start));
    expect(mid, lessThan(start + cell - 1));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(crate).dx, closeTo(start + cell, .1));
    await tester.pumpWidget(board(level.initial));
    await tester.pump(const Duration(milliseconds: 70));
    final undoMid = tester.getTopLeft(crate).dx;
    expect(undoMid, greaterThan(start));
    expect(undoMid, lessThan(start + cell));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(crate).dx, closeTo(start, .1));
  });

  testWidgets('reduced motion places the crate immediately', (tester) async {
    await tester.pumpWidget(board(level.initial, reduced: true));
    await tester.pumpAndSettle();
    final start = tester.getTopLeft(crate).dx;
    await tester.pumpWidget(
      board(
        GameRules.moveBoard(level, level.initial, Direction.right)!,
        reduced: true,
      ),
    );
    expect(tester.getTopLeft(crate).dx, closeTo(start + 263 / 7, .1));
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'winning push finishes visually before Level clear replaces board',
    (tester) async {
      final vm = CampaignViewModel(MemoryRepository(), automaticTimer: false);
      addTearDown(vm.dispose);
      await vm.initialize();
      await vm.start(vm.levels.first);
      await vm.pause();
      await tester.pumpWidget(CampaignApp(model: vm));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Resume'));
      await tester.pumpAndSettle();
      await vm.move(Direction.right);
      await tester.pumpAndSettle();
      await vm.move(Direction.right);
      await tester.pump();
      expect(vm.solved, isTrue);
      expect(find.text('Level clear'), findsNothing);
      expect(find.byKey(const ValueKey('puzzle-swipe')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Level clear'), findsOneWidget);
    },
  );
}
