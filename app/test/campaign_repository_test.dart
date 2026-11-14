import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:forest_sokoban/data/campaign_repository.dart';
import 'package:forest_sokoban/domain/puzzle.dart';

import 'support.dart';

void main() {
  late SqliteCampaignRepository repository;
  final level = testLevels().first;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    repository = await SqliteCampaignRepository.open(
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() => repository.close());

  Attempt finish(String id, {int steps = 2, int ms = 1200}) {
    var attempt = Attempt.start(level, id);
    attempt = GameRules.move(level, attempt, Direction.right)!;
    attempt = GameRules.move(level, attempt, Direction.right)!;
    return Attempt(
      id: id,
      levelKey: level.key,
      board: attempt.board,
      steps: steps,
      elapsedMs: ms,
      history: attempt.history,
    );
  }

  test('save roundtrip keeps board, history, counters and version', () async {
    final attempt = GameRules.move(
      level,
      Attempt.start(level, 'roundtrip'),
      Direction.right,
    )!;
    await repository.save(attempt.withTime(900));
    final restored = Attempt.restore((await repository.loadSave())!, level);
    expect(restored.steps, 1);
    expect(restored.history.length, 1);
    expect(restored.elapsedMs, 900);
    expect(restored.board.crates, attempt.board.crates);
  });

  test(
    'completion commits progress, outbox and save removal together',
    () async {
      await repository.save(Attempt.start(level, 'one'));
      await repository.complete(finish('one'), 'submission-one');
      expect(await repository.loadSave(), isNull);
      expect((await repository.loadProgress())[level.key]!.steps, 2);
      final rows = await repository.database.query('score_outbox');
      expect(rows.length, 1);
      expect(rows.single['state'], 'pending');
      expect(rows.single['owner_id'], isNull);
    },
  );

  test('failed completion rolls back every change', () async {
    await repository.save(Attempt.start(level, 'rollback'));
    await repository.database.execute(
      'CREATE TRIGGER fail_insert BEFORE INSERT ON score_outbox '
      "BEGIN SELECT RAISE(ABORT, 'injected storage failure'); END",
    );
    await expectLater(
      repository.complete(finish('rollback'), 'failure'),
      throwsA(isA<Exception>()),
    );
    expect(await repository.loadProgress(), isEmpty);
    expect(await repository.loadSave(), isNotNull);
    expect(await repository.database.query('score_outbox'), isEmpty);
  });

  test(
    'best result remains one pair and improves by Steps then time',
    () async {
      await repository.complete(finish('a', steps: 4, ms: 1000), 'a');
      await repository.complete(finish('b', steps: 2, ms: 9000), 'b');
      await repository.complete(finish('c', steps: 3, ms: 1), 'c');
      final best = (await repository.loadProgress())[level.key]!;
      expect(best.steps, 2);
      expect(best.elapsedMs, 9000);
      await repository.complete(finish('d', steps: 2, ms: 8000), 'd');
      expect((await repository.loadProgress())[level.key]!.elapsedMs, 8000);
    },
  );

  test('completion retry does not duplicate the outbox', () async {
    await repository.complete(finish('same-attempt'), 'same-uuid');
    await repository.complete(finish('same-attempt'), 'same-uuid');
    expect((await repository.database.query('score_outbox')).length, 1);
  });

  test('discarding save preserves completed progress and outbox', () async {
    await repository.complete(finish('old'), 'old');
    await repository.save(Attempt.start(level, 'new'));
    await repository.discardSave();
    expect(await repository.loadSave(), isNull);
    expect(await repository.loadProgress(), isNotEmpty);
    expect(await repository.database.query('score_outbox'), isNotEmpty);
  });
}
