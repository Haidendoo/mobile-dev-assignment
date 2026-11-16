import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/puzzle.dart';
import 'push_feedback.dart';

/// Live Figma sprites with stable identities for cell-to-cell motion.
class FigmaBoard extends StatefulWidget {
  const FigmaBoard({
    super.key,
    required this.level,
    required this.board,
    required this.onMove,
    this.animate = true,
  });
  final Level level;
  final Board board;
  final void Function(Direction) onMove;
  final bool animate;
  static const slideDuration = Duration(milliseconds: 170);
  static const feedbackDuration = Duration(milliseconds: 280);
  @override
  State<FigmaBoard> createState() => _FigmaBoardState();
}

class _FigmaBoardState extends State<FigmaBoard>
    with SingleTickerProviderStateMixin {
  Level get level => widget.level;
  Board get board => widget.board;
  Offset _gesture = Offset.zero;
  static const _path = 'assets/figma/scenes/';
  final _crateIds = <Cell, int>{};
  late final AnimationController _feedback;
  int? _pushedId;
  Offset _pushDirection = Offset.zero;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _feedback = AnimationController(
      vsync: this,
      duration: FigmaBoard.feedbackDuration,
    );
    _resetIds();
  }

  void _resetIds() {
    _crateIds.clear();
    var id = 0;
    for (final p in board.crates) {
      _crateIds[p] = id++;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _feedback.stop();
      _feedback.value = 1;
    }
  }

  @override
  void didUpdateWidget(FigmaBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level.key != level.key) {
      _resetIds();
      _pushedId = null;
      _feedback.stop();
      return;
    }
    final removed = oldWidget.board.crates.difference(board.crates);
    final added = board.crates.difference(oldWidget.board.crates);
    if (removed.length == 1 && added.length == 1) {
      final from = removed.single;
      final to = added.single;
      final id = _crateIds.remove(from)!;
      _crateIds[to] = id;
      // Undo slides too; only a forward push emits dust and an altar glow.
      if (board.player == from && !_reducedMotion && widget.animate) {
        _pushedId = id;
        _pushDirection = Offset(
          (to.x - from.x).toDouble(),
          (to.y - from.y).toDouble(),
        );
        _feedback.forward(from: 0);
      } else {
        _pushedId = null;
        _feedback.stop();
      }
    } else if (removed.isNotEmpty || added.isNotEmpty) {
      _resetIds();
      _pushedId = null;
      _feedback.stop();
    }
    if (!widget.animate) {
      _pushedId = null;
      _feedback.stop();
    }
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('puzzle-status'),
    customSemanticsActions: {
      for (final d in Direction.values)
        CustomSemanticsAction(label: 'Move ${d.name}'): () => widget.onMove(d),
    },
    label:
        '${level.name}. Player at column ${board.player.x + 1}, row ${board.player.y + 1}. '
        '${board.crates.where(level.goals.contains).length} of ${level.goals.length} altars restored.',
    child: GestureDetector(
      key: const ValueKey('puzzle-swipe'),
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => _gesture = Offset.zero,
      onPanUpdate: (details) => _gesture += details.delta,
      onPanEnd: (_) {
        if (_gesture.distance < 20) return;
        widget.onMove(
          _gesture.dx.abs() > _gesture.dy.abs()
              ? (_gesture.dx > 0 ? Direction.right : Direction.left)
              : (_gesture.dy > 0 ? Direction.down : Direction.up),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(
            level.chapter == 1
                ? 0xff12241b
                : level.chapter == 2
                ? 0xff182f37
                : 0xff302136,
          ),
          border: Border.all(color: const Color(0xff8b9b6c), width: .5),
          borderRadius: BorderRadius.circular(7.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cell = math.min(
                constraints.maxWidth / level.width,
                constraints.maxHeight / level.height,
              );
              return Center(
                child: SizedBox(
                  width: cell * level.width,
                  height: cell * level.height,
                  child: Stack(
                    children: [
                      for (var y = 0; y < level.height; y++)
                        for (var x = 0; x < level.width; x++)
                          Positioned(
                            left: x * cell,
                            top: y * cell,
                            width: cell - 1,
                            height: cell - 1,
                            child: _tile(Cell(x, y)),
                          ),
                      for (final goal in level.goals) ...[
                        if (level.chapter == 1) ...[
                          _sprite(
                            goal,
                            cell,
                            'a32c681a-86c5-47b4-9e8c-87b6bba0d5b3.svg',
                            26.5,
                            26.5,
                            5,
                            5,
                          ),
                          _sprite(
                            goal,
                            cell,
                            '6cd820ee-79f4-4a27-98a7-3ad94f1cf657.svg',
                            21.5,
                            21.5,
                            7.5,
                            7.5,
                          ),
                          _sprite(
                            goal,
                            cell,
                            '5ba00784-5873-4ba3-905a-f35d6e01a722.svg',
                            16.5,
                            16.5,
                            10,
                            10,
                          ),
                        ] else ...[
                          _sprite(
                            goal,
                            cell,
                            '88c0a14e-6076-450e-a544-c61b9ad413ef.svg',
                            26.25,
                            26.25,
                            5.625,
                            5.625,
                          ),
                          _sprite(
                            goal,
                            cell,
                            '112bd40b-123b-4e50-884d-9bcf8bcce401.svg',
                            12,
                            15.375,
                            12.75,
                            10.5,
                          ),
                        ],
                      ],
                      if (level.chapter == 1) ...[
                        _sprite(
                          board.player,
                          cell,
                          '1c475daa-f022-49a0-9351-a82dc0e4cf1b.svg',
                          25,
                          6,
                          6,
                          27.5,
                          identity: 'shadow',
                        ),
                        _sprite(
                          board.player,
                          cell,
                          '93cb8a01-c3bd-4510-8700-e050e55cfad2.svg',
                          26,
                          28,
                          5.5,
                          3,
                          identity: 'player',
                        ),
                      ] else
                        _sprite(
                          board.player,
                          cell,
                          level.chapter == 2
                              ? 'd8107196-8a0a-4e8a-b85e-f6004bfbfc35.svg'
                              : '04e56f67-be54-4f13-bdcc-6edea0439f01.svg',
                          29.625,
                          29.625,
                          3.9375,
                          3.9375,
                          identity: 'player',
                        ),
                      for (final crate in board.crates)
                        _sprite(
                          crate,
                          cell,
                          level.chapter == 1
                              ? '7ef2a194-810a-4a1a-af56-ac44566b1f90.svg'
                              : level.chapter == 2
                              ? '6fa4498a-bb18-410e-bf8c-0fa2409024fd.svg'
                              : '2e68db95-40d9-4495-965d-bc44f2cf1515.svg',
                          level.chapter == 1 ? 27.5 : 29.625,
                          level.chapter == 1 ? 25 : 29.625,
                          level.chapter == 1 ? 4.5 : 3.9375,
                          level.chapter == 1 ? 6 : 3.9375,
                          identity: 'crate-${_crateIds[crate]}',
                          feedback: _crateIds[crate] == _pushedId,
                        ),
                      for (final crate in board.crates.where(
                        level.goals.contains,
                      ))
                        Positioned(
                          left: (crate.x + .6) * cell,
                          top: (crate.y + .6) * cell,
                          width: cell * .34,
                          height: cell * .34,
                          child: FadeTransition(
                            opacity:
                                _crateIds[crate] == _pushedId && !_reducedMotion
                                ? _feedback.drive(
                                    CurveTween(curve: const Interval(.6, 1)),
                                  )
                                : const AlwaysStoppedAnimation(1.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xff172c23),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xffeacb80),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(1),
                                child: SvgPicture.asset(
                                  '${_path}50587ef6-bd56-40db-ad63-c7257fc03c23.svg',
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _sprite(
    Cell p,
    double cell,
    String asset,
    double w,
    double h,
    double x,
    double y, {
    String? identity,
    bool feedback = false,
  }) {
    final scale = cell / 37.5;
    Widget sprite = SvgPicture.asset('$_path$asset');
    if (feedback && !_reducedMotion && widget.animate) {
      sprite = PushFeedback(
        progress: _feedback,
        direction: _pushDirection,
        onGoal: level.goals.contains(p),
        child: sprite,
      );
    }
    final left = p.x * cell + x * scale;
    final top = p.y * cell + y * scale;
    if (identity == null) {
      return Positioned(
        left: left,
        top: top,
        width: w * scale,
        height: h * scale,
        child: sprite,
      );
    }
    return AnimatedPositioned(
      key: ValueKey(identity),
      duration: _reducedMotion || !widget.animate
          ? Duration.zero
          : FigmaBoard.slideDuration,
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: w * scale,
      height: h * scale,
      child: sprite,
    );
  }

  Widget _tile(Cell p) {
    final wall = level.walls.contains(p);
    if (level.chapter > 1) {
      final ruins = level.chapter == 2;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: wall
              ? Color(ruins ? 0xff719293 : 0xff92809f)
              : Color(
                  ruins
                      ? ((p.x + p.y).isEven ? 0xff263d45 : 0xff304b52)
                      : ((p.x + p.y).isEven ? 0xff3a2c43 : 0xff49364f),
                ),
          border: wall
              ? const Border(
                  top: BorderSide(color: Color(0xffa3ad9d), width: 2),
                )
              : null,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wall
            ? null
            : Color((p.x + p.y).isEven ? 0xff526f4e : 0xff4d694b),
        gradient: wall
            ? const LinearGradient(
                colors: [Color(0xff72877a), Color(0xff486154)],
              )
            : null,
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: wall
          ? Stack(
              children: [
                Positioned(
                  left: 3,
                  right: 3,
                  top: 21.5,
                  height: 1,
                  child: const ColoredBox(color: Color(0xff3c594c)),
                ),
                Positioned(
                  left: 3.5,
                  right: 3.5,
                  top: 3.5,
                  height: 2,
                  child: const ColoredBox(color: Color(0xff95a08a)),
                ),
                Positioned(
                  left: 6,
                  top: 3.5,
                  width: 8.5,
                  height: 2.5,
                  child: const ColoredBox(color: Color(0xff94ad68)),
                ),
                Positioned(
                  left: 14.5,
                  top: 3.5,
                  width: 4,
                  height: 1.5,
                  child: const ColoredBox(color: Color(0xff7d9c58)),
                ),
              ],
            )
          : const Stack(
              children: [
                Positioned(
                  left: 10,
                  top: 20,
                  width: 4.5,
                  height: 1,
                  child: ColoredBox(color: Color(0xff759267)),
                ),
              ],
            ),
    );
  }
}
