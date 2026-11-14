import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:forest_sokoban/main.dart' as app;
import 'package:material_ui/material_ui.dart';

// Run on a clean install: flutter test integration_test -d <android-device-id>.
// The runner uses the actual Android SQLite plugin rather than an in-memory fake.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('first-install campaign can complete and replay offline', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Campaign'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First Steps'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move right'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move right'));
    await tester.pumpAndSettle();
    expect(find.text('Grove restored!'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
    await tester.pumpAndSettle();
    expect(find.text('Grove restored!'), findsNothing);
    expect(find.text('L01 · First Steps'), findsOneWidget);
  });
}
