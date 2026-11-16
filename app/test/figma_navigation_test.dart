import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:forest_sokoban/ui/campaign_app.dart';
import 'package:forest_sokoban/viewmodels/campaign_view_model.dart';
import 'package:forest_sokoban/data/campaign_repository.dart';

import 'support.dart';

void main() {
  testWidgets('ranking picker uses real versions without starting a game', (
    tester,
  ) async {
    final vm = CampaignViewModel(MemoryRepository(), automaticTimer: false);
    addTearDown(vm.dispose);
    await vm.initialize();
    await tester.pumpWidget(CampaignApp(model: vm));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Leaderboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Choose level'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('L06 / v2'));
    await tester.pumpAndSettle();
    expect(find.text('Casual · Unverified · L06'), findsOneWidget);
    expect(vm.attempt, isNull);
  });

  testWidgets('world map and chapter cards reflect restored progress', (
    tester,
  ) async {
    final repository = MemoryRepository();
    final levels = testLevels();
    repository.progress = {
      for (final level in levels.take(5)) level.key: const BestScore(2, 1000),
    };
    final vm = CampaignViewModel(repository, automaticTimer: false);
    addTearDown(vm.dispose);
    await vm.initialize();
    await tester.pumpWidget(CampaignApp(model: vm));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('The Awakening'));
    await tester.pumpAndSettle();
    expect(find.text('Best 2 · 00:01'), findsNWidgets(5));
  });

  testWidgets('later chapters use their own Figma gameplay themes', (
    tester,
  ) async {
    final repository = MemoryRepository();
    final levels = testLevels();
    repository.progress = {
      for (final level in levels.take(9)) level.key: const BestScore(2, 1000),
    };
    final vm = CampaignViewModel(repository, automaticTimer: false);
    addTearDown(vm.dispose);
    await vm.initialize();
    await vm.start(vm.levels[5]);
    await vm.pause();
    await tester.pumpWidget(CampaignApp(model: vm));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('RUNES ALIGNED'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    final board = tester.getSemantics(
      find.byKey(const ValueKey('puzzle-status')),
    );
    expect(board.getSemanticsData().customSemanticsActionIds, hasLength(4));
    semantics.dispose();
  });

  testWidgets('Figma buttons expose an accessibility tap action', (
    tester,
  ) async {
    final vm = CampaignViewModel(MemoryRepository(), automaticTimer: false);
    addTearDown(vm.dispose);
    await vm.initialize();
    await tester.pumpWidget(CampaignApp(model: vm));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    final node = tester.getSemantics(find.bySemanticsLabel('Play'));
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('Back from More returns to Home', (tester) async {
    final vm = CampaignViewModel(MemoryRepository(), automaticTimer: false);
    addTearDown(vm.dispose);
    await vm.initialize();
    await tester.pumpWidget(CampaignApp(model: vm));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('The Lost Seeds'), findsOneWidget);
  });

  testWidgets('More uses the Figma screen and navigates through chapters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = CampaignViewModel(MemoryRepository(), automaticTimer: false);
    addTearDown(vm.dispose);
    await vm.initialize();
    await tester.pumpWidget(CampaignApp(model: vm));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    await tester.tap(find.text('Chapters'));
    await tester.pumpAndSettle();
    expect(find.text('World Map'), findsOneWidget);
    await tester.tap(find.text('The Awakening'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First Steps'));
    await tester.pumpAndSettle();
    expect(find.text('Swipe to move'), findsOneWidget);
    expect(find.byTooltip('Move right'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('puzzle-swipe')),
      const Offset(65, 0),
    );
    await tester.pumpAndSettle();
    expect(vm.attempt!.steps, 1);
  });
}
