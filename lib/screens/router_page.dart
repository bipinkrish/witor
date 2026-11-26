import 'package:witor/l10n/labels.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../brand.dart';
import 'guided_page.dart';
import '../diagnostics/network_probe.dart';
import '../diagnostics/finding.dart';
import '../router/observations.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router/router.dart';
import '../router/vault.dart';
import '../router/safe_change.dart';

class RouterPage extends StatefulWidget {
  const RouterPage(
    this.gateway, {
    super.key,
    required this.findings,
    this.expectedSsid,
    this.expectedBssid,
  });
  final String? expectedSsid, expectedBssid;
  final String gateway;
  final List<Finding> findings;
  @override
  State<RouterPage> createState() => _RouterPageState();
}

class _RouterPageState extends State<RouterPage> {
  RouterFamily family = RouterFamily.unknown;
  bool secure = true;
  bool includeSurvey = false;
  RouterSurvey? survey;
  bool busy = false;
  String? message;
  bool remember = false;
  final vault = const RouterVault();
  String? get deviceKey => widget.expectedBssid == null
      ? null
      : '${widget.expectedBssid!.toLowerCase()}/${family.name}';

  List<Map<String, String>> radios = [];
  final user = TextEditingController();
  final password = TextEditingController();

  Future<bool> _sameRouter() async {
    if (await NetworkInfo().getWifiGatewayIP().timeout(
          const Duration(seconds: 5),
        ) !=
        widget.gateway) {
      return false;
    }
    if (widget.expectedBssid != null) {
      return (await NetworkProbe.currentBssid())?.toLowerCase() ==
          widget.expectedBssid!.toLowerCase();
    }
    if (widget.expectedSsid != null) {
      return (await NetworkInfo().getWifiName())?.replaceAll('"', '') ==
          widget.expectedSsid;
    }
    return true;
  }

  Map<String, String>? board;
  Future<void> _change(Map<String, String> radio, {bool undo = false}) async {
    final key = deviceKey;
    if (key == null || !RouterSession.supportsChannelChange(board)) return;
    String? next = '1';
    if (undo) {
      try {
        final backup = await vault.readBackup(key);
        if (backup == null || backup['radio'] != radio['Radio']) {
          if (mounted) setState(() => message = 'No backup for this radio.');
          return;
        }
        next = backup['channel'] as String?;
      } catch (_) {
        if (mounted) {
          setState(() => message = 'Could not open the encrypted backup.');
        }
        return;
      }
    }
    if (!mounted || next == null) return;
    final candidates = undo ? [next] : ['1', '6', '11', 'auto'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(undo ? 'Restore channel' : 'Change 2.4 GHz channel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current channel ${radio['Channel']}. Wireless devices may disconnect while the radio restarts. OpenWrt will roll back after 90 seconds unless the new setting is verified.',
              ),
              DropdownButton<String>(
                value: next,
                items: [
                  for (final c in candidates)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setLocal(() => next = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const UiText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, next),
              child: const UiText('Apply'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _run((s) async {
      if (password.text.isEmpty) {
        message = 'Enter or load your router account first.';
        return;
      }
      final secret = password.text;
      password.clear();
      final outcome = await s.verifiedChannelChange(
        user: user.text.trim(),
        password: secret,
        radio: radio['Radio']!,
        original: radio['Channel']!,
        proposed: selected,
        sameRouter: _sameRouter,
        saveBackup: (config) => vault.backup(key, config),
      );
      message = switch (outcome) {
        ChangeOutcome.unchanged => 'The channel already matches.',
        ChangeOutcome.verified => 'Reconnected and verified the channel.',
        ChangeOutcome.awaitingRouterRollback =>
          'The change could not be confirmed. Let OpenWrt roll back, reconnect, then read the settings again.',
      };
      if (outcome == ChangeOutcome.verified) radio['Channel'] = selected;
    });
  }

  Future<void> _run(Future<void> Function(RouterSession) action) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    final session = RouterSession(
      widget.gateway,
      https: secure,
      sameRouter: _sameRouter,
    );
    try {
      if (!await _sameRouter()) {
        throw const FormatException('The connected network changed.');
      }
      await action(session);
    } on StateError catch (e) {
      message = e.message;
    } on Exception {
      message =
          'Could not complete this request. Check the Wi-Fi connection, protocol, router permissions and credentials. For a local certificate, open the router page in your browser.';
    } finally {
      session.close();
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    user.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const WitorWordmark()),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.router_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        [
                          widget.expectedSsid,
                          widget.gateway,
                        ].nonNulls.join('  ·  '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                UiText(
                  'Router admin sign-in',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const UiText(
                  'Use the admin account you set up, or the admin details on the router label if they are still current.',
                ),
                const SizedBox(height: 22),
                DropdownButtonFormField<RouterFamily>(
                  key: ValueKey(family),
                  initialValue: family,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: uiLabel(context, 'Router family'),
                  ),
                  items: [
                    for (final f in RouterFamily.values)
                      DropdownMenuItem(value: f, child: Text(f.label)),
                  ],
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          family = v!;
                          user.clear();
                          password.clear();
                          remember = false;
                          radios = [];
                          survey = null;
                          board = null;
                          message = null;
                        }),
                ),
                const SizedBox(height: 16),
                if (family == RouterFamily.openwrt ||
                    family == RouterFamily.fritz) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          UiText(
                            'Admin account',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: user,
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline),
                              border: const OutlineInputBorder(),
                              labelText: uiLabel(context, 'Admin username'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: password,
                            enabled: !busy,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              labelText: uiLabel(context, 'Admin password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => _run((s) async {
                            if (user.text.trim().isEmpty ||
                                password.text.isEmpty) {
                              message =
                                  'Enter your subscriber account and password.';
                              return;
                            }
                            final secret = password.text;
                            password.clear();
                            radios = family == RouterFamily.openwrt
                                ? await s.openWrtRadios(
                                    user.text.trim(),
                                    secret,
                                    includeSurvey: includeSurvey,
                                  )
                                : await s.fritzRadios(user.text.trim(), secret);
                            board = s.board;
                            survey = s.survey;
                            if (remember && deviceKey != null) {
                              await vault.remember(
                                deviceKey!,
                                user.text.trim(),
                                secret,
                              );
                            }
                            message = radios.isEmpty
                                ? 'The router returned no readable radio settings.'
                                : 'Wi-Fi settings read from your router.';
                          }),
                    child: const UiText('Sign in and read'),
                  ),
                ],
                if (family != RouterFamily.openwrt &&
                    family != RouterFamily.fritz)
                  FilledButton.icon(
                    icon: const Icon(Icons.login_rounded),
                    label: const UiText('Open router sign-in'),
                    onPressed: busy
                        ? null
                        : () => _run((s) async {
                            if (!Platform.isLinux &&
                                (secure || widget.gateway == '192.168.1.1')) {
                              if (!mounted) return;
                              final captured = await Navigator.of(this.context)
                                  .push<List<Map<String, String>>>(
                                    MaterialPageRoute(
                                      builder: (_) => GuidedPage(
                                        findings: [
                                          ...routerFindings(radios),
                                          ...widget.findings,
                                        ],
                                        uri: s.page,
                                        family: family,
                                      ),
                                    ),
                                  );
                              if (captured != null) radios = captured;
                            } else if (!await launchUrl(
                              s.page,
                              mode: LaunchMode.externalApplication,
                            )) {
                              throw const FormatException();
                            }
                          }),
                  ),
                const SizedBox(height: 12),
                if (!secure)
                  const UiText(
                    'HTTP sends login details across your Wi-Fi without encryption.',
                  ),
                ExpansionTile(
                  title: const UiText('Connection options'),
                  subtitle: Text(secure ? 'HTTPS' : 'HTTP'),
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const UiText('Use HTTPS'),
                      subtitle: Text(
                        secure
                            ? 'Use a trusted encrypted connection.'
                            : 'HTTP sends login details across your Wi-Fi without encryption.',
                      ),
                      value: secure,
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              secure = v;
                              password.clear();
                              remember = false;
                              radios = [];
                              survey = null;
                              board = null;
                              message = null;
                            }),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (!Platform.isLinux &&
                            (secure || widget.gateway == '192.168.1.1'))
                          OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => _run((s) async {
                                    if (!mounted) return;
                                    final captured =
                                        await Navigator.of(
                                          this.context,
                                        ).push<List<Map<String, String>>>(
                                          MaterialPageRoute(
                                            builder: (_) => GuidedPage(
                                              findings: [
                                                ...routerFindings(radios),
                                                ...widget.findings,
                                              ],
                                              uri: s.page,
                                              family: family,
                                            ),
                                          ),
                                        );
                                    if (captured != null) radios = captured;
                                  }),
                            child: const UiText('Guided setup'),
                          ),
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => _run((s) async {
                                  final detected = await s.identify();
                                  if (!mounted) return;
                                  if (family != detected) {
                                    user.clear();
                                    password.clear();
                                    remember = false;
                                  }
                                  family = detected;
                                  radios = [];
                                  survey = null;
                                  board = null;
                                  message = family == RouterFamily.unknown
                                      ? 'Choose the family printed on the router.'
                                      : 'Detected ${family.label}.';
                                }),
                          child: const UiText('Identify router'),
                        ),
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => _run((s) async {
                                  if (!await launchUrl(
                                    s.page,
                                    mode: LaunchMode.externalApplication,
                                  )) {
                                    throw const FormatException();
                                  }
                                }),
                          child: const UiText('Open router page'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                if (family == RouterFamily.openwrt ||
                    family == RouterFamily.fritz)
                  ExpansionTile(
                    title: const UiText('Account and scan options'),
                    children: [
                      if (family == RouterFamily.openwrt)
                        CheckboxListTile(
                          value: includeSurvey,
                          onChanged: busy
                              ? null
                              : (v) =>
                                    setState(() => includeSurvey = v ?? false),
                          title: const Text('Include a router-side Wi-Fi scan'),
                          subtitle: const Text(
                            'Read nearby access points, connected client count and WAN address type.',
                          ),
                        ),
                      if (deviceKey != null) ...[
                        CheckboxListTile(
                          value: remember,
                          onChanged: busy
                              ? null
                              : (v) => setState(() => remember = v ?? false),
                          title: const UiText(
                            'Remember account in device keychain',
                          ),
                        ),
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _run((_) async {
                                      final saved = await vault.readLogin(
                                        deviceKey!,
                                      );
                                      if (saved == null) {
                                        message =
                                            'No saved account for this access point.';
                                        return;
                                      }
                                      user.text = saved[0];
                                      password.text = saved[1];
                                      remember = true;
                                    }),
                              child: const UiText('Load saved account'),
                            ),
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _run((_) async {
                                      await vault.forget(deviceKey!);
                                      password.clear();
                                      remember = false;
                                      message = 'Saved account removed.';
                                    }),
                              child: const UiText('Forget account'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ExpansionTile(
                  title: const UiText('Wireless settings guide'),
                  children: [
                    SelectableText(family.guide),
                    const SizedBox(height: 12),
                    const Text(
                      'Record your current settings before editing. After the radio restarts, reconnect to this Wi-Fi and run another check.',
                    ),
                  ],
                ),
                if (family == RouterFamily.openwrt &&
                    RouterSession.supportsChannelChange(board) &&
                    deviceKey != null)
                  for (final radio in radios.where(
                    (r) => r['Band'] == '2g' && r['Channel'] != null,
                  ))
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: busy ? null : () => _change(radio),
                          child: const UiText('Change channel'),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => _change(radio, undo: true),
                          child: const UiText('Restore previous channel'),
                        ),
                      ],
                    ),
                if (survey case final observed?)
                  ListTile(
                    title: Text(
                      'Router scan · ${observed.nearby.length} access points',
                    ),
                    subtitle: Text(
                      [
                        if (observed.clientCount != null)
                          '${observed.clientCount} wireless clients',
                        ...observed.notes,
                      ].join(' · '),
                    ),
                  ),
                if (radios.isNotEmpty || survey != null)
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.pop(context, (
                            radios: radios,
                            survey: survey,
                          )),
                    child: const UiText('Add settings to report'),
                  ),
                if (busy) const LinearProgressIndicator(),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(message!),
                  ),
                for (final radio in radios)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        radio.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
