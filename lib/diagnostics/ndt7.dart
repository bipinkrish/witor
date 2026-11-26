import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Locate URLs carry a short-lived token and are never included in reports.
class Ndt7 {
  static const _protocol = 'net.measurementlab.ndt.v7';
  static const _limit = 32 * 1024 * 1024;

  Future<Map<String, Uri>> locate() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..userAgent = 'witor/0.1';
    try {
      return await (() async {
        final request = await client.getUrl(
          Uri.https('locate.measurementlab.net', '/v2/nearest/ndt/ndt7'),
        );
        final response = await request.close();
        if (response.statusCode != 200) {
          throw const HttpException('No M-Lab server available');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 256 * 1024) {
            throw const FormatException('Unexpected discovery response');
          }
          bytes.addAll(chunk);
        }
        final payload = jsonDecode(utf8.decode(bytes));
        for (final item in payload['results'] as List) {
          final urls = item['urls'] as Map;
          final endpoints = <String, Uri>{};
          for (final mode in ['download', 'upload']) {
            final uri = Uri.tryParse(
              urls['wss:///ndt/v7/$mode'] as String? ?? '',
            );
            if (uri != null &&
                uri.scheme == 'wss' &&
                uri.host.isNotEmpty &&
                uri.userInfo.isEmpty &&
                uri.path == '/ndt/v7/$mode') {
              endpoints[mode] = uri;
            }
          }
          if (endpoints.length == 2) return endpoints;
        }
        throw const FormatException('Missing secure NDT7 endpoints');
      })().timeout(const Duration(seconds: 10));
    } finally {
      client.close(force: true);
    }
  }

  Future<double> measure(Uri endpoint, {required bool upload}) async {
    final http = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..userAgent = 'witor/0.1';
    WebSocket? socket;
    StreamSubscription<dynamic>? subscription;
    try {
      final ws = await WebSocket.connect(
        endpoint.toString(),
        protocols: [_protocol],
        customClient: http,
        compression: CompressionOptions.compressionOff,
      ).timeout(const Duration(seconds: 8));
      socket = ws;
      if (ws.protocol != _protocol) {
        throw const FormatException('NDT7 protocol mismatch');
      }
      final timer = Stopwatch()..start();
      final done = Completer<void>();
      var received = 0, acknowledged = 0, ackTime = 0;
      void finish() {
        if (!done.isCompleted) done.complete();
      }

      subscription = ws.listen(
        (message) {
          if (message is List<int> && !upload) {
            received += message.length;
            if (received >= _limit) finish();
          } else if (message is String && upload && message.length < 65536) {
            try {
              final stats = jsonDecode(message)['AppInfo'];
              if (stats is Map &&
                  stats['NumBytes'] is int &&
                  stats['ElapsedTime'] is int) {
                acknowledged = stats['NumBytes'] as int;
                ackTime = stats['ElapsedTime'] as int;
                if (acknowledged >= _limit) finish();
              }
            } on FormatException {
              /* Ignore optional telemetry messages. */
            }
          }
        },
        onDone: finish,
        onError: (Object error) {
          finish();
        },
        cancelOnError: true,
      );
      if (upload) {
        final random = Random.secure();
        final chunk = Uint8List.fromList(
          List.generate(65536, (_) => random.nextInt(256)),
        );
        var sent = 0;
        while (!done.isCompleted &&
            timer.elapsed < const Duration(seconds: 10)) {
          if (sent < _limit && sent - acknowledged < 4 * 1024 * 1024) {
            ws.add(chunk);
            sent += chunk.length;
          } else {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        }
        if (ackTime <= 0 || acknowledged <= 0) {
          throw const HttpException('No measured upload');
        }
        return acknowledged * 8 / ackTime;
      }
      await done.future.timeout(const Duration(seconds: 11), onTimeout: () {});
      if (received == 0) throw const HttpException('No measured download');
      return received * 8 / max(1, timer.elapsedMicroseconds);
    } finally {
      await subscription?.cancel();
      if (socket != null) unawaited(socket.close().catchError((_) => null));
      http.close(force: true);
    }
  }
}
