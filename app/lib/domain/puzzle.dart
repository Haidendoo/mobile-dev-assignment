import 'dart:collection';

enum Direction {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const Direction(this.dx, this.dy);
  final int dx;
  final int dy;

  static Direction fromCode(String code) => switch (code) {
    'U' => up,
    'D' => down,
    'L' => left,
    'R' => right,
    _ => throw FormatException('Unknown direction: $code'),
  };
}

class Cell {
  const Cell(this.x, this.y);
  factory Cell.fromJson(dynamic value) {
    if (value is! List ||
        value.length != 2 ||
        value[0] is! int ||
        value[1] is! int) {
      throw const FormatException('Invalid cell');
    }
    return Cell(value[0] as int, value[1] as int);
  }
  final int x;
  final int y;
  Cell offset(Direction d) => Cell(x + d.dx, y + d.dy);
  List<int> toJson() => [x, y];
  @override
  bool operator ==(Object other) =>
      other is Cell && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
}

class Board {
  Board(this.player, Iterable<Cell> crates)
    : crates = UnmodifiableSetView(Set<Cell>.of(crates));
  factory Board.fromJson(Map<String, dynamic> json) => Board(
    Cell.fromJson(json['player']),
    (json['crates'] as List).map(Cell.fromJson),
  );
  final Cell player;
  final Set<Cell> crates;
  Map<String, dynamic> toJson() => {
    'player': player.toJson(),
    'crates': crates.map((p) => p.toJson()).toList(),
  };
}

class Level {
  Level._(
    this.id,
    this.version,
    this.name,
    this.chapter,
    this.rows,
    this.walls,
    this.goals,
    this.initial,
  );

  factory Level.fromJson(Map<String, dynamic> json) {
    final rows = List<String>.from(json['map'] as List);
    if (rows.length < 3 ||
        rows.length > 8 ||
        rows.first.length < 3 ||
        rows.first.length > 10 ||
        rows.any((r) => r.length != rows.first.length)) {
      throw const FormatException('Invalid board dimensions');
    }
    final walls = <Cell>{};
    final goals = <Cell>{};
    final crates = <Cell>{};
    final players = <Cell>[];
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        final char = rows[y][x];
        final p = Cell(x, y);
        if (!r'# .$@*+'.contains(char)) {
          throw const FormatException('Unknown tile');
        }
        if (char == '#') walls.add(p);
        if ('.*+'.contains(char)) goals.add(p);
        if (r'$*'.contains(char)) crates.add(p);
        if ('@+'.contains(char)) players.add(p);
        if ((x == 0 ||
                y == 0 ||
                x == rows[y].length - 1 ||
                y == rows.length - 1) &&
            char != '#') {
          throw const FormatException('Open board boundary');
        }
      }
    }
    if (players.length != 1 ||
        crates.isEmpty ||
        crates.length > 4 ||
        crates.length != goals.length) {
      throw const FormatException('Invalid player, crate, or goal count');
    }
    return Level._(
      json['id'] as String,
      json['version'] as int,
      json['name'] as String,
      json['chapter'] as int,
      List.unmodifiable(rows),
      Set.unmodifiable(walls),
      Set.unmodifiable(goals),
      Board(players.single, crates),
    );
  }

  final String id;
  final int version;
  final String name;
  final int chapter;
  final List<String> rows;
  final Set<Cell> walls;
  final Set<Cell> goals;
  final Board initial;
  int get width => rows.first.length;
  int get height => rows.length;
  String get key => '$id/v$version';

  bool walkable(Cell p) =>
      p.x >= 0 && p.y >= 0 && p.x < width && p.y < height && !walls.contains(p);

  bool validBoard(Board b) =>
      walkable(b.player) &&
      !b.crates.contains(b.player) &&
      b.crates.length == goals.length &&
      b.crates.every(walkable);

  bool solved(Board b) =>
      b.crates.length == goals.length && b.crates.every(goals.contains);
}

class Attempt {
  Attempt({
    required this.id,
    required this.levelKey,
    required this.board,
    this.steps = 0,
    this.elapsedMs = 0,
    Iterable<Board> history = const [],
  }) : history = List.unmodifiable(history);

  factory Attempt.start(Level level, String id) =>
      Attempt(id: id, levelKey: level.key, board: level.initial);

  factory Attempt.restore(Map<String, dynamic> json, Level level) {
    if (json['schema_version'] != 2 || json['level_key'] != level.key) {
      throw const FormatException('Unsupported save or level version');
    }
    final attempt = Attempt(
      id: json['attempt_id'] as String,
      levelKey: json['level_key'] as String,
      board: Board.fromJson(json['board'] as Map<String, dynamic>),
      steps: json['steps'] as int,
      elapsedMs: json['elapsed_ms'] as int,
      history: (json['history'] as List).map(
        (b) => Board.fromJson(b as Map<String, dynamic>),
      ),
    );
    if (attempt.id.isEmpty ||
        attempt.steps < 0 ||
        attempt.elapsedMs < 0 ||
        attempt.steps < attempt.history.length ||
        (attempt.steps - attempt.history.length).isOdd ||
        !level.validBoard(attempt.board) ||
        attempt.history.any((b) => !level.validBoard(b) || level.solved(b)) ||
        level.solved(attempt.board)) {
      throw const FormatException('Invalid saved attempt');
    }
    // Verify the history is a chain of legal moves from the canonical map.
    var previous = level.initial;
    for (final next in [...attempt.history.skip(1), attempt.board]) {
      if (attempt.history.isEmpty) break;
      if (!_sameBoard(attempt.history.first, level.initial) ||
          !Direction.values.any((d) {
            final move = GameRules.moveBoard(level, previous, d);
            return move != null && _sameBoard(move, next);
          })) {
        throw const FormatException('Invalid history chain');
      }
      previous = next;
    }
    if (attempt.history.isEmpty && !_sameBoard(attempt.board, level.initial)) {
      throw const FormatException('Missing history');
    }
    return attempt;
  }

  final String id;
  final String levelKey;
  final Board board;
  final int steps;
  final int elapsedMs;
  final List<Board> history;

  Attempt withTime(int ms) => Attempt(
    id: id,
    levelKey: levelKey,
    board: board,
    steps: steps,
    elapsedMs: ms,
    history: history,
  );

  Map<String, dynamic> toJson() => {
    'schema_version': 2,
    'attempt_id': id,
    'level_key': levelKey,
    'board': board.toJson(),
    'steps': steps,
    'elapsed_ms': elapsedMs,
    'history': history.map((b) => b.toJson()).toList(),
  };
}

bool _sameBoard(Board a, Board b) =>
    a.player == b.player &&
    a.crates.length == b.crates.length &&
    a.crates.containsAll(b.crates);

abstract final class GameRules {
  static Board? moveBoard(Level level, Board board, Direction d) {
    final target = board.player.offset(d);
    if (!level.walkable(target)) return null;
    final crates = Set<Cell>.of(board.crates);
    if (crates.contains(target)) {
      final beyond = target.offset(d);
      if (!level.walkable(beyond) || crates.contains(beyond)) return null;
      crates
        ..remove(target)
        ..add(beyond);
    }
    return Board(target, crates);
  }

  static Attempt? move(Level level, Attempt current, Direction direction) {
    if (level.solved(current.board)) return null;
    final board = moveBoard(level, current.board, direction);
    if (board == null) return null;
    return Attempt(
      id: current.id,
      levelKey: current.levelKey,
      board: board,
      steps: current.steps + 1,
      elapsedMs: current.elapsedMs,
      history: [...current.history, current.board],
    );
  }

  static Attempt? undo(Level level, Attempt current) {
    if (level.solved(current.board) || current.history.isEmpty) return null;
    return Attempt(
      id: current.id,
      levelKey: current.levelKey,
      board: current.history.last,
      steps: current.steps + 1,
      elapsedMs: current.elapsedMs,
      history: current.history.take(current.history.length - 1),
    );
  }
}

const chapterNames = [
  'The Awakening',
  'Forgotten Ruins',
  'Heart of the Forest',
];

bool chapterUnlocked(int chapter, List<Level> levels, Set<String> completed) =>
    levels
        .where((l) => l.chapter < chapter)
        .every((l) => completed.contains(l.key));

bool betterScore(int steps, int ms, int oldSteps, int oldMs) =>
    steps < oldSteps || (steps == oldSteps && ms < oldMs);
