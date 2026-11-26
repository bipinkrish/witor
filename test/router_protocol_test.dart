import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:witor/router/router.dart';
import 'package:witor/diagnostics/network_probe.dart';

void main() {
  test('gateway ping distinguishes dropped packets from an unavailable tool', () {
    final ping = NetworkProbe.parsePing(
      '64 bytes from gateway: time=2.34 ms\n2 packets transmitted, 1 received, 50% packet loss',
    );
    expect(ping?.samples, [2.34]);
    expect(ping?.loss, 50);
    expect(NetworkProbe.parsePing('permission denied'), isNull);
  });

  test(
    'a rejected router login stops after the submitted credentials',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final attempts = <Object?>[];
      final client = HttpClient()
        ..connectionFactory = (_, _, _) =>
            Socket.startConnect(InternetAddress.loopbackIPv4, server.port);
      final router = RouterSession('192.168.1.1', https: false, client: client);
      server.listen((request) async {
        final payload = jsonDecode(await utf8.decoder.bind(request).join());
        attempts.add((payload['params'] as List).skip(1).toList());
        request.response.write(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'result': [6],
          }),
        );
        await request.response.close();
      });
      try {
        await expectLater(
          router.openWrtRadios('owner', 'entered-on-label'),
          throwsA(isA<HttpException>()),
        );
        expect(attempts, [
          [
            'session',
            'login',
            {'username': 'owner', 'password': 'entered-on-label'},
          ],
        ]);
      } finally {
        router.close();
        await server.close(force: true);
      }
    },
  );

  test(
    'authorized OpenWrt read uses a single login, reads only allowed fields and closes the session',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final methods = <String>[];
      final seen = <DateTime>[];
      final client = HttpClient()
        ..connectionFactory = (_, _, _) =>
            Socket.startConnect(InternetAddress.loopbackIPv4, server.port);
      final router = RouterSession('192.168.1.1', https: false, client: client);
      server.listen((req) async {
        final call =
            jsonDecode(await utf8.decoder.bind(req).join())['params'] as List;
        final method = '${call[1]}.${call[2]}';
        methods.add(method);
        seen.add(DateTime.now());
        final value = switch (method) {
          'session.login' => {'ubus_rpc_session': 'fixture-token'},
          'system.board' => {
            'model': 'Test router',
            'release': {'revision': 'fixture'},
          },
          'uci.get' => {
            'values': {
              'ap': {
                '.type': 'wifi-iface',
                'ssid': 'Home',
                'key': 'discard-this',
              },
            },
          },
          'network.interface.wan.status' => {
            'ipv4-address': [
              {'address': '10.0.0.2'},
            ],
          },
          'iwinfo.devices' => {
            'devices': ['wlan0'],
          },
          'iwinfo.scan' => {
            'results': [
              {
                'ssid': 'Neighbour',
                'bssid': '02:00:00:00:00:02',
                'channel': 6,
                'mhz': 2437,
                'signal': -54,
              },
            ],
          },
          'iwinfo.assoclist' => {
            'results': [
              {'mac': '02:00:00:00:00:03'},
            ],
          },
          'session.destroy' => {},
          _ => throw StateError(method),
        };
        req.response.write(
          jsonEncode({
            'id': 1,
            'jsonrpc': '2.0',
            'result': [0, value],
          }),
        );
        await req.response.close();
      });
      try {
        final radios = await router.openWrtRadios(
          'subscriber',
          'fixture',
          includeSurvey: true,
        );
        expect(radios, [
          {'Network': 'Home'},
        ]);
        expect(router.survey?.nearby.single['frequency'], 2437);
        expect(router.survey?.privateWan, true);
        expect(router.survey?.clientCount, 1);
        expect(methods.where((m) => m == 'session.login'), hasLength(1));
        expect(methods.last, 'session.destroy');
        for (var i = 1; i < seen.length; ++i) {
          expect(
            seen[i].difference(seen[i - 1]).inMilliseconds,
            greaterThanOrEqualTo(825),
          );
        }
      } finally {
        router.close();
        await server.close(force: true);
      }
    },
  );
}
