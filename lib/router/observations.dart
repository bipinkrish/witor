import '../diagnostics/finding.dart';

/// Sanitised observations from a subscriber-visible wireless settings page.
/// Fields outside this allowlist (including keys, cookies and form tokens)
/// never cross the WebView bridge.
const readVisibleRadio = r"""
(() => {
  const docs = [document];
  for (const frame of document.querySelectorAll('iframe,frame')) {
    try { if (frame.contentDocument) docs.push(frame.contentDocument); } catch (_) {}
  }
  for (const doc of docs) {
    const fields = {};
    for (const name of ['band','chanwid','chan','txpower','security_method','wpa2ciphersuite_t','wpa2ciphersuite_a']) {
      const el = doc.querySelector('select[name="'+name+'"],input[type=checkbox][name="'+name+'"]');
      if (!el || !el.getClientRects().length) continue;
      if (el.tagName === 'SELECT') {
        const option = el.options[el.selectedIndex];
        if (option) fields[name] = {value:option.value.slice(0,24),text:option.text.slice(0,80)};
      } else { fields[name] = el.checked; }
    }
    if (Object.keys(fields).length) return JSON.stringify(fields);
  }
  return null;
})()
""";

Map<String, String> boaObservations(Map fields) {
  String? selected(String key, String attr) {
    final field = fields[key];
    final value = field is Map ? field[attr] : null;
    return value is String && value.length <= 80 ? value : null;
  }

  final mode = selected('band', 'text');
  final width = {
    '0': '20 MHz',
    '1': '40 MHz',
    '2': '80 MHz',
  }[selected('chanwid', 'value')];
  final channel = int.tryParse(selected('chan', 'value') ?? '');
  final method = selected('security_method', 'text');
  final power = selected('txpower', 'text');
  return {
    if (mode != null) 'Wireless mode': mode,
    if (width != null) 'Configured width': width,
    if (channel != null && channel >= 0 && channel <= 233)
      'Configured channel': channel == 0 ? 'Auto' : '$channel',
    if (method != null) 'Security': method,
    if (fields['wpa2ciphersuite_t'] is bool)
      'TKIP': fields['wpa2ciphersuite_t'] == true ? 'Enabled' : 'Disabled',
    if (fields['wpa2ciphersuite_a'] is bool)
      'AES': fields['wpa2ciphersuite_a'] == true ? 'Enabled' : 'Disabled',
    if (power != null) 'Transmit power': power,
  };
}

List<Finding> routerFindings(Iterable<Map<String, String>> radios) {
  final found = <String, Finding>{};
  for (final radio in radios) {
    final mode = (radio['Wireless mode'] ?? '').toUpperCase().replaceAll(
      ' ',
      '',
    );
    if (mode.contains('B+G') ||
        mode.contains('802.11B/G') ||
        mode.contains('(B/G')) {
      found['legacy'] = Finding(
        'Legacy 802.11b is enabled',
        'The router reports wireless mode ${radio['Wireless mode']}.',
        'If all devices support it, select G+N or a newer mode on the 2.4 GHz radio.',
        setting: RouterSetting.mode,
      );
    }
    final security = (radio['Security'] ?? '').toLowerCase();
    if (radio['TKIP'] == 'Enabled' ||
        security.contains('tkip') ||
        security.contains('mixed') &&
            (security.contains('psk') || security.contains('wpa2 mixed'))) {
      found['tkip'] = Finding(
        'Review the router’s security mode',
        'The router reports ${radio['Security'] ?? 'TKIP enabled'}.',
        'In Wireless Security, use WPA2-AES or WPA3 when compatible with your devices.',
        setting: RouterSetting.security,
      );
    }
    if (security == 'none' || security == 'wep' || security == 'open') {
      found['open'] = const Finding(
        'Unprotected wireless network',
        'The router reports open or WEP security.',
        'Choose WPA2-AES or WPA3 and set a strong network password.',
        setting: RouterSetting.security,
      );
    }
    if (radio['Configured width'] == '40 MHz' &&
        (mode.contains('2.4') || mode.contains('B+G'))) {
      found['width'] = const Finding(
        'Review 2.4 GHz channel width',
        'The router is configured for 40 MHz. The live link may use a narrower channel.',
        'If the nearby scan shows overlapping networks, try 20 MHz and repeat the check.',
        setting: RouterSetting.width,
      );
    }
  }
  return found.values.toList();
}
