import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../domain/puzzle.dart';
import '../viewmodels/campaign_view_model.dart';
import 'board_view.dart';
import 'forest_theme.dart';

enum _Page { home, levels, game, guide }

class CampaignApp extends StatefulWidget {
  const CampaignApp({super.key, required this.model});
  final CampaignViewModel model;
  @override
  State<CampaignApp> createState() => _CampaignAppState();
}

class _CampaignAppState extends State<CampaignApp> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  _Page _page = _Page.home;
  CampaignViewModel get vm => widget.model;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(vm.pause());
  }

  Future<void> _home() async {
    await vm.pause();
    if (mounted) setState(() => _page = _Page.home);
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: _navigator.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _start(Level level) async {
    if (vm.hasSave &&
        !await _confirm(
          'Replace saved campaign?',
          'Your unfinished board will be replaced. Completed levels and personal bests are kept.',
          'Start level',
        )) {
      return;
    }
    await vm.start(level);
    if (mounted && vm.error == null) setState(() => _page = _Page.game);
  }

  Future<void> _restart() async {
    await vm.pause();
    if (!mounted) return;
    final confirmed = await _confirm(
      'Restart this level?',
      'Reset the board, Steps, active time, and Undo history?',
      'Restart',
    );
    if (confirmed) {
      await vm.restart();
    } else {
      vm.resume();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    title: 'Forest Sokoban: The Lost Seeds',
    theme: forestTheme(),
    debugShowCheckedModeBanner: false,
    home: Builder(
      builder: (context) => ListenableBuilder(
        listenable: vm,
        builder: (context, _) => PopScope(
          canPop: _page == _Page.home,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) unawaited(_home());
          },
          child: Scaffold(
            body: ForestBackdrop(
              child: SafeArea(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.levels.isEmpty
                    ? _startupError()
                    : switch (_page) {
                        _Page.home => _homeView(),
                        _Page.levels => _levelView(),
                        _Page.game => _gameView(),
                        _Page.guide => _guideView(),
                      },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _startupError() => Center(
    child: ForestPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(vm.error ?? 'Game data is unavailable.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: vm.initialize, child: const Text('Retry')),
        ],
      ),
    ),
  );

  Widget _menu(String title, Widget child) => Padding(
    padding: const EdgeInsets.all(16),
    child: ForestPanel(
      padding: 16,
      child: Column(
        children: [
          Row(
            children: [
              if (_page != _Page.home)
                IconButton(
                  onPressed: _home,
                  tooltip: 'Home',
                  icon: const Icon(Icons.home_outlined),
                ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    ),
  );

  Widget _homeView() => _menu(
    'FOREST SOKOBAN',
    ListView(
      children: [
        const Text(
          'THE LOST SEEDS',
          style: TextStyle(
            fontSize: 22,
            letterSpacing: 2,
            color: gold,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Restore a quiet forest, one thoughtful move at a time.'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _menuButton(
              'Campaign',
              Icons.map_outlined,
              () => setState(() => _page = _Page.levels),
            ),
            _menuButton(
              'Continue',
              Icons.play_arrow,
              vm.hasSave
                  ? () {
                      setState(() => _page = _Page.game);
                    }
                  : null,
            ),
            _menuButton(
              'Guide',
              Icons.menu_book_outlined,
              () => setState(() => _page = _Page.guide),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('${vm.completed.length}/12 levels restored  ·  Offline campaign'),
        if (!vm.hasSave)
          const Text(
            'No unfinished campaign',
            style: TextStyle(color: Color(0xFFCBD8BB)),
          ),
        if (vm.corruptSave) ...[
          const SizedBox(height: 12),
          const Text(
            'The saved board is incompatible or damaged. Your completed levels are kept.',
          ),
          TextButton(
            onPressed: () async {
              if (await _confirm(
                'Discard damaged save?',
                'Only the unfinished campaign save will be removed.',
                'Discard',
              )) {
                await vm.discardCorruptSave();
              }
            },
            child: const Text('Discard unfinished save'),
          ),
        ],
        if (vm.error != null)
          Text(vm.error!, style: const TextStyle(color: gold)),
      ],
    ),
  );

  Widget _menuButton(String label, IconData icon, VoidCallback? action) =>
      SizedBox(
        width: 180,
        child: FilledButton.icon(
          onPressed: vm.busy ? null : action,
          icon: Icon(icon),
          label: Text(label),
        ),
      );

  Widget _levelView() => _menu(
    'World map',
    ListView(
      children: [
        for (var chapter = 1; chapter <= 3; chapter++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'CH-0$chapter · ${chapterNames[chapter - 1]}',
              style: const TextStyle(
                fontSize: 18,
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!vm.unlocked(chapter))
            Text(
              chapter == 2
                  ? 'Complete L01–L05 to enter the ruins.'
                  : 'Complete L01–L09 to reach the Ancient Tree.',
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final level in vm.levels.where((l) => l.chapter == chapter))
                SizedBox(
                  width: 178,
                  child: FilledButton(
                    onPressed: vm.unlocked(chapter) && !vm.busy
                        ? () => _start(level)
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              vm.completed.contains(level.key)
                                  ? Icons.check_circle_outline
                                  : vm.unlocked(chapter)
                                  ? Icons.spa_outlined
                                  : Icons.lock_outline,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(level.id),
                          ],
                        ),
                        Text(level.name, textAlign: TextAlign.center),
                        if (vm.progress[level.key] case final score?)
                          Text(
                            '${score.steps} Steps · ${formatTime(score.elapsedMs)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _guideView() => _menu(
    'Guardian’s guide',
    ListView(
      children: const [
        _GuideEntry(
          Icons.open_with,
          'Move one cell',
          'Tap the direction buttons. You can also use arrow keys or WASD on a keyboard.',
        ),
        _GuideEntry(
          Icons.inventory_2_outlined,
          'Push Light Seeds',
          'Push one crate onto each diamond altar. You cannot pull crates or push two at once.',
        ),
        _GuideEntry(
          Icons.undo,
          'Undo costs one Step',
          'A legal move or push adds one Step. Undo restores the previous board and also adds '
              'one Step. Blocked taps add nothing. Undo never rewinds active time.',
        ),
        _GuideEntry(
          Icons.restart_alt,
          'Escape a deadlock',
          'A crate in a corner without an altar can become stuck. Undo or confirm Restart '
              'to try again. Restart resets Steps and time.',
        ),
        _GuideEntry(
          Icons.pause,
          'Take a break',
          'Pause or leave the app to freeze active time. Continue restores the saved board '
              'paused. One unfinished campaign is kept on this device.',
        ),
        _GuideEntry(
          Icons.forest_outlined,
          'Restore all three chapters',
          'Complete the first five levels to unlock Forgotten Ruins, then the first nine '
              'to unlock Heart of the Forest. Choose any order within an unlocked chapter.',
        ),
      ],
    ),
  );

  Widget _gameView() {
    final level = vm.level!;
    final attempt = vm.attempt!;
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CH-0${level.chapter} · ${chapterNames[level.chapter - 1]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: gold, fontSize: 12),
                      ),
                      Text(
                        '${level.id} · ${level.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _metric('Steps', '${attempt.steps}'),
                const SizedBox(width: 12),
                _metric(
                  'Time',
                  formatTime(vm.solved ? attempt.elapsedMs : vm.elapsedMs),
                ),
                IconButton(
                  onPressed: vm.busy
                      ? null
                      : () => vm.paused ? vm.resume() : vm.pause(),
                  tooltip: vm.paused ? 'Resume' : 'Pause',
                  icon: Icon(vm.paused ? Icons.play_arrow : Icons.pause),
                ),
                IconButton(
                  onPressed: _home,
                  tooltip: 'Home',
                  icon: const Icon(Icons.home_outlined),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 144, child: Center(child: _dpad())),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BoardView(level: level, board: attempt.board),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 88,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              onPressed:
                                  !vm.paused &&
                                      !vm.busy &&
                                      !vm.solved &&
                                      attempt.history.isNotEmpty
                                  ? vm.undo
                                  : null,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.all(6),
                              ),
                              child: const Text('Undo'),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: vm.busy || vm.solved ? null : _restart,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.all(6),
                              ),
                              child: const Text('Restart'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (vm.paused || vm.error != null || vm.solved)
                    Positioned.fill(
                      child: ColoredBox(
                        color: const Color(0xBB102A25),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(8),
                            child: ForestPanel(
                              padding: 14,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 390,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      vm.solved
                                          ? 'Grove restored!'
                                          : vm.error != null
                                          ? 'Save interrupted'
                                          : 'Paused',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        color: gold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      vm.error ??
                                          (vm.solved
                                              ? '${attempt.steps} Steps · ${formatTime(attempt.elapsedMs)}\nSaved on this device.'
                                              : 'Your board is saved. Resume when you are ready.'),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        if (vm.error != null)
                                          FilledButton(
                                            onPressed: vm.busy
                                                ? null
                                                : vm.retrySave,
                                            child: const Text('Retry save'),
                                          )
                                        else if (!vm.solved)
                                          FilledButton(
                                            onPressed: vm.busy
                                                ? null
                                                : vm.resume,
                                            child: const Text('Resume'),
                                          ),
                                        if (vm.solved) ...[
                                          FilledButton(
                                            onPressed: vm.busy
                                                ? null
                                                : vm.restart,
                                            child: const Text('Replay'),
                                          ),
                                          FilledButton(
                                            onPressed: () => setState(
                                              () => _page = _Page.levels,
                                            ),
                                            child: const Text('World map'),
                                          ),
                                        ],
                                        TextButton(
                                          onPressed: _home,
                                          child: const Text('Home'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                vm.feedback,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: gold)),
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _dpad() {
    Widget direction(Direction direction, IconData icon) => SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filledTonal(
        onPressed: vm.paused || vm.busy || vm.solved
            ? null
            : () => vm.move(direction),
        tooltip: 'Move ${direction.name}',
        icon: Icon(icon),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF705735),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        direction(Direction.up, Icons.arrow_upward),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            direction(Direction.left, Icons.arrow_back),
            direction(Direction.down, Icons.arrow_downward),
            direction(Direction.right, Icons.arrow_forward),
          ],
        ),
      ],
    );
  }
}

String formatTime(int ms) {
  final seconds = ms ~/ 1000;
  return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
}

class _GuideEntry extends StatelessWidget {
  const _GuideEntry(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 6),
    leading: Icon(icon, color: gold),
    title: Text(title),
    subtitle: Text(body),
  );
}
