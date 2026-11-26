import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:witor/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('checks the connection and refreshes after an error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'remember': false,
      'detailed': false,
    });
    const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    final messenger = tester.binding.defaultBinaryMessenger;
    const network = MethodChannel('dev.fluttercommunity.plus/network_info');
    messenger.setMockMethodCallHandler(network, (call) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(network, null));
    var attempt = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'check');
      attempt++;
      return switch (attempt) {
        1 => ['wifi'],
        2 => throw PlatformException(code: 'unavailable'),
        _ => ['none'],
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(const WitorApp());
    await tester.tap(find.text('Check connection'));
    await tester.pumpAndSettle();
    expect(
      find.text('Wi-Fi'),
      findsOneWidget,
      reason:
          'Connectivity calls: $attempt; visible: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(' / ')}',
    );

    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(
      find.text('Connection details are unavailable. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Wi-Fi'), findsNothing);

    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(find.text('No active network connection.'), findsOneWidget);
  });
}
