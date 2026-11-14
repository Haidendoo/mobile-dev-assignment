import 'package:flutter_test/flutter_test.dart';
import 'package:forest_sokoban/domain/puzzle.dart';

import 'support.dart';

void main() {
  final levels = testLevels();
  for (final json in levelJson()) {
    test(
      '${json['id']}/v${json['version']} reference solution is legal and wins',
      () {
        final level = Level.fromJson(json);
        var attempt = Attempt.start(level, 'test');
        final solution = json['solution'] as String;
        for (var index = 0; index < solution.length; index++) {
          final next = GameRules.move(
            level,
            attempt,
            Direction.fromCode(solution[index]),
          );
          expect(next, isNotNull, reason: 'Blocked action at $index');
          attempt = next!;
          expect(level.solved(attempt.board), index == solution.length - 1);
        }
        expect(attempt.steps, solution.length);
        expect(GameRules.undo(level, attempt), isNull);
        expect(GameRules.move(level, attempt, Direction.left), isNull);
      },
    );
  }

  test('blocked move leaves board, history and Steps unchanged', () {
    final initial = Attempt.start(levels.first, 'blocked');
    final up = GameRules.move(levels.first, initial, Direction.up)!;
    expect(GameRules.move(levels.first, up, Direction.up), isNull);
    expect(up.steps, 1);
    expect(up.history.length, 1);
  });

  test('cannot push two crates or push into a wall', () {
    final level = Level.fromJson({
      'id': 'fixture',
      'version': 1,
      'name': 'fixture',
      'chapter': 1,
      'map': ['#######', r'#@$$..#', '#######'],
    });
    expect(
      GameRules.move(level, Attempt.start(level, 'a'), Direction.right),
      isNull,
    );
    final blocked = Attempt(
      id: 'b',
      levelKey: level.key,
      board: Board(const Cell(4, 1), [const Cell(5, 1), const Cell(2, 1)]),
    );
    expect(GameRules.move(level, blocked, Direction.right), isNull);
  });

  test('Undo restores board, costs one Step and preserves elapsed time', () {
    final initial = Attempt.start(levels.first, 'undo').withTime(1500);
    final moved = GameRules.move(levels.first, initial, Direction.right)!;
    final restored = GameRules.undo(levels.first, moved)!;
    expect(restored.board.player, initial.board.player);
    expect(restored.board.crates, initial.board.crates);
    expect(restored.steps, 2);
    expect(restored.elapsedMs, 1500);
    expect(restored.history, isEmpty);
    expect(GameRules.undo(levels.first, restored), isNull);
  });

  test(
    'restoration validates map/version, history chain and counter parity',
    () {
      final moved = GameRules.move(
        levels.first,
        Attempt.start(levels.first, 'save'),
        Direction.right,
      )!;
      expect(
        Attempt.restore(moved.toJson(), levels.first).board.crates,
        moved.board.crates,
      );
      for (final entry in <String, dynamic>{
        'steps': 0,
        'level_key': 'L01/v9',
        'history': [],
        'elapsed_ms': -1,
        'schema_version': 1,
      }.entries) {
        expect(
          () => Attempt.restore({
            ...moved.toJson(),
            entry.key: entry.value,
          }, levels.first),
          throwsFormatException,
        );
      }
    },
  );

  test('chapter unlock depends on current version completions', () {
    expect(chapterUnlocked(1, levels, {}), isTrue);
    expect(chapterUnlocked(2, levels, {}), isFalse);
    final completed = levels.take(5).map((l) => l.key).toSet();
    expect(chapterUnlocked(2, levels, completed), isTrue);
    expect(chapterUnlocked(3, levels, completed), isFalse);
    completed.addAll(levels.take(9).map((l) => l.key));
    expect(chapterUnlocked(3, levels, completed), isTrue);
    completed.remove('L06/v2');
    completed.add('L06/v1');
    expect(chapterUnlocked(3, levels, completed), isFalse);
  });

  test('best comparison keeps a whole Steps/time pair', () {
    expect(betterScore(9, 9000, 10, 1000), isTrue);
    expect(betterScore(10, 999, 10, 1000), isTrue);
    expect(betterScore(10, 1000, 10, 1000), isFalse);
    expect(betterScore(11, 1, 10, 1000), isFalse);
  });
}
