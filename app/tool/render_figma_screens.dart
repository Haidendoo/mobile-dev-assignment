// Run from app/: flutter test tool/render_figma_screens.dart --no-pub
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forest_sokoban/ui/campaign_app.dart';
import 'package:forest_sokoban/viewmodels/campaign_view_model.dart';
import 'package:forest_sokoban/data/campaign_repository.dart';

import '../test/support.dart';

void main() {
  testWidgets('render the running Figma UI migration', (tester) async {
    for (final entry in {
      'CormorantGaramond': [
        'assets/fonts/CormorantGaramond.ttf',
        'assets/fonts/CormorantGaramond-Italic.ttf',
      ],
      'DMSans': ['assets/fonts/DMSans.ttf'],
      'IBMPlexMono': ['assets/fonts/IBMPlexMono-Medium.ttf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final asset in entry.value) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = CampaignViewModel(MemoryRepository(), automaticTimer: false);
    addTearDown(vm.dispose);
    await vm.initialize();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CampaignApp(model: vm),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('../docs/a02/figma-ui-previews');
        await dir.create(recursive: true);
        await File('${dir.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> tap(String label) async {
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
    }

    await shot('home-fresh');
    await tap('More');
    await shot('more');
    await tap('Chapters');
    await shot('world-map');
    await tap('The Awakening');
    await shot('chapter-one');
    await tap('L01   First Steps');
    await shot('gameplay');
    await tap('Pause');
    await shot('pause');
    await tap('Resume');
    await tap('Restart');
    await shot('restart');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.drag(
        find.byKey(const ValueKey('puzzle-swipe')),
        const Offset(65, 0),
      );
      await tester.pumpAndSettle();
    }
    await shot('level-clear');
    await tap('Levels');
    await tap('Home');
    await tap('More');
    await tap('How to Play');
    await shot('how-to-play');
    await tap('More rules');
    await shot('rules');
    await tap('Back');
    await tap('Back');
    await tap('Profile');
    await shot('profile');
    await tap('Back');
    await tap('Settings');
    await shot('settings');
    await tap('Back');
    await tap('Leaderboard');
    await shot('leaderboard');
    vm.progress = {
      for (final level in vm.levels.take(9))
        level.key: const BestScore(2, 1000),
    };
    for (final index in [5, 9]) {
      await vm.start(vm.levels[index]);
      await vm.pause();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: CampaignApp(key: ValueKey(index), model: vm),
        ),
      );
      await tester.pumpAndSettle();
      await tap('Continue');
      await tap('Resume');
      await shot(index == 5 ? 'gameplay-ruins' : 'gameplay-heartwood');
    }
  });
}
