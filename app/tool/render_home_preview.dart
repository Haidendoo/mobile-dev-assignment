// Run from app/: flutter test tool/render_home_preview.dart --no-pub
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forest_sokoban/ui/campaign_app.dart';
import 'package:forest_sokoban/viewmodels/campaign_view_model.dart';

import '../test/support.dart';

void main() {
  testWidgets('render the saved-L01 Home at the Figma reference size', (
    tester,
  ) async {
    for (final entry in {
      'CormorantGaramond': [
        'assets/fonts/CormorantGaramond.ttf',
        'assets/fonts/CormorantGaramond-Italic.ttf',
      ],
      'DMSans': ['assets/fonts/DMSans.ttf'],
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
    final model = CampaignViewModel(MemoryRepository(), automaticTimer: false);
    addTearDown(model.dispose);
    await model.initialize();
    await model.start(model.levels.first);
    await model.pause();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CampaignApp(model: model),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        const output = String.fromEnvironment(
          'HOME_PREVIEW_OUTPUT',
          defaultValue: '../docs/a02/home-continue-figma.png',
        );
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  });
}
