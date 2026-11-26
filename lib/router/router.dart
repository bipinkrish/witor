import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html;
import 'package:xml/xml.dart';

import '../diagnostics/network_probe.dart';
import '../diagnostics/report.dart';
import 'safe_change.dart';

enum RouterFamily {
  boa('Realtek / Boa'),
  openwrt('OpenWrt'),
  fritz('FRITZ!Box'),
  tplink('TP-Link'),
  asus('ASUS'),
  xiaomi('Xiaomi'),
  netgear('NETGEAR'),
  huawei('Huawei'),
  zte('ZTE'),
  nokia('Nokia'),
  jio('JioFiber'),
  unknown('Other router');

  const RouterFamily(this.label);
  final String label;
  String get guide => switch (this) {
    RouterFamily.boa =>
      'Open WLAN in the sidebar. Select the band, then Basic Settings for channel or width, or Security for encryption.',
    RouterFamily.openwrt =>
      'In LuCI, open Network → Wireless. Choose Edit beside your radio. Channel and width are under Device Configuration. Encryption is under Wireless Security.',
    RouterFamily.fritz =>
      'Open Wi-Fi → Wi-Fi Channel for channel selection, or Wi-Fi → Security for encryption.',
    RouterFamily.tplink =>
      'Open Advanced → Wireless → Wireless Settings. Select the band before editing channel, width or security.',
    RouterFamily.asus =>
      'Open Advanced Settings → Wireless → General and select the band.',
    RouterFamily.xiaomi =>
      'Open Settings → Wi-Fi settings, then select the band.',
    RouterFamily.netgear =>
      'Open the Wireless settings page under Basic and select the band you want to adjust.',
    RouterFamily.huawei =>
      'Open Wi-Fi Settings or WLAN. Fibre and mobile broadband models use different menus.',
    RouterFamily.zte || RouterFamily.nokia =>
      'Open Network → WLAN or Local Network → WLAN. Your ISP determines which settings your account can change.',
    RouterFamily.jio =>
      'Use the Wi-Fi settings for your connection in MyJio. After saving, reconnect this device and run another check.',
    RouterFamily.unknown =>
      'Sign in with your router’s subscriber account and look for Wireless or WLAN. If those settings are managed by your provider, use its app.',
  };
  static RouterFamily identify(String server, String page) {
    final doc = html.parse(page);
    final hints = [
      server,
      doc.querySelector('title')?.text ?? '',
      ...doc
          .querySelectorAll(
            'script[src], link[href], form[action], meta[http-equiv]',
          )
          .map((e) => e.attributes.values.join(' ')),
    ].join(' ').toLowerCase();
    for (final family in values) {
      final match = switch (family) {
        RouterFamily.boa =>
          hints.contains('boa/') || hints.contains('/boaform/'),
        RouterFamily.openwrt =>
          hints.contains('openwrt') ||
              hints.contains('/cgi-bin/luci') && hints.contains('luci-static'),
        RouterFamily.fritz => hints.contains('fritz'),
        RouterFamily.tplink =>
          hints.contains('tp-link') || hints.contains('tplink'),
        RouterFamily.asus => hints.contains('asus'),
        RouterFamily.xiaomi => hints.contains('miwifi'),
        RouterFamily.jio =>
          hints.contains('jiofiber') || hints.contains('teamf1'),
        RouterFamily.netgear => hints.contains('netgear'),
        RouterFamily.huawei => hints.contains('huawei'),
        RouterFamily.zte => hints.contains('zte'),
        RouterFamily.nokia => hints.contains('nokia'),
        RouterFamily.unknown => false,
      };
      if (match) return family;
    }
    return unknown;
  }
}

/// One queue per gateway across login, metadata and configuration reads.
class RouterSession implements ChannelTransaction {
  RouterSession(
    this.gateway, {
    this.https = true,
    this.sameRouter,
    HttpClient? client,
  }) : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 5);
    if (!privateGateway(gateway)) {
      throw const FormatException('Expected a local IPv4 gateway');
    }
    _client.findProxy = (_) => 'DIRECT';
  }
  final String gateway;
  final bool https;
  final Future<bool> Function()? sameRouter;
  final HttpClient _client;
  Map<String, String>? board;
  RouterSurvey? survey;
  static final _queues = <String, Future<void>>{};
  static final _last = <String, DateTime>{};
  Uri get page => Uri(scheme: https ? 'https' : 'http', host: gateway);
  String? _token;

  Future<({String body, String server})> request(
    String path, {
    String? body,
    String contentType = 'application/json',
    int? port,
    Map<String, String> headers = const {},
  }) async {
    final previous = _queues[gateway] ?? Future<void>.value();
    final done = Completer<void>();
    _queues[gateway] = done.future;
    try {
      await previous;
      final gap = DateTime.now().difference(_last[gateway] ?? DateTime(1970));
      if (gap < const Duration(milliseconds: 850)) {
        await Future<void>.delayed(const Duration(milliseconds: 850) - gap);
      }
      return await (() async {
        if (sameRouter != null && !await sameRouter!()) {
          throw const HttpException('The connected network changed.');
        }
        final uri = page.replace(path: path, port: port);
        final req = await _client.openUrl(body == null ? 'GET' : 'POST', uri);
        req.followRedirects = false;
        for (final h in headers.entries) {
          req.headers.set(h.key, h.value);
        }
        if (body != null) {
          req.headers.set('Content-Type', contentType);
          req.add(utf8.encode(body));
        }
        final response = await req.close();
        if (response.statusCode >= 400) {
          throw HttpException('Router returned HTTP ${response.statusCode}');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 1024 * 1024) {
            throw const FormatException('Router response too large');
          }
          bytes.addAll(chunk);
        }
        return (
          body: utf8.decode(bytes, allowMalformed: true),
          server: response.headers.value('server') ?? '',
        );
      })().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _client.close(force: true);
          throw TimeoutException('Router timed out');
        },
      );
    } finally {
      _last[gateway] = DateTime.now();
      done.complete();
      if (identical(_queues[gateway], done.future)) _queues.remove(gateway);
    }
  }

  Future<RouterFamily> identify() async {
    final response = await request('/');
    return RouterFamily.identify(response.server, response.body);
  }

  Future<Json> _rpc(String object, String action, Json args) async {
    final response = await request(
      '/ubus',
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'call',
        'params': [
          _token ?? '00000000000000000000000000000000',
          object,
          action,
          args,
        ],
      }),
    );
    final result = jsonDecode(response.body);
    final data = result is Map ? result['result'] : null;
    if (data is! List || data.isEmpty || data.first != 0) {
      throw const HttpException('Router denied this operation');
    }
    return data.length > 1 && data[1] is Map ? Json.from(data[1] as Map) : {};
  }

  Future<T> _signedIn<T>(
    String user,
    String password,
    Future<T> Function() work,
  ) async {
    final auth = await _rpc('session', 'login', {
      'username': user,
      'password': password,
    });
    final token = auth['ubus_rpc_session'];
    if (token is! String || token.isEmpty) {
      throw const HttpException('Sign-in failed');
    }
    _token = token;
    try {
      return await work();
    } finally {
      try {
        await _rpc('session', 'destroy', {'ubus_rpc_session': token});
      } on Exception {
        /* the session also expires on the router */
      }
      _token = null;
    }
  }

  Future<List<Map<String, String>>> openWrtRadios(
    String user,
    String password, {
    bool includeSurvey = false,
  }) => _signedIn(user, password, () async {
    try {
      final data = await _rpc('system', 'board', {});
      final release = data['release'];
      if (data['model'] is String &&
          release is Map &&
          release['revision'] is String) {
        board = {'model': data['model'], 'revision': release['revision']};
      }
    } on Exception {
      /* Limited accounts may only read wireless settings. */
    }
    final config = await _rpc('uci', 'get', {'config': 'wireless'});
    if (includeSurvey) survey = await _survey();
    return summarizeWireless(config['values']);
  });

  Future<RouterSurvey> _survey() async {
    final byBssid = <String, Json>{};
    final clients = <String>{};
    final notes = <String>[];
    var associationsRead = false;
    bool? privateWan;
    try {
      final wan = await _rpc('network.interface.wan', 'status', {});
      final addresses = wan['ipv4-address'];
      if (addresses is List && addresses.isNotEmpty && addresses.first is Map) {
        final address = addresses.first['address'];
        if (address is String) privateWan = privateGateway(address);
      }
    } on Exception {
      notes.add('WAN information was unavailable.');
    }
    try {
      final radios = (await _rpc('iwinfo', 'devices', {}))['devices'];
      if (radios is! List || radios.isEmpty) throw const FormatException();
      for (final device in radios.whereType<String>().toSet().take(8)) {
        try {
          final result = await _rpc('iwinfo', 'scan', {'device': device});
          for (final item in RouterSurvey.accessPoints(result['results'])) {
            byBssid[item['bssid'] as String] = item;
          }
        } on Exception {
          notes.add('No scan result for $device.');
        }
        try {
          final result = (await _rpc('iwinfo', 'assoclist', {
            'device': device,
          }))['results'];
          if (result is! List) throw const FormatException();
          clients.addAll(
            result
                .whereType<Map>()
                .map((v) => v['mac'])
                .whereType<String>()
                .map((v) => v.toUpperCase()),
          );
          associationsRead = true;
        } on Exception {
          notes.add('The association list for $device was unavailable.');
        }
      }
    } on Exception {
      notes.add(
        'The router did not expose its Wi-Fi interfaces to this account.',
      );
    }
    return RouterSurvey(
      byBssid.values.toList(),
      associationsRead ? clients.length : null,
      privateWan,
      notes,
    );
  }

  // Populate only after the acceptance run on the named hardware/firmware.
  static const verifiedChannelProfiles = <(String, String)>{};
  static bool supportsChannelChange(Map<String, String>? board) =>
      board != null &&
      verifiedChannelProfiles.contains((board['model'], board['revision']));

  Future<ChangeOutcome> verifiedChannelChange({
    required String user,
    required String password,
    required String radio,
    required String original,
    required String proposed,
    required Future<bool> Function() sameRouter,
    required Future<void> Function(Json) saveBackup,
  }) => _signedIn(user, password, () async {
    final data = await _rpc('system', 'board', {});
    final release = data['release'];
    final identity = {
      'model': data['model']?.toString() ?? '',
      'revision': release is Map ? release['revision']?.toString() ?? '' : '',
    };
    if (!supportsChannelChange(identity)) {
      throw const HttpException('Use guided setup for this firmware');
    }
    final raw = (await _rpc('uci', 'get', {'config': 'wireless'}))['values'];
    if (raw is! Map ||
        raw[radio] is! Map ||
        raw[radio]['.type'] != 'wifi-device' ||
        raw[radio]['band'] != '2g') {
      throw const FormatException('Expected a 2.4 GHz radio');
    }
    return changeChannel(
      router: this,
      radio: radio,
      original: original,
      proposed: proposed,
      sameRouter: sameRouter,
      backup: (r, c) => saveBackup({
        'board': identity,
        'radio': r,
        'channel': c,
        'wireless': raw,
      }),
    );
  });
  @override
  Future<String> readChannel(String radio) async {
    final reply = await _rpc('uci', 'get', {
      'config': 'wireless',
      'section': radio,
      'option': 'channel',
    });
    if (reply['value'] == null) {
      throw const FormatException('Missing channel readback');
    }
    return reply['value'].toString();
  }

  @override
  Future<void> stage(String radio, String channel) async {
    await _rpc('uci', 'set', {
      'config': 'wireless',
      'section': radio,
      'values': {'channel': channel},
    });
  }

  @override
  Future<void> applyWithRollback(Duration timeout) async {
    await _rpc('uci', 'apply', {
      'rollback': true,
      'timeout': timeout.inSeconds,
    });
  }

  @override
  Future<void> confirm() async {
    await _rpc('uci', 'confirm', {});
  }

  @override
  Future<void> revertStaged() async {
    await _rpc('uci', 'revert', {'config': 'wireless'});
  }

  /// Only these display fields may leave the protocol layer. UCI also returns keys.
  static List<Map<String, String>> summarizeWireless(Object? values) {
    if (values is! Map) {
      throw const FormatException('Missing wireless settings');
    }
    final output = <Map<String, String>>[];
    for (final entry in values.entries) {
      final v = entry.value;
      if (v is! Map) continue;
      if (v['.type'] == 'wifi-device') {
        output.add({
          'Radio': entry.key.toString(),
          for (final pair in {
            'band': 'Band',
            'channel': 'Channel',
            'htmode': 'Channel mode',
            'txpower': 'Transmit power',
          }.entries)
            if (v[pair.key] != null) pair.value: v[pair.key].toString(),
        });
      } else if (v['.type'] == 'wifi-iface') {
        output.add({
          for (final pair in {
            'ssid': 'Network',
            'device': 'Radio',
            'encryption': 'Security',
            'mode': 'Mode',
          }.entries)
            if (v[pair.key] != null) pair.value: v[pair.key].toString(),
        });
      }
    }
    return output;
  }

  Future<List<Map<String, String>>> fritzRadios(
    String user,
    String password,
  ) async {
    final port = https ? 49443 : 49000;
    var asked = false;
    _client.authenticate = (uri, scheme, realm) async {
      if (asked ||
          scheme.toLowerCase() != 'digest' ||
          uri.host != gateway ||
          uri.port != port ||
          realm == null) {
        return false;
      }
      asked = true;
      _client.addCredentials(
        uri,
        realm,
        HttpClientDigestCredentials(user, password),
      );
      return true;
    };
    final desc = XmlDocument.parse(
      (await request('/tr64desc.xml', port: port)).body,
    );
    final radios = <Map<String, String>>[];
    for (final service in desc.findAllElements('service')) {
      final type = service.getElement('serviceType')?.innerText;
      final path = service.getElement('controlURL')?.innerText;
      if (type == null ||
          !RegExp(
            r'^urn:dslforum-org:service:WLANConfiguration:[0-9]+$',
          ).hasMatch(type) ||
          path == null ||
          !path.startsWith('/')) {
        continue;
      }
      final reply = await request(
        path,
        port: port,
        contentType: 'text/xml; charset=utf-8',
        headers: {'SOAPAction': '"$type#GetInfo"'},
        body:
            '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><u:GetInfo xmlns:u="$type"/></s:Body></s:Envelope>',
      );
      final xml = XmlDocument.parse(reply.body);
      final fields = <String, String>{};
      for (final pair in {
        'NewSSID': 'Network',
        'NewChannel': 'Channel',
        'NewBeaconType': 'Security',
        'NewStatus': 'Status',
      }.entries) {
        final nodes = xml.findAllElements(pair.key);
        if (nodes.isNotEmpty) fields[pair.value] = nodes.first.innerText;
      }
      if (fields.isNotEmpty) radios.add(fields);
    }
    return radios;
  }

  void close() => _client.close(force: true);
}

class RouterSurvey {
  RouterSurvey(this.nearby, this.clientCount, this.privateWan, this.notes);
  final List<Json> nearby;
  final int? clientCount;
  final bool? privateWan;
  final List<String> notes;

  static Iterable<Json> accessPoints(Object? entries) sync* {
    if (entries is! List) return;
    for (final entry in entries.whereType<Map>()) {
      final bssid = entry['bssid'];
      if (bssid is! String || bssid.isEmpty) continue;
      final band = switch (entry['band']?.toString()) {
        '2' || '2.4' || '2.4GHz' => '2.4 GHz',
        '5' || '5GHz' => '5 GHz',
        '6' || '6GHz' => '6 GHz',
        _ => null,
      };
      yield {
        'bssid': bssid.toUpperCase(),
        if (entry['ssid'] is String) 'ssid': entry['ssid'],
        if (entry['mhz'] is int) 'frequency': entry['mhz'],
        if (entry['channel'] is int) 'channel': entry['channel'],
        if (entry['signal'] is int && entry['signal'] < 0)
          'rssi': entry['signal'],
        if (band != null) 'band': band,
      };
    }
  }

  Json get data => {
    'nearby': nearby,
    if (clientCount != null) 'clientCount': clientCount,
    if (privateWan != null) 'privateWan': privateWan,
    'notes': notes,
  };
}
