import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:witor/diagnostics/finding.dart';
import 'package:witor/diagnostics/report.dart';
import 'package:witor/l10n/generated/app_localizations.dart';
import 'package:witor/screens/guide_panel.dart';

void main() {
  final data =
      jsonDecode(
            File('test/fixtures/dragon_path_707gr1.json').readAsStringSync(),
          )
          as Json;
  final findings = CheckReport(data['before'] as Json).findings;
  Widget app(List<Finding> list) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: GuidePanel(familyGuide: 'Open Wireless.', findings: list),
    ),
  );
  testWidgets(
    'guide follows the measured settings and preserves progress when hidden',
    (tester) async {
      await tester.pumpWidget(app(findings));
      await tester.tap(find.text('Start steps'));
      await tester.pump();
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.textContaining('G+N or a newer mode'), findsOneWidget);
      await tester.tap(find.text('Next step'));
      await tester.pump();
      expect(find.text('Channel width'), findsOneWidget);
      await tester.tap(find.byTooltip('Hide guide'));
      await tester.pump();
      expect(find.text('Next step'), findsNothing);
      await tester.tap(find.byTooltip('Show guide'));
      await tester.pump();
      expect(find.text('Step 2 of 4'), findsOneWidget);
      await tester.tap(find.text('Next step'));
      await tester.pump();
      await tester.tap(find.text('Next step'));
      await tester.pump();
      expect(find.text('Wireless security'), findsOneWidget);
      await tester.tap(find.text('Review changes'));
      await tester.pump();
      expect(find.text('Save and recheck'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(find.text('Step 4 of 4'), findsOneWidget);
    },
  );
  testWidgets(
    'no router changes are suggested for an unrelated device finding',
    (tester) async {
      await tester.pumpWidget(
        app([const Finding('Weak signal', '-75 dBm', 'Move closer.')]),
      );
      expect(find.text('Start steps'), findsNothing);
    },
  );
  test('overlapping readings produce one step for the same setting', () {
    final steps = routerGuideSteps([...findings, ...findings]);
    expect(steps.map((f) => f.setting), RouterSetting.values);
  });
}
