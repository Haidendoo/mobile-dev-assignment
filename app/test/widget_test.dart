import 'package:flutter_test/flutter_test.dart';
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
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(CampaignApp(model: vm));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch disables Continue and starts an offline campaign', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('No unfinished campaign'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Campaign'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First Steps'));
    await tester.pumpAndSettle();
    expect(find.text('L01 · First Steps'), findsOneWidget);
    expect(find.byTooltip('Move right'), findsOneWidget);
  });

  for (final size in [const Size(640, 360), const Size(800, 450)]) {
    testWidgets('play, win and replay at $size with 1.3x text', (tester) async {
      await vm.start(vm.levels.first);
      await vm.pause();
      await open(tester, size: size, scale: 1.3);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Resume'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Move right'));
      await tester.pumpAndSettle();
      expect(vm.attempt!.steps, 1);
      await tester.tap(find.byTooltip('Move right'));
      await tester.pumpAndSettle();
      expect(find.text('Grove restored!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Replay'));
      await tester.pumpAndSettle();
      expect(vm.attempt!.steps, 0);
      expect(find.text('Grove restored!'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restart dialog Cancel preserves board and Confirm resets it', (
    tester,
  ) async {
    await vm.start(vm.levels.first);
    await vm.pause();
    await open(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move right'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restart'));
    await tester.pumpAndSettle();
    expect(find.text('Restart this level?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(vm.attempt!.steps, 1);
    expect(vm.paused, isFalse);
    await tester.tap(find.widgetWithText(FilledButton, 'Restart'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restart').last);
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
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Resume'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(vm.paused, isTrue);
    expect(find.text('Paused'), findsOneWidget);
  });
}
