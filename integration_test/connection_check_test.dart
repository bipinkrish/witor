import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:witor/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads the host connection through the platform plugin', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    final retry = find.text('Check again');
    final timer = Stopwatch()..start();
    while (retry.evaluate().isEmpty &&
        timer.elapsed < const Duration(seconds: 100)) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(retry, findsOneWidget);
    expect(find.text('Check report'), findsOneWidget);
    await tester.ensureVisible(find.text('Check report'));
    await tester.tap(find.text('Check report'));
    await tester.pumpAndSettle();
    expect(find.text('Findings'), findsOneWidget);
    expect(find.text('Checking connections…'), findsNothing);
  });
}
