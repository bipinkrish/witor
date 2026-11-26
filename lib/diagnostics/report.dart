import 'dart:math' as math;
import '../router/observations.dart';
import 'finding.dart';

typedef Json = Map<String, dynamic>;

class Radio {
  Radio(this.fields);
  final Json fields;
  String? get name => fields['ssid'] as String?;
  String? get id => fields['bssid'] as String?;
  int? get rssi => (fields['rssi'] as num?)?.toInt();
  int? get frequency => (fields['frequency'] as num?)?.toInt();
  int? get width => (fields['width'] as num?)?.toInt();
  String? get band {
    final f = frequency;
    if (f == null) return fields['band'] as String?;
    if (f >= 2400 && f <= 2500) return '2.4 GHz';
    if (f >= 4900 && f < 5925) return '5 GHz';
    if (f >= 5925 && f < 7125) return '6 GHz';
    return null;
  }

  int? get channel {
    if (fields['channel'] is int) return fields['channel'];
    final f = frequency;
    if (f == null) return null;
    if (f == 2484) return 14;
    if (f == 5935) return 2;
    if (f < 5000 && f >= 4900) return (f - 4000) ~/ 5;
    return switch (band) {
      '2.4 GHz' => (f - 2407) ~/ 5,
      '5 GHz' => (f - 5000) ~/ 5,
      '6 GHz' => (f - 5950) ~/ 5,
      _ => null,
    };
  }

  String? get signal => rssi != null
      ? '$rssi dBm'
      : fields['quality'] is num
      ? "${fields['quality']}%"
      : null;
}

class CheckReport {
  CheckReport(this.data);
  final Json data;
  DateTime get time => DateTime.parse(data['time'] as String).toLocal();
  String get network => data['network'] as String;
  String? get gateway => data['gateway'] as String?;
  Radio get link => Radio(Json.from(data['link'] as Map? ?? {}));
  Iterable<Radio> get nearby => (data['nearby'] as List? ?? [])
      .whereType<Map>()
      .map((x) => Radio(Json.from(x)));
  Iterable<Radio> get routerNearby =>
      ((data['routerSurvey'] as Map?)?['nearby'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Radio(Json.from(e)));
  Map<String, String> get notes =>
      Map<String, String>.from(data['notes'] as Map? ?? {});
  num? metric(String key) => (data['metrics'] as Map?)?[key] as num?;
  String? get identity =>
      link.id ?? (link.name == null ? null : '${link.name}/$gateway');
  bool comparable(CheckReport other) =>
      identity != null && identity == other.identity;

  Map<String, String> get readings {
    final radio = link;
    final metrics = data['metrics'] as Map? ?? {};
    final protocol = data['gatewayProtocol'] ?? 'TCP';
    return {
      'Network type': network,
      if (radio.name != null) 'Wi-Fi network': radio.name!,
      if (radio.band != null) 'Band': radio.band!,
      if (radio.channel != null) 'Channel': '${radio.channel}',
      if (radio.width != null) 'Channel width': '${radio.width} MHz',
      if (radio.signal != null) 'Signal': radio.signal!,
      if (radio.fields['security'] != null)
        'Security': radio.fields['security'].toString(),
      if (radio.fields['phy'] != null)
        'Wi-Fi standard': radio.fields['phy'].toString(),
      if (radio.fields['txRate'] != null)
        'Link rate': "${radio.fields['txRate']} Mbps",
      if (data['address'] != null) 'Local address': data['address'] as String,
      if (gateway != null) 'Gateway': gateway!,
      if (metrics['gatewayLoss'] is num)
        'Gateway ICMP packet loss':
            "${(metrics['gatewayLoss'] as num).toStringAsFixed(0)}%",
      for (final entry in {
        'gatewayMs': 'Gateway $protocol median',
        'gatewayP95': 'Gateway $protocol p95',
        'gatewayJitter': 'Gateway $protocol jitter',
        'gatewayMean': 'Gateway $protocol average',
        'gatewayMin': 'Gateway $protocol minimum',
        'internetMs': 'Internet TCP median',
        'dnsMs': 'DNS lookup',
        'down': 'Download',
        'up': 'Upload',
      }.entries)
        if (metrics[entry.key] is num)
          entry.value:
              "${(metrics[entry.key] as num).toStringAsFixed(1)} ${['up', 'down'].contains(entry.key) ? 'Mbps' : 'ms'}",
    };
  }

  List<Map<String, String>> get routerRadios =>
      (data['routerRadios'] as List? ?? [])
          .whereType<Map>()
          .map((v) => Map<String, String>.from(v))
          .toList();

  List<Finding> get findings {
    final radio = link;
    final security = (radio.fields['security'] as String? ?? '').toUpperCase();
    final result = routerFindings(routerRadios);
    if ((data['routerSurvey'] as Map?)?['privateWan'] == true) {
      result.add(
        const Finding(
          'Possible double NAT',
          'The router has a private IPv4 WAN address.',
          'Check whether an upstream modem or router also does NAT. If you control both routers, consider access-point mode on the downstream unit.',
        ),
      );
    }
    if (data['offline'] == true) {
      return [
        const Finding(
          'No active network',
          'The operating system reported no connection.',
          'Join your Wi-Fi network in system settings, then check again.',
        ),
      ];
    }
    if (security.contains('WEP') || security == 'OPEN') {
      result.add(
        Finding(
          'Wi-Fi security needs attention',
          'This network advertises $security security.',
          'In Wireless Security, select WPA2-AES or WPA3 and set a strong Wi-Fi password.',
          setting: RouterSetting.security,
        ),
      );
    } else if (security.contains('TKIP') || security.contains('WPA/WPA2')) {
      result.add(
        Finding(
          'Legacy Wi-Fi security',
          'The access point advertises $security.',
          'Use WPA2-AES or WPA3 if all of your devices support it.',
          setting: RouterSetting.security,
        ),
      );
    }
    final signal = radio.rssi;
    if (signal != null &&
        radio.band != null &&
        signal < (radio.band == '2.4 GHz' ? -70 : -67)) {
      result.add(
        Finding(
          'Weak Wi-Fi signal',
          'The ${radio.band} link measures $signal dBm.',
          'Move closer to the access point and compare another check.',
        ),
      );
    }
    final alternatives = nearby.where(
      (n) =>
          radio.name != null &&
          n.name == radio.name &&
          n.band == '5 GHz' &&
          (n.rssi ?? -150) >= -70,
    );
    if (radio.band == '2.4 GHz' && alternatives.isNotEmpty) {
      result.add(
        const Finding(
          'A 5 GHz connection is available',
          'A nearby 5 GHz access point advertises the same network name with a strong signal.',
          'Try the 5 GHz band in your Wi-Fi settings and compare the two checks.',
        ),
      );
    }
    final neighbours = (nearby.isNotEmpty ? nearby : routerNearby)
        .where(
          (n) =>
              radio.id != null &&
              n.id != null &&
              n.id!.toLowerCase() != radio.id!.toLowerCase() &&
              n.band == '2.4 GHz' &&
              n.channel != null,
        )
        .toList();
    final channel = radio.channel;
    if (radio.band == '2.4 GHz' &&
        channel != null &&
        !{1, 6, 11}.contains(channel) &&
        neighbours.isEmpty) {
      result.add(
        Finding(
          'Overlapping 2.4 GHz channel',
          'The access point uses channel $channel.',
          'Inspect the nearby networks before choosing a 20 MHz channel. Channels 1, 6 and 11 do not overlap one another.',
          setting: RouterSetting.channel,
        ),
      );
    }
    if (radio.band == '2.4 GHz' && channel != null && neighbours.isNotEmpty) {
      double interference(int c) => neighbours.fold(0.0, (sum, n) {
        final width = ((n.width ?? 20) + 20) / 10;
        final overlap = math.max(0.0, 1 - (n.channel! - c).abs() / width);
        return sum + overlap * math.pow(10, ((n.rssi ?? -70) + 100) / 20);
      });
      final best = [
        1,
        6,
        11,
      ].reduce((a, b) => interference(a) <= interference(b) ? a : b);
      if (best != channel &&
          interference(best) < interference(channel) * 0.75) {
        result.add(
          Finding(
            'A quieter channel is available',
            'Nearby networks overlap channel $channel more than channel $best in this scan.',
            'In the router’s 2.4 GHz settings, try channel $best and check again.',
            setting: RouterSetting.channel,
          ),
        );
      }
      if ((radio.width ?? 0) >= 40 &&
          neighbours.where((n) => (n.channel! - channel).abs() < 6).length >=
              3) {
        result.add(
          const Finding(
            'Wide channel in a busy band',
            'At least three nearby access points overlap your 2.4 GHz channel.',
            'Try 20 MHz channel width in the router settings.',
            setting: RouterSetting.width,
          ),
        );
      }
    }
    if ((metric('gatewayP95') ?? 0) > 80 ||
        (metric('gatewayJitter') ?? 0) > 15) {
      result.add(
        Finding(
          'Uneven local response times',
          "Gateway ${data['gatewayProtocol'] ?? 'TCP'} p95 was ${metric('gatewayP95')?.round()} ms.",
          'Repeat the check closer to the router and pause other transfers.',
        ),
      );
    }
    if ((metric('dnsMs') ?? 0) > 100) {
      result.add(
        Finding(
          'Slow DNS lookup',
          'The system resolver took ${metric('dnsMs')!.round()} ms.',
          'Repeat the test. If delays persist, review the DNS servers in your network settings.',
        ),
      );
    }
    final rate = radio.fields['txRate'] as num?;
    if (rate != null &&
        rate > 0 &&
        metric('up') != null &&
        metric('up')! < rate * .4) {
      result.add(
        Finding(
          'Upload below the Wi-Fi link rate',
          'The upload test measured ${metric('up')!.toStringAsFixed(1)} Mbps on a $rate Mbps transmit link.',
          'Compare with an Ethernet test to distinguish Wi-Fi conditions from your internet plan.',
        ),
      );
    }
    return result;
  }
}
