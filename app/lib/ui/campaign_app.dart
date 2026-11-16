import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/puzzle.dart';
import '../viewmodels/campaign_view_model.dart';
import 'figma_board.dart';
import 'figma_dialog.dart';
import 'figma_home.dart';
import 'figma_scene.dart';
import 'forest_theme.dart';

class CampaignApp extends StatefulWidget {
  const CampaignApp({super.key, required this.model});
  final CampaignViewModel model;
  @override
  State<CampaignApp> createState() => _CampaignAppState();
}

class _CampaignAppState extends State<CampaignApp> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  String _page = 'home';
  String _leaderboardLevel = 'L01';
  bool _confirmingRestart = false;
  bool _recoveryShown = false;
  Timer? _winTimer;
  String? _winningAttempt;
  bool _winVisible = false;
  CampaignViewModel get vm => widget.model;
  bool get _playing => _page == 'game';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    vm.addListener(_observeWin);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    vm.removeListener(_observeWin);
    _winTimer?.cancel();
    super.dispose();
  }

  void _observeWin() {
    if (!vm.solved) {
      _winTimer?.cancel();
      _winTimer = null;
      _winningAttempt = null;
      _winVisible = false;
      return;
    }
    final id = vm.attempt!.id;
    if (_winningAttempt == id) return;
    _winningAttempt = id;
    if (MediaQuery.disableAnimationsOf(_navigator.currentContext ?? context)) {
      _winVisible = true;
      return;
    }
    // The score is already committed. Only its presentation waits for the push.
    _winTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && vm.solved && vm.attempt!.id == id) {
        setState(() => _winVisible = true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(vm.pause());
  }

  void _go(String page) {
    if (_playing) unawaited(vm.pause());
    setState(() => _page = page);
    if (page == '7-12213' && vm.corruptSave && !_recoveryShown) {
      _recoveryShown = true;
      unawaited(_recoverSave());
    }
  }

  Future<void> _recoverSave() async {
    if (await _confirm(
      'Saved game unavailable',
      'The unfinished save is damaged or incompatible. Discard it? Completed levels and personal bests are kept.',
      'Discard save',
    )) {
      await vm.discardCorruptSave();
      if (mounted && vm.error != null) _unavailable(vm.error);
    }
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showGeneralDialog<bool>(
        context: _navigator.currentContext!,
        barrierLabel: 'Cancel',
        barrierDismissible: false,
        barrierColor: const Color(0xc7091711),
        pageBuilder: (context, _, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FigmaDialog(
              title: title,
              body: body,
              action: action,
              onConfirm: () => Navigator.pop(context, true),
              onCancel: () => Navigator.pop(context, false),
            ),
          ),
        ),
      ) ??
      false;

  Future<void> _start(Level level) async {
    if (vm.busy || !vm.unlocked(level.chapter)) return;
    if (vm.hasSave &&
        !await _confirm(
          'Replace saved campaign?',
          'Replace the unfinished board? Completed levels and personal bests are kept.',
          'Start level',
        )) {
      return;
    }
    await vm.start(level);
    if (!mounted) return;
    if (vm.error == null) {
      setState(() => _page = 'game');
    } else {
      _unavailable(vm.error);
    }
  }

  Future<void> _restart() async {
    setState(() => _confirmingRestart = true);
    await vm.pause();
    if (!mounted) return;
    final confirmed = await _confirm(
      'Restart level?',
      'Start ${vm.level!.name} over?',
      'Restart',
    );
    if (confirmed) {
      await vm.restart();
    } else {
      vm.resume();
    }
    if (mounted) setState(() => _confirmingRestart = false);
  }

  void _unavailable([String? feature]) {
    _messenger.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            feature ?? 'Online services are not configured in this build. Your offline progress is kept.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _action(String action) {
    if (action.startsWith('L') && RegExp(r'^L\d{2}\s').hasMatch(action)) {
      if (_page == '24-14302') {
        _leaderboardLevel = action.substring(0, 3);
        _go('24-14544');
      } else {
        unawaited(
          _start(vm.levels.firstWhere((l) => l.id == action.substring(0, 3))),
        );
      }
      return;
    }
    switch (action) {
      case 'Play':
      case 'Chapters':
      case 'Campaign':
      case 'World Map':
      case 'Levels':
        _go('13-103');
      case 'More':
        _go('7-12213');
      case 'Home':
      case 'Play from Home  →':
        _go('home');
      case 'Back':
        _go(switch (_page) {
          '7-12213' => 'home',
          '24-14302' => '24-14544',
          '24-14890' => '7-14068',
          '13-1402' || '13-1408' || '24-14562' => '13-1397',
          _ => '7-12213',
        });
      case 'The Awakening':
        _openChapter(1);
      case 'Forgotten Ruins':
        _openChapter(2);
      case 'Heart of the Forest':
        _openChapter(3);
      case 'How to Play':
        _go('7-14068');
      case 'More rules':
        _go('24-14890');
      case 'Swipe gameplay':
        unawaited(_start(vm.levels[1]));
      case 'Try First Steps':
        unawaited(_start(vm.levels.first));
      case 'Story Archive':
      case 'Story Archive  →':
        _go('13-137');
      case 'Profile':
        _go('13-1305');
      case 'Link email':
        _go('13-1325');
      case 'Sign in':
        _go('13-1361');
      case 'Cancel':
        _go(_page == '13-1325' || _page == '13-1361' ? '13-1305' : '13-1397');
      case 'Challenge':
      case 'Challenge 1v1':
        _go('13-1397');
      case 'Create room':
        _go('13-1402');
      case 'Join room':
        _go('13-1408');
      case 'My Rooms':
        _go('24-14562');
      case 'Leaderboard':
        _go('24-14544');
      case 'Choose level':
        _go('24-14302');
      case 'Settings':
      case 'Audio settings':
        _go('13-1219');
      case 'PoC Overview':
        _go('16-89');
      case 'Pause':
        unawaited(vm.pause());
      case 'Restart':
        unawaited(_restart());
      case 'Undo':
        unawaited(vm.undo());
      case 'Resume':
        vm.resume();
      case 'Replay':
        unawaited(vm.restart());
      case 'Next level':
        final index = vm.levels.indexOf(vm.level!) + 1;
        if (index < vm.levels.length && vm.unlocked(vm.levels[index].chapter)) {
          unawaited(_start(vm.levels[index]));
        } else {
          _go('13-103');
        }
      case 'Music':
      case 'Sound effects':
        _unavailable('Audio playback is not implemented in this build.');
      case 'The Awakening · Intro':
      case 'Preview ending':
      case 'Ending · Locked':
        _unavailable('Story scenes are not implemented in this build.');
      default:
        _unavailable();
    }
  }

  void _openChapter(int chapter) {
    _go(
      vm.unlocked(chapter)
          ? ['23-159', '23-193', '23-222'][chapter - 1]
          : chapter == 2
          ? '13-125'
          : '13-131',
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    scaffoldMessengerKey: _messenger,
    title: 'Forest Sokoban: The Lost Seeds',
    theme: forestTheme(),
    debugShowCheckedModeBanner: false,
    home: ListenableBuilder(
      listenable: vm,
      builder: (context, _) => PopScope(
        canPop: _page == 'home',
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _go('home');
        },
        child: Scaffold(
          body: DecoratedBox(
            decoration: figmaHomeBackground,
            child: SafeArea(
              child: vm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.levels.isEmpty
                  ? Center(
                      child: FigmaDialog(
                        title: 'Unable to start',
                        body: vm.error ?? 'Game data is unavailable.',
                        action: 'Retry',
                        onConfirm: vm.initialize,
                        onCancel: () {},
                      ),
                    )
                  : _view(),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _view() {
    if (_page == 'home') {
      return vm.hasSave
          ? FigmaHome(
              savedLevelName: vm.level?.name,
              onContinue: vm.busy ? null : () => _go('game'),
              onMore: vm.busy ? null : () => _go('7-12213'),
            )
          : FigmaScene(scene: '7-11079', onAction: _action);
    }
    if (_playing) return _gameView();
    return FigmaScene(
      scene: _page,
      onAction: _action,
      text: _sceneText(),
      labels: _page == '24-14302'
          ? {
              for (var i = 0; i < vm.levels.length; i++)
                '24:${14356 + 2 * i}':
                    '${vm.levels[i].id} / v${vm.levels[i].version}',
            }
          : const {},
    );
  }

  Map<String, String> _sceneText() {
    if (_page == '13-103') {
      return {
        '38:89997': vm.unlocked(2) ? 'Explore  →' : 'Locked',
        '38:90021': vm.unlocked(3) ? 'Explore  →' : 'Locked',
      };
    }
    if (const {'23-159', '23-193', '23-222'}.contains(_page)) {
      const ids = [
        '38:89511',
        '38:89526',
        '38:89544',
        '38:89562',
        '38:89583',
        '38:89693',
        '38:89711',
        '38:89729',
        '38:89750',
        '38:89853',
        '38:89874',
        '38:89895',
      ];
      return {
        for (var i = 0; i < vm.levels.length; i++)
          if (vm.progress[vm.levels[i].key] case final score?)
            ids[i]: 'Best ${score.steps} · ${formatTime(score.elapsedMs)}'
          else if (i >= 2)
            ids[i]: '${vm.levels[i].initial.crates.length} pieces',
      };
    }
    if (_page == '24-14544') {
      return {
        '24:14546': 'Casual · Unverified · $_leaderboardLevel',
        '24:14548': 'Online services are not configured. No cached rankings.',
      };
    }
    if (_page == '24-14302') {
      return {
        for (var i = 0; i < vm.levels.length; i++)
          '24:${14357 + 2 * i}':
              '${vm.levels[i].id} / v${vm.levels[i].version}',
      };
    }
    if (_page == '13-1408') {
      return {
        '13:1413': 'Online services are not configured.',
        '13:1465': 'Unavailable',
      };
    }
    if (_page == '13-1402') {
      return {
        '13:1407': 'Online services are not configured.',
        '25:8783': '03   Two Deliveries · v1',
      };
    }
    if (_page == '13-137') {
      return {'13:142': 'Story scenes are not implemented in this build.'};
    }
    if (_page == '24-14562') {
      return {'24:14566': 'Online rooms are not available in this build.'};
    }
    if (_page == '13-1325' || _page == '13-1361') {
      return {
        _page == '13-1325' ? '13:1330' : '13:1366':
            'Email services are not configured.',
        _page == '13-1325' ? '13:1338' : '13:1374': 'Email unavailable',
      };
    }
    if (_page == '16-89') {
      return {
        '16:122': 'Offline campaign build · Online services pending',
        '16:110': 'Online services pending',
        '16:114': 'Guest · Email services pending',
        '16:106': 'Online services pending',
      };
    }
    return {};
  }

  Widget _gameView() {
    final level = vm.level!;
    final attempt = vm.attempt!;
    if (vm.solved && _winVisible) {
      final best = vm.progress[level.key];
      return FigmaScene(
        scene: '7-11999',
        onAction: _action,
        hidden:
            best?.steps == attempt.steps && best?.elapsedMs == attempt.elapsedMs
            ? const {}
            : {'Personal best chip', '7:12202', '7:12204'},
        text: {
          '7:12193':
              'LEVEL ${level.id.substring(1)} · ${level.name.toUpperCase()}',
          '7:12197': '${attempt.steps}',
          '7:12200': formatTime(attempt.elapsedMs),
          '7:12212': 'Saved on this device · Score awaiting upload',
        },
      );
    }
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final direction = {
          LogicalKeyboardKey.arrowUp: Direction.up,
          LogicalKeyboardKey.keyW: Direction.up,
          LogicalKeyboardKey.arrowDown: Direction.down,
          LogicalKeyboardKey.keyS: Direction.down,
          LogicalKeyboardKey.arrowLeft: Direction.left,
          LogicalKeyboardKey.keyA: Direction.left,
          LogicalKeyboardKey.arrowRight: Direction.right,
          LogicalKeyboardKey.keyD: Direction.right,
        }[event.logicalKey];
        if (direction != null) {
          unawaited(vm.move(direction));
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyU) {
          unawaited(vm.undo());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          if (level.chapter > 1)
            _laterChapterGame()
          else
            FigmaScene(
              scene: '7-11289',
              onAction: _action,
              colors: {
                '7:11637': Color(
                  attempt.history.isEmpty ? 0xffa0b09d : 0xfffff1d2,
                ),
              },
              hidden: const {'Drag board to demonstrate right swipe'},
              text: {
                '7:11471': 'LEVEL ${level.id.substring(1)}',
                '7:11472': level.name,
                '7:11474': '${attempt.steps}',
                '7:11476': formatTime(vm.elapsedMs),
              },
              replacements: {
                'First Steps · Swipe region': FigmaBoard(
                  key: ValueKey(attempt.id),
                  animate: !vm.paused || vm.solved,
                  level: level,
                  board: attempt.board,
                  onMove: (d) => unawaited(vm.move(d)),
                ),
              },
              enabled: {
                'Pause': !vm.busy,
                'Restart': !vm.busy,
                'Undo': !vm.paused && !vm.busy && attempt.history.isNotEmpty,
              },
            ),
          if ((vm.paused && !_confirmingRestart && !vm.solved) ||
              vm.error != null)
            Positioned.fill(
              child: FigmaScene(
                scene: '7-12632',
                dialogOnly: true,
                onAction: (action) {
                  if (action == 'Resume' && vm.error != null) {
                    unawaited(vm.retrySave());
                  } else {
                    _action(action);
                  }
                },
                text: {
                  '7:12991': vm.error != null ? 'Save interrupted' : 'Paused',
                  '7:12992': vm.error != null
                      ? 'Your last saved board is preserved.'
                      : level.name,
                  '7:16440': vm.error != null ? 'Retry save' : 'Resume',
                },
                enabled: {'Resume': !vm.busy},
              ),
            ),
        ],
      ),
    );
  }

  Widget _laterChapterGame() {
    final level = vm.level!;
    final attempt = vm.attempt!;
    final ruins = level.chapter == 2;
    return FigmaScene(
      scene: ruins ? '23-110' : '23-138',
      onAction: _action,
      hidden: ruins
          ? const {
              'Rune Stone 1',
              'Rune Stone 2',
              'Rune Stone 3',
              'Ruin Owl',
              'Swipe →',
            }
          : const {
              'Hollow Stump 1',
              'Hollow Stump 2',
              'Hollow Stump 3',
              'Hollow Stump 4',
              'Heartwood Fox',
              'Swipe ↑',
            },
      replacements: {
        ruins ? 'Classic board L06 v4' : 'Classic board L10 v4': FigmaBoard(
          key: ValueKey(attempt.id),
          animate: !vm.paused || vm.solved,
          level: level,
          board: attempt.board,
          onMove: (d) => unawaited(vm.move(d)),
        ),
      },
      text: {
        ruins ? '24:2718' : '24:8416':
            'LEVEL ${level.id.substring(1)}  /  V${level.version}',
        ruins ? '24:2719' : '24:8417': level.name,
        ruins ? '24:2750' : '24:8466': 'Steps ${attempt.steps}',
        ruins ? '27:8672' : '27:8676': 'Time  ${formatTime(vm.elapsedMs)}',
        ruins ? '38:90261' : '38:90281':
            '${attempt.board.crates.where(level.goals.contains).length} / ${level.goals.length}',
      },
      enabled: {
        'Pause': !vm.busy,
        'Restart': !vm.busy,
        'Undo': !vm.busy && attempt.history.isNotEmpty,
      },
    );
  }
}

String formatTime(int ms) {
  final seconds = ms ~/ 1000;
  return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
}
