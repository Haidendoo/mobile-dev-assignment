import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:forest_sokoban/ui/campaign_app.dart';
import 'package:forest_sokoban/viewmodels/campaign_view_model.dart';

import 'support.dart';

void main() {
  late CampaignViewModel vm;
  setUp(() async {
    vm = CampaignViewModel(MemoryRepository(), automaticTimer: false);
    await vm.initialize();
  });
  tearDown(() => vm.dispose());

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(800, 450),
    double scale = 1,
    GlobalKey? boundaryKey,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: CampaignApp(model: vm),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Home artwork background also covers system insets', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 20, bottom: 20);
    addTearDown(tester.view.resetPadding);
    final key = GlobalKey();
    await open(tester, boundaryKey: key);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      try {
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final offset = (10 * image.width + 10) * 4;
        expect(bytes!.buffer.asUint8List().sublist(offset, offset + 4), [
          0x10,
          0x1e,
          0x19,
          255,
        ]);
      } finally {
        image.dispose();
      }
    });
  });

  testWidgets('Figma fresh Home and More use the current navigation', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Forest'), findsOneWidget);
    expect(find.text('Sokoban'), findsOneWidget);
    expect(find.text('The Lost Seeds'), findsOneWidget);
    expect(find.text('Campaign'), findsNothing);
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    expect(find.text('Chapters'), findsOneWidget);
    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    expect(find.text('Swipe to move'), findsOneWidget);
  });

  testWidgets('Figma Continue names and restores the actual saved level', (
    tester,
  ) async {
    await vm.start(vm.levels[1]);
    await vm.pause();
    await open(tester);
    expect(find.text('Around the Bend'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Around the Bend'), findsWidgets);
    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('Home controls remain separate in a short landscape viewport', (
    tester,
  ) async {
    await vm.start(vm.levels.first);
    await vm.pause();
    await open(tester, size: const Size(640, 300), scale: 1.3);
    final primary = tester.getRect(find.bySemanticsLabel('Continue'));
    final more = tester.getRect(find.bySemanticsLabel('More'));
    expect(primary.height, greaterThanOrEqualTo(48));
    expect(more.height, greaterThanOrEqualTo(48));
    expect(primary.overlaps(more), isFalse);
    expect(more.bottom, lessThanOrEqualTo(300));
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    expect(find.text('Chapters'), findsOneWidget);
  });

  testWidgets('first launch uses Play and starts an offline campaign', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(vm.attempt, isNull);
    await tester.tap(find.bySemanticsLabel('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Awakening'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First Steps'));
    await tester.pumpAndSettle();
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.byKey(const ValueKey('puzzle-swipe')), findsOneWidget);
  });

  for (final size in [
    const Size(640, 360),
    const Size(800, 360),
    const Size(800, 450),
    const Size(960, 432),
  ]) {
    testWidgets('play, win and replay at $size with 1.3x text', (tester) async {
      await vm.start(vm.levels.first);
      await vm.pause();
      await open(tester, size: size, scale: 1.3);
      final continueRect = tester.getRect(find.bySemanticsLabel('Continue'));
      final moreRect = tester.getRect(find.bySemanticsLabel('More'));
      expect(continueRect.height, greaterThanOrEqualTo(48));
      expect(moreRect.height, greaterThanOrEqualTo(48));
      expect(continueRect.overlaps(moreRect), isFalse);
      await tester.tap(find.bySemanticsLabel('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('puzzle-swipe')),
        const Offset(65, 0),
      );
      await tester.pumpAndSettle();
      expect(vm.attempt!.steps, 1);
      await tester.drag(
        find.byKey(const ValueKey('puzzle-swipe')),
        const Offset(65, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Level clear'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.bySemanticsLabel('Replay'));
      await tester.pumpAndSettle();
      expect(vm.attempt!.steps, 0);
      expect(find.text('Level clear'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restart dialog Cancel preserves board and Confirm resets it', (
    tester,
  ) async {
    await vm.start(vm.levels.first);
    await vm.pause();
    await open(tester);
    await tester.tap(find.bySemanticsLabel('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('puzzle-swipe')),
      const Offset(65, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Restart'));
    await tester.pumpAndSettle();
    expect(find.text('Restart level?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(vm.attempt!.steps, 1);
    expect(vm.paused, isFalse);
    await tester.tap(find.bySemanticsLabel('Restart'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Restart').last);
    await tester.pumpAndSettle();
    expect(vm.attempt!.steps, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('background pauses and foreground does not auto-resume', (
    tester,
  ) async {
    await vm.start(vm.levels.first);
    await vm.pause();
    await open(tester);
    await tester.tap(find.bySemanticsLabel('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(vm.paused, isTrue);
    expect(find.text('Paused'), findsOneWidget);
  });
}
