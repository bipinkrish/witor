import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:witor/diagnostics/report.dart';
import 'package:witor/l10n/generated/app_localizations.dart';
import 'package:witor/router/router.dart';
import 'package:witor/screens/report_page.dart';

void main() {
  final data =
      jsonDecode(
            File('test/fixtures/dragon_path_707gr1.json').readAsStringSync(),
          )
          as Json;
  final before = CheckReport(data['before'] as Json);
  final after = CheckReport({
    ...data['after'] as Json,
    'gateway': '192.168.1.1',
  });

  Widget report({CheckReport? previous, bool current = true}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ReportPage(after, previous: previous, current: current),
  );
  testWidgets('report opens paired measurements and the empty admin form', (
    tester,
  ) async {
    await tester.pumpWidget(report(previous: before));
    await tester.tap(find.text('Before and after'));
    await tester.pumpAndSettle();
    expect(find.textContaining('+29 Mbps'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Router admin sign-in'));
    await tester.pumpAndSettle();
    expect(find.text('Open router sign-in'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<RouterFamily>));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('OpenWrt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenWrt').last);
    await tester.pumpAndSettle();
    final inputs = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(inputs.map((i) => i.controller!.text), ['', '']);
    expect(inputs.last.obscureText, isTrue);
  });
  testWidgets(
    'historical single check opens the baseline without admin actions',
    (tester) async {
      await tester.pumpWidget(report(current: false));
      expect(find.text('Router admin sign-in'), findsNothing);
      await tester.tap(find.text('Before and after'));
      await tester.pumpAndSettle();
      expect(find.text('Your baseline check'), findsOneWidget);
      expect(find.text('Speed comparison'), findsNothing);
    },
  );
}
