import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:forest_sokoban/data/campaign_repository.dart';
import 'package:forest_sokoban/domain/puzzle.dart';

List<Map<String, dynamic>> levelJson() =>
    ((jsonDecode(File('assets/data/levels.json').readAsStringSync())
                as Map<String, dynamic>)['levels']
            as List)
        .cast<Map<String, dynamic>>();

List<Level> testLevels() => levelJson().map(Level.fromJson).toList();

class MemoryRepository implements CampaignRepository {
  Map<String, dynamic>? saved;
  Map<String, BestScore> progress = {};
  List<Attempt> completions = [];
  bool failWrites = false;
  Completer<void>? writeGate;
  @override
  Future<List<Level>> loadLevels() async => testLevels();
  @override
  Future<Map<String, BestScore>> loadProgress() async => Map.of(progress);
  @override
  Future<Map<String, dynamic>?> loadSave() async => saved;
  @override
  Future<void> save(Attempt attempt) async {
    if (writeGate != null) await writeGate!.future;
    if (failWrites) throw const FileSystemException('Injected write failure');
    saved = attempt.toJson();
  }

  @override
  Future<void> discardSave() async {
    saved = null;
  }

  @override
  Future<void> complete(Attempt attempt, String submissionId) async {
    if (failWrites) {
      throw const FileSystemException('Injected transaction failure');
    }
    completions.add(attempt);
    progress[attempt.levelKey] = BestScore(attempt.steps, attempt.elapsedMs);
    saved = null;
  }

  @override
  Future<void> close() async {}
}

class ManualClock implements Stopwatch {
  int ms = 0;
  bool running = false;
  void advance(int value) {
    if (running) ms += value;
  }

  @override
  int get elapsedMilliseconds => ms;
  @override
  Duration get elapsed => Duration(milliseconds: ms);
  @override
  int get elapsedMicroseconds => ms * 1000;
  @override
  int get elapsedTicks => elapsedMicroseconds;
  @override
  int get frequency => 1000000;
  @override
  bool get isRunning => running;
  @override
  void start() {
    running = true;
  }

  @override
  void stop() {
    running = false;
  }

  @override
  void reset() {
    ms = 0;
  }
}
