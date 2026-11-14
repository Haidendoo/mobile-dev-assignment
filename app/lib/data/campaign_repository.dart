import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/puzzle.dart';

class BestScore {
  const BestScore(this.steps, this.elapsedMs);
  final int steps;
  final int elapsedMs;
}

abstract class CampaignRepository {
  Future<List<Level>> loadLevels();
  Future<Map<String, BestScore>> loadProgress();
  Future<Map<String, dynamic>?> loadSave();
  Future<void> save(Attempt attempt);
  Future<void> discardSave();
  Future<void> complete(Attempt attempt, String submissionId);
  Future<void> close();
}

class SqliteCampaignRepository implements CampaignRepository {
  SqliteCampaignRepository(this.database);
  final Database database;

  static Future<SqliteCampaignRepository> open({String? path}) async {
    final file = path ?? p.join(await getDatabasesPath(), 'forest_sokoban.db');
    final database = await openDatabase(
      file,
      version: 2,
      onCreate: (db, version) => createSchema(db),
      onUpgrade: (db, oldVersion, version) async {
        // No V1 app has shipped. A full legacy migration remains an A02 task;
        // refuse unknown old schemas rather than silently claiming compatibility.
        throw const FormatException(
          'Legacy database migration is not available yet.',
        );
      },
    );
    return SqliteCampaignRepository(database);
  }

  static Future<void> createSchema(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE campaign_save '
      '(slot INTEGER PRIMARY KEY CHECK(slot = 1), payload TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE progress (level_key TEXT PRIMARY KEY, '
      'steps INTEGER NOT NULL CHECK(steps >= 0), '
      'elapsed_ms INTEGER NOT NULL CHECK(elapsed_ms >= 0))',
    );
    await db.execute(
      'CREATE TABLE score_outbox (submission_id TEXT PRIMARY KEY, '
      'attempt_id TEXT NOT NULL UNIQUE, owner_id TEXT, level_key TEXT NOT NULL, '
      'steps INTEGER NOT NULL, elapsed_ms INTEGER NOT NULL, '
      "state TEXT NOT NULL DEFAULT 'pending')",
    );
    await db.execute(
      'CREATE TABLE metadata '
      '(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
  }

  @override
  Future<List<Level>> loadLevels() async {
    final source = jsonDecode(
      await rootBundle.loadString('assets/data/levels.json'),
    ) as Map<String, dynamic>;
    return (source['levels'] as List)
        .map((j) => Level.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, BestScore>> loadProgress() async => {
    for (final row in await database.query('progress'))
      row['level_key'] as String: BestScore(
        row['steps'] as int,
        row['elapsed_ms'] as int,
      ),
  };

  @override
  Future<Map<String, dynamic>?> loadSave() async {
    final rows = await database.query('campaign_save');
    return rows.isEmpty
        ? null
        : jsonDecode(rows.single['payload'] as String) as Map<String, dynamic>;
  }

  @override
  Future<void> save(Attempt attempt) async {
    await database.insert('campaign_save', {
      'slot': 1,
      'payload': jsonEncode(attempt.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> discardSave() async => database.transaction((tx) async {
    await tx.delete('campaign_save');
  });

  @override
  Future<void> complete(Attempt attempt, String submissionId) async {
    await database.transaction((tx) async {
      final old = await tx.query(
        'progress',
        where: 'level_key = ?',
        whereArgs: [attempt.levelKey],
      );
      if (old.isEmpty ||
          betterScore(
            attempt.steps,
            attempt.elapsedMs,
            old.single['steps'] as int,
            old.single['elapsed_ms'] as int,
          )) {
        await tx.insert('progress', {
          'level_key': attempt.levelKey,
          'steps': attempt.steps,
          'elapsed_ms': attempt.elapsedMs,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      // Persist every completion until a future authenticated publisher ACKs it.
      // The attempt constraint makes transaction retries safe.
      await tx.insert('score_outbox', {
        'submission_id': submissionId,
        'attempt_id': attempt.id,
        'level_key': attempt.levelKey,
        'steps': attempt.steps,
        'elapsed_ms': attempt.elapsedMs,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await tx.delete('campaign_save');
    });
  }

  @override
  Future<void> close() => database.close();
}
