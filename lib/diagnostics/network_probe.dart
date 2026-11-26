import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'ndt7.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:nm/nm.dart';

import 'report.dart';

bool privateGateway(String? text) {
  final ip = InternetAddress.tryParse(text ?? '');
  if (ip == null || ip.type != InternetAddressType.IPv4) return false;
  final b = ip.rawAddress;
  return b[0] == 10 ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
      (b[0] == 192 && b[1] == 168);
}

Future<T?> _optional<T>(Future<T?> Function() work) async {
  try {
    return await work().timeout(const Duration(seconds: 5));
  } on Exception {
    return null;
  }
}

class NetworkProbe {
  static const _radio = MethodChannel('witor/wifi');
  Future<CheckReport> check({
    required bool detailed,
    required bool internet,
    required bool speed,
    String provider = 'Cloudflare',
    required void Function(String) progress,
  }) async {
    final notes = <String, String>{};
    final metrics = <String, num>{};
    progress('Reading the current connection…');
    final types = await Connectivity().checkConnectivity().timeout(
      const Duration(seconds: 10),
    );
    if (types.isEmpty) throw const FormatException('Missing connection type');
    final labels = types
        .where((v) => v != ConnectivityResult.none)
        .map(
          (v) => switch (v) {
            ConnectivityResult.wifi => 'Wi-Fi',
            ConnectivityResult.mobile => 'Mobile data',
            ConnectivityResult.ethernet => 'Ethernet',
            ConnectivityResult.vpn => 'VPN',
            ConnectivityResult.bluetooth => 'Bluetooth',
            ConnectivityResult.satellite => 'Satellite',
            _ => 'Other network',
          },
        )
        .toSet();
    final data = <String, dynamic>{
      'time': DateTime.now().toUtc().toIso8601String(),
      'network': labels.isEmpty
          ? 'No active network connection.'
          : labels.join(' · '),
      'offline': labels.isEmpty,
      'notes': notes,
      'metrics': metrics,
    };
    if (labels.isEmpty) return CheckReport(data);
    if (types.contains(ConnectivityResult.wifi)) {
      final info = NetworkInfo();
      final addresses = await Future.wait([
        _optional(info.getWifiIP),
        _optional(info.getWifiGatewayIP),
      ]);
      data['address'] = addresses[0];
      data['gateway'] = addresses[1];
      if (detailed) {
        progress('Reading Wi-Fi measurements…');
        try {
          final Json snapshot;
          if (Platform.isLinux) {
            snapshot = await _linuxRadio().timeout(const Duration(seconds: 10));
          } else {
            final raw = await _radio
                .invokeMapMethod<String, dynamic>('snapshot')
                .timeout(const Duration(seconds: 45));
            snapshot = raw ?? {};
          }
          data['link'] = snapshot['link'] ?? {};
          data['nearby'] = snapshot['nearby'] ?? [];
          if (snapshot['note'] is String) {
            notes['Nearby Wi-Fi'] = snapshot['note'];
          }
        } on Exception {
          notes['Nearby Wi-Fi'] =
              'Radio details could not be read. Check Wi-Fi and location permissions in system settings.';
        }
        final link = Json.from(data['link'] as Map? ?? {});
        if (link['ssid'] == null) {
          var ssid = await _optional(info.getWifiName);
          if (ssid != null &&
              ssid.startsWith('"') &&
              ssid.endsWith('"') &&
              ssid.length >= 2) {
            ssid = ssid.substring(1, ssid.length - 1);
          }
          if (ssid != null && ssid.isNotEmpty && ssid != '<unknown ssid>') {
            link['ssid'] = ssid;
          }
        }
        data['link'] = link;
      }
    }
    if (privateGateway(data['gateway'] as String?)) {
      progress('Measuring gateway latency…');
      final gateway = data['gateway'] as String;
      final ping = await pingGateway(gateway);
      final local = ping?.samples ?? await tcpSamples(gateway, 80, 1);
      final protocol = ping == null ? 'TCP' : 'ICMP';
      data['gatewayProtocol'] = protocol;
      if (ping != null) metrics['gatewayLoss'] = ping.loss;
      if (local.isEmpty) {
        notes['Gateway timing'] =
            'The gateway did not respond to the $protocol check.';
      } else {
        metrics['gatewayMs'] = percentile(local, .5);
        metrics['gatewayMin'] = local.reduce(math.min);
        final mean = local.reduce((a, b) => a + b) / local.length;
        metrics['gatewayMean'] = mean;
        if (local.length >= 2) {
          metrics['gatewayP95'] = percentile(local, .95);
          metrics['gatewayJitter'] = math.sqrt(
            local.fold(0.0, (s, n) => s + math.pow(n - mean, 2)) / local.length,
          );
        }
        notes['Gateway timing'] =
            '${local.length} successful $protocol sample(s).';
      }
    }
    if (internet) {
      progress('Checking DNS and internet latency…');
      final dnsTimer = Stopwatch()..start();
      final dns = await _optional(
        () => InternetAddress.lookup('speed.cloudflare.com'),
      );
      if (dns != null && dns.isNotEmpty) {
        metrics['dnsMs'] = dnsTimer.elapsedMicroseconds / 1000;
      } else {
        notes['DNS'] = 'The system resolver did not return an address.';
      }
      final times = await tcpSamples('1.1.1.1', 443, 5);
      if (times.isEmpty) {
        notes['Internet timing'] =
            'Cloudflare did not respond before the timeout.';
      } else {
        metrics['internetMs'] = percentile(times, .5);
      }
      if (speed) {
        final ndt = Ndt7();
        final useNdt = provider == 'M-Lab NDT7';
        final endpoints = useNdt ? await _optional(ndt.locate) : null;
        notes['Throughput provider'] = provider;
        if (useNdt && endpoints == null) {
          notes['Throughput'] = 'M-Lab discovery did not return a server.';
          return CheckReport(data);
        }
        for (final upload in [false, true]) {
          progress(upload ? 'Measuring upload…' : 'Measuring download…');
          try {
            metrics[upload ? 'up' : 'down'] = useNdt
                ? await ndt.measure(
                    endpoints![upload ? 'upload' : 'download']!,
                    upload: upload,
                  )
                : await _transfer(upload);
          } on Exception {
            notes[upload ? 'Upload' : 'Download'] =
                'The $provider transfer could not finish.';
          }
        }
      }
    }
    return CheckReport(data);
  }

  static Future<String?> currentBssid() async {
    if (!Platform.isLinux) return _optional(NetworkInfo().getWifiBSSID);
    final client = NetworkManagerClient();
    try {
      await client.connect().timeout(const Duration(seconds: 5));
      return client.devices
          .map((d) => d.wireless?.activeAccessPoint?.hwAddress)
          .nonNulls
          .firstOrNull;
    } finally {
      await client.close();
    }
  }

  static double percentile(List<double> values, double fraction) {
    final sorted = [...values]..sort();
    return sorted[(sorted.length * fraction).ceil() - 1];
  }

  static ({List<double> samples, double loss})? parsePing(String output) {
    final counts = RegExp(
      r'(\d+) packets transmitted,\s*(\d+) (?:packets )?received',
    ).firstMatch(output);
    if (counts == null) return null;
    final sent = int.parse(counts[1]!);
    final received = int.parse(counts[2]!);
    if (sent == 0 || received > sent) return null;
    final samples = RegExp(
      r'\btime[=<]\s*([0-9]+(?:\.[0-9]+)?)\s*ms',
    ).allMatches(output).map((m) => double.parse(m[1]!)).toList();
    if (received != samples.length) return null;
    return (samples: samples, loss: 100 * (sent - received) / sent);
  }

  static Future<({List<double> samples, double loss})?> pingGateway(
    String gateway,
  ) async {
    if (!privateGateway(gateway) ||
        !(Platform.isLinux || Platform.isAndroid || Platform.isMacOS)) {
      return null;
    }
    Process? child;
    try {
      child = await Process.start(
        Platform.isAndroid ? '/system/bin/ping' : 'ping',
        ['-n', '-c', '20', gateway],
        environment: {'LC_ALL': 'C'},
      );
      final results = await Future.wait<dynamic>([
        child.stdout.transform(utf8.decoder).join(),
        child.stderr.drain<void>(),
        child.exitCode,
      ]).timeout(const Duration(seconds: 32));
      return parsePing(results.first as String);
    } on Exception {
      return null;
    } finally {
      child?.kill();
    }
  }

  static Future<List<double>> tcpSamples(
    String host,
    int port,
    int count, {
    Duration spacing = const Duration(milliseconds: 150),
  }) async {
    final values = <double>[];
    for (var i = 0; i < count; i++) {
      if (i > 0) await Future<void>.delayed(spacing);
      final timer = Stopwatch()..start();
      try {
        final socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 2),
        );
        values.add(timer.elapsedMicroseconds / 1000);
        socket.destroy();
      } on SocketException {
        if (values.isEmpty || i > 1) break;
      }
    }
    return values;
  }

  Future<double> _transfer(bool upload) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..autoUncompress = false;
    try {
      return await (() async {
        const uploadSize = 1024 * 1024;
        const downloadSize = 4 * 1024 * 1024;
        final uri = Uri.https(
          'speed.cloudflare.com',
          upload ? '/__up' : '/__down',
          upload
              ? null
              : {
                  'bytes': '$downloadSize',
                  'nonce': DateTime.now().microsecondsSinceEpoch.toString(),
                },
        );
        final request = await client.openUrl(upload ? 'POST' : 'GET', uri);
        request.followRedirects = false;
        request.headers.set('Accept-Encoding', 'identity');
        final timer = Stopwatch()..start();
        if (upload) {
          request.headers.contentType = ContentType.binary;
          request.contentLength = uploadSize;
          request.add(Uint8List(uploadSize));
        }
        final response = await request.close();
        if (response.statusCode ~/ 100 != 2) {
          throw HttpException('Transfer failed');
        }
        var bytes = 0;
        await for (final chunk in response) {
          bytes += chunk.length;
          if (bytes > downloadSize) {
            throw const FormatException('Unexpected download size');
          }
        }
        if (!upload && bytes != downloadSize) {
          throw const FormatException('Incomplete download');
        }
        return (upload ? uploadSize : bytes) *
            8 /
            math.max(1, timer.elapsedMicroseconds);
      })().timeout(const Duration(seconds: 20));
    } finally {
      client.close(force: true);
    }
  }

  Future<Json> _linuxRadio() async {
    final client = NetworkManagerClient();
    try {
      await client.connect();
      for (final device in client.devices) {
        final wifi = device.wireless;
        final active = wifi?.activeAccessPoint;
        if (wifi == null || active == null) continue;
        Json ap(NetworkManagerAccessPoint p) {
          final flags = [
            ...p.rsnFlags,
            ...p.wpaFlags,
          ].map((f) => f.name.toLowerCase()).join(' ');
          final security = flags.contains('sae')
              ? 'WPA3'
              : p.rsnFlags.isNotEmpty
              ? (p.wpaFlags.isEmpty ? 'WPA2' : 'WPA/WPA2')
              : p.wpaFlags.isNotEmpty
              ? 'WPA'
              : p.flags.contains(NetworkManagerWifiAccessPointFlag.privacy)
              ? 'Protected'
              : 'Open';
          return {
            'ssid': utf8.decode(p.ssid, allowMalformed: true),
            'bssid': p.hwAddress,
            'frequency': p.frequency,
            'quality': p.strength,
            'security': flags.contains('tkip') ? '$security · TKIP' : security,
          };
        }

        return {
          'link': {
            ...ap(active),
            if (wifi.bitrate > 0) 'txRate': wifi.bitrate / 1000,
          },
          'nearby': wifi.accessPoints.map(ap).toList(),
          'note':
              'Cached access points from NetworkManager. Signal quality is reported as a percentage.',
        };
      }
      return {
        'note': 'NetworkManager did not report an associated Wi-Fi interface.',
      };
    } finally {
      await client.close();
    }
  }
}
