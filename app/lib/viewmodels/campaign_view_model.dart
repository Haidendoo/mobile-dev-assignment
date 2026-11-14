import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/campaign_repository.dart';
import '../domain/puzzle.dart';

class CampaignViewModel extends ChangeNotifier {
  CampaignViewModel(
    this.repository, {
    bool automaticTimer = true,
    Stopwatch? clock,
  }) : _clock = clock ?? Stopwatch() {
    if (automaticTimer) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => checkpoint());
    }
  }

  final CampaignRepository repository;
  final Stopwatch _clock;
  final _uuid = const Uuid();
  Timer? _timer;
  List<Level> levels = [];
  Map<String, BestScore> progress = {};
  Attempt? attempt;
  Level? level;
  bool loading = true;
  bool busy = false;
  bool paused = true;
  bool hasSave = false;
  bool corruptSave = false;
  String? error;
  String feedback = 'Push the Light Seeds onto the restoration altars.';
  bool _disposed = false;
  int _baseMs = 0;
  Future<void>? _pending;

  bool get solved => attempt != null && level!.solved(attempt!.board);
  int get elapsedMs => _baseMs + _clock.elapsedMilliseconds;
  Set<String> get completed => progress.keys.toSet();
  bool unlocked(int chapter) => chapterUnlocked(chapter, levels, completed);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    loading = true;
    error = null;
    _notify();
    try {
      levels = await repository.loadLevels();
      progress = await repository.loadProgress();
      await _restore();
    } catch (_) {
      error = 'Could not open local game data. Please retry.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> _restore() async {
    hasSave = false;
    corruptSave = false;
    attempt = null;
    level = null;
    paused = true;
    _baseMs = 0;
    _clock
      ..stop()
      ..reset();
    try {
      final data = await repository.loadSave();
      if (data == null) return;
      final selected = levels.firstWhere((l) => l.key == data['level_key']);
      attempt = Attempt.restore(data, selected);
      level = selected;
      _baseMs = attempt!.elapsedMs;
      _clock
        ..stop()
        ..reset();
      paused = true;
      hasSave = true;
    } on FormatException {
      corruptSave = true;
    } on TypeError {
      corruptSave = true;
    } on StateError {
      corruptSave = true;
    }
  }

  Future<void> start(Level selected) => _exclusive(() async {
    if (!unlocked(selected.chapter)) return;
    final fresh = Attempt.start(selected, _uuid.v4());
    await repository.save(fresh);
    level = selected;
    attempt = fresh;
    hasSave = true;
    _baseMs = 0;
    error = null;
    corruptSave = false;
    _clock
      ..stop()
      ..reset()
      ..start();
    paused = false;
    feedback = 'Restore every altar. Undo costs one Step.';
  });

  Future<void> move(Direction direction) =>
      _act((l, a) => GameRules.move(l, a, direction));
  Future<void> undo() => _act(GameRules.undo);

  Future<void> _act(Attempt? Function(Level, Attempt) change) =>
      _exclusive(() async {
        if (attempt == null || paused || solved || error != null) return;
        final candidate = change(level!, attempt!.withTime(elapsedMs));
        if (candidate == null) {
          feedback = 'Blocked. Try another direction or Undo.';
          return;
        }
        if (level!.solved(candidate.board)) {
          _clock.stop();
          final finished = candidate.withTime(elapsedMs);
          try {
            await repository.complete(finished, _uuid.v4());
          } catch (_) {
            // Keep the last acknowledged board, rather than displaying a win
            // that the database has not committed.
            rethrow;
          }
          attempt = finished;
          final best = progress[finished.levelKey];
          if (best == null ||
              betterScore(
                finished.steps,
                finished.elapsedMs,
                best.steps,
                best.elapsedMs,
              )) {
            progress = {
              ...progress,
              finished.levelKey: BestScore(finished.steps, finished.elapsedMs),
            };
          }
          _baseMs = finished.elapsedMs;
          _clock.reset();
          paused = true;
          hasSave = false;
          feedback = 'Forest restored! Your result is saved on this device.';
        } else {
          await repository.save(candidate);
          attempt = candidate;
          feedback = 'Saved on this device';
        }
      });

  Future<void> pause() async {
    // Freeze immediately, even when an action transaction is in flight.
    paused = true;
    _clock.stop();
    _notify();
    final pending = _pending;
    if (pending != null) await pending;
    paused = true;
    _clock.stop();
    await _exclusive(() async {
      if (attempt == null || solved) return;
      final saved = attempt!.withTime(elapsedMs);
      await repository.save(saved);
      attempt = saved;
    });
  }

  void resume() {
    if (attempt == null || solved || busy || error != null) return;
    paused = false;
    _clock.start();
    _notify();
  }

  Future<void> restart() async {
    if (level != null) await start(level!);
  }

  Future<void> checkpoint() => _exclusive(() async {
    if (paused || solved || attempt == null || error != null) return;
    final updated = attempt!.withTime(elapsedMs);
    await repository.save(updated);
    attempt = updated;
  });

  Future<void> retrySave() => _exclusive(() async {
    if (attempt != null && !solved) {
      await repository.save(attempt!.withTime(elapsedMs));
    }
    error = null;
    feedback = 'Saved. Select Resume when you are ready.';
  });

  Future<void> discardCorruptSave() => _exclusive(() async {
    await repository.discardSave();
    corruptSave = false;
    hasSave = false;
    error = null;
  });

  Future<void> _exclusive(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    _notify();
    final operation = () async {
      try {
        await action();
      } catch (_) {
        paused = true;
        _clock.stop();
        error =
            'Could not save your game. Your last saved board is preserved. '
            'Free some storage and retry.';
      } finally {
        busy = false;
        _notify();
      }
    }();
    _pending = operation;
    await operation;
    _pending = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
