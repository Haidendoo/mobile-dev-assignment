import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:forest_sokoban/domain/puzzle.dart';
import 'package:forest_sokoban/viewmodels/campaign_view_model.dart';

import 'support.dart';

void main() {
  late MemoryRepository repository;
  late ManualClock clock;
  late CampaignViewModel vm;
  setUp(() async {
    repository = MemoryRepository();
    clock = ManualClock();
    vm = CampaignViewModel(repository, automaticTimer: false, clock: clock);
    await vm.initialize();
  });
  tearDown(() => vm.dispose());

  test(
    'start, pause, resume, checkpoint use only active monotonic time',
    () async {
      await vm.start(vm.levels.first);
      clock.advance(1200);
      await vm.pause();
      clock.advance(50000);
      expect(vm.elapsedMs, 1200);
      expect(repository.saved!['elapsed_ms'], 1200);
      vm.resume();
      clock.advance(300);
      await vm.checkpoint();
      expect(repository.saved!['elapsed_ms'], 1500);
    },
  );

  test('restored campaign is paused with Undo history intact', () async {
    await vm.start(vm.levels.first);
    await vm.move(Direction.right);
    clock.advance(900);
    await vm.pause();
    final restored = CampaignViewModel(repository, automaticTimer: false);
    addTearDown(restored.dispose);
    await restored.initialize();
    expect(restored.paused, isTrue);
    expect(restored.attempt!.steps, 1);
    expect(restored.attempt!.history.length, 1);
    expect(restored.elapsedMs, 900);
  });

  test(
    'failed save preserves acknowledged board and requires explicit resume',
    () async {
      await vm.start(vm.levels.first);
      final previous = vm.attempt;
      repository.failWrites = true;
      await vm.move(Direction.right);
      expect(vm.attempt, same(previous));
      expect(vm.error, isNotNull);
      expect(vm.paused, isTrue);
      repository.failWrites = false;
      await vm.retrySave();
      expect(vm.error, isNull);
      expect(vm.paused, isTrue);
      vm.resume();
      await vm.move(Direction.right);
      expect(vm.attempt!.steps, 1);
    },
  );

  test('intents are serialized and ACK happens after commit', () async {
    await vm.start(vm.levels.first);
    repository.writeGate = Completer<void>();
    final moving = vm.move(Direction.right);
    await vm.move(Direction.right);
    expect(vm.attempt!.steps, 0);
    repository.writeGate!.complete();
    await moving;
    expect(vm.attempt!.steps, 1);
  });

  test('background during an in-flight start finishes paused', () async {
    repository.writeGate = Completer<void>();
    final starting = vm.start(vm.levels.first);
    final pausing = vm.pause();
    repository.writeGate!.complete();
    await starting;
    await pausing;
    expect(vm.paused, isTrue);
    expect(clock.isRunning, isFalse);
  });

  test('completion freezes once and clears unfinished save', () async {
    await vm.start(vm.levels.first);
    await vm.move(Direction.right);
    await vm.move(Direction.right);
    expect(vm.solved, isTrue);
    expect(vm.hasSave, isFalse);
    expect(vm.completed, contains('L01/v1'));
    expect(repository.completions.length, 1);
    await vm.move(Direction.right);
    await vm.undo();
    expect(repository.completions.length, 1);
    expect(vm.attempt!.steps, 2);
  });

  test('failed completion keeps prior board and no progress', () async {
    await vm.start(vm.levels.first);
    await vm.move(Direction.right);
    repository.failWrites = true;
    await vm.move(Direction.right);
    expect(vm.solved, isFalse);
    expect(vm.attempt!.steps, 1);
    expect(vm.completed, isEmpty);
  });

  test('restart generates a new ID and resets all attempt counters', () async {
    await vm.start(vm.levels.first);
    final id = vm.attempt!.id;
    await vm.move(Direction.right);
    clock.advance(1500);
    await vm.restart();
    expect(vm.attempt!.id, isNot(id));
    expect(vm.attempt!.steps, 0);
    expect(vm.attempt!.history, isEmpty);
    expect(vm.elapsedMs, 0);
  });

  test('invalid save is retained until explicit discard', () async {
    repository.saved = {'level_key': 'missing'};
    await vm.initialize();
    expect(vm.corruptSave, isTrue);
    expect(repository.saved, isNotNull);
    await vm.discardCorruptSave();
    expect(repository.saved, isNull);
    expect(vm.corruptSave, isFalse);
  });
}
