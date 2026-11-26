import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:witor/diagnostics/history.dart';
import 'package:witor/diagnostics/export.dart';
import 'package:witor/diagnostics/network_probe.dart';
import 'package:witor/diagnostics/report.dart';
import 'package:witor/router/observations.dart';
import 'package:witor/router/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture =
      jsonDecode(
            File('test/fixtures/dragon_path_707gr1.json').readAsStringSync(),
          )
          as Json;
  test(
    'Dragon Path measured link and configured radio width remain distinct',
    () {
      final before = CheckReport(fixture['before'] as Json),
          after = CheckReport(fixture['after'] as Json);
      expect(before.readings['Channel width'], '20 MHz');
      expect(before.routerRadios.single['Configured width'], '40 MHz');
      expect(
        before.findings.map((f) => f.title),
        containsAll([
          'Legacy 802.11b is enabled',
          'Review the router’s security mode',
          'Review 2.4 GHz channel width',
        ]),
      );
      expect(after.findings, isEmpty);
      expect(after.metric('down'), 75);
    },
  );
  test(
    'channel planner excludes own BSSID and recommendations require evidence',
    () {
      final report = CheckReport({
        'network': 'Wi-Fi',
        'link': {'bssid': 'AA', 'ssid': 'Home', 'frequency': 2422, 'width': 40},
        'nearby': [
          {'bssid': 'aa', 'frequency': 2422, 'rssi': -20},
          for (final i in [1, 2, 3])
            {'bssid': 'n$i', 'frequency': 2412 + i * 5, 'rssi': -60},
          {'bssid': 'b', 'ssid': 'Home', 'frequency': 5180, 'rssi': -64},
        ],
      });
      expect(
        report.findings.map((f) => f.title),
        containsAll([
          'A quieter channel is available',
          'Wide channel in a busy band',
          'A 5 GHz connection is available',
        ]),
      );
      expect(CheckReport({'network': 'Wi-Fi'}).findings, isEmpty);
      expect(Radio({'frequency': 5935}).channel, 2);
      expect(Radio({'frequency': 2484}).channel, 14);
    },
  );
  test('router form exports discard passwords and unknown controls', () {
    expect(
      boaObservations({
        'band': {'text': '2.4 GHz B+G+N'},
        'chanwid': {'value': '1'},
        'pskValue': {'text': 'secret'},
        'csrftoken': 'token',
      }),
      {'Wireless mode': '2.4 GHz B+G+N', 'Configured width': '40 MHz'},
    );
    expect(
      RouterSession.summarizeWireless({
        'ap': {
          '.type': 'wifi-iface',
          'key': 'secret',
          'encryption': 'psk2',
          'ssid': 'Home',
        },
      }),
      [
        {'Network': 'Home', 'Security': 'psk2'},
      ],
    );
    expect(
      RouterFamily.identify('Boa/0.93.15', '<title>Router</title>'),
      RouterFamily.boa,
    );
    expect(privateGateway('example.org'), isFalse);
    expect(privateGateway('127.0.0.1'), isFalse);
    expect(privateGateway('192.168.1.1'), isTrue);
  });
  test('PDF and JSON exports contain the before and after report', () async {
    final before = CheckReport(fixture['before'] as Json);
    final after = CheckReport(fixture['after'] as Json);
    final pdf = await reportBytes(after, before, pdf: true);
    expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
    final data = jsonDecode(
      utf8.decode(await reportBytes(after, before, pdf: false)),
    );
    expect(data['before']['readings']['Link rate'], '86 Mbps');
    expect(data['readings']['Link rate'], '115 Mbps');
  });
  test('saved checks are durable, replaceable and deletable', () async {
    final dir = await Directory.systemTemp.createTemp('witor-history-');
    final file = File('${dir.path}/checks.sqlite');
    var db = CheckHistory(NativeDatabase(file));
    try {
      final report = CheckReport(fixture['before'] as Json);
      await db.save(report);
      await db.save(report);
      await db.close();
      db = CheckHistory(NativeDatabase(file));
      expect((await db.recent()).single.findings.length, 4);
      await db.clear();
      expect(await db.recent(), isEmpty);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}
