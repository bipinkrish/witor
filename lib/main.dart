import 'package:witor/l10n/labels.dart';
import 'l10n/generated/app_localizations.dart';
import 'dart:async';
import 'diagnostics/history.dart';
import 'diagnostics/network_probe.dart';
import 'diagnostics/report.dart';
import 'screens/history_page.dart';
import 'screens/report_page.dart';
import 'screens/settings_page.dart';
import 'package:flutter/material.dart';

import 'brand.dart';

void main() => runApp(const WitorApp());

class WitorApp extends StatelessWidget {
  const WitorApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final theme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xff0066cc),
            brightness: brightness,
          ).copyWith(
            primary: Color(dark ? 0xff83b7ff : 0xff005dbb),
            surface: Color(dark ? 0xff212226 : 0xffffffff),
            onSurface: Color(dark ? 0xfff5f5f7 : 0xff1d1d1f),
            onSurfaceVariant: Color(dark ? 0xffb6b7bd : 0xff565b65),
            outlineVariant: Color(dark ? 0xff3b3d43 : 0xffe0e3e9),
          ),
      scaffoldBackgroundColor: Color(dark ? 0xff141518 : 0xfff6f7f9),
    );
    return theme.copyWith(
      dividerTheme: DividerThemeData(
        color: theme.colorScheme.outlineVariant,
        thickness: .7,
        space: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'witor',
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: const ConnectionCheck(),
  );
}

enum _CheckState { ready, checking, complete, failed }

class ConnectionCheck extends StatefulWidget {
  const ConnectionCheck({super.key});
  @override
  State<ConnectionCheck> createState() => _ConnectionCheckState();
}

class _ConnectionCheckState extends State<ConnectionCheck> {
  _CheckState _state = _CheckState.ready;
  late final CheckHistory _history = CheckHistory();
  final _probe = NetworkProbe();
  CheckOptions _options = const CheckOptions();
  CheckReport? _report, _previous;
  String _progress = '';
  bool _fresh = false;
  String? _storageNote;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _restore();
  }

  Future<void> _restore() async {
    try {
      _options = await CheckOptions.load();
    } catch (_) {}
    try {
      if (_options.remember) {
        final saved = await _history.recent();
        if (mounted && saved.isNotEmpty && _state == _CheckState.ready) {
          setState(() {
            _report = saved.first;
            _previous = saved.skip(1).where(saved.first.comparable).firstOrNull;
            _state = _CheckState.complete;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _storageNote = 'History is unavailable on this device.');
      }
    }
  }

  @override
  void dispose() {
    unawaited(_history.close());
    super.dispose();
  }

  Future<void> _check() async {
    if (_state == _CheckState.checking) return;
    setState(() {
      _state = _CheckState.checking;
      _progress = 'Starting check…';
      _fresh = false;
    });
    await _ready;
    if (!mounted) return;
    try {
      final report = await _probe.check(
        detailed: _options.detailed,
        internet: _options.internet,
        speed: _options.speed,
        provider: _options.provider,
        progress: (stage) {
          if (mounted) setState(() => _progress = stage);
        },
      );
      CheckReport? previous = _report != null && report.comparable(_report!)
          ? _report
          : null;
      if (_options.remember) {
        try {
          previous ??= (await _history.recent())
              .where(report.comparable)
              .firstOrNull;
          await _history.save(report);
          _storageNote = null;
        } catch (_) {
          _storageNote = 'This report could not be saved to history.';
        }
      }
      if (!mounted) return;
      setState(() {
        _report = report;
        _previous = previous;
        _state = _CheckState.complete;
        _fresh = true;
      });
    } on Exception {
      if (mounted) {
        setState(() {
          _state = _CheckState.failed;
          _report = null;
          _previous = null;
        });
      }
    }
  }

  Future<void> _settings() async {
    await _ready;
    if (!mounted) return;
    final updated = await Navigator.push<CheckOptions>(
      context,
      MaterialPageRoute(builder: (_) => SettingsPage(_options)),
    );
    if (mounted && updated != null) setState(() => _options = updated);
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Center(child: WitorIcon(size: 48)),
        title: const UiText('About witor'),
        content: const Text(
          'Wi-Fi Doctor measures your connection and explains what you can improve. Reports stay on this device. Internet tests contact the provider you enable in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const UiText('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width < 660;
    final gutter = compact ? 20.0 : 48.0;
    final value = switch (_state) {
      _CheckState.ready => 'Not checked yet',
      _CheckState.checking => _progress,
      _CheckState.failed => 'Connection details are unavailable. Try again.',
      _CheckState.complete => _report!.network,
    };
    final date = _report?.time;
    final localizations = MaterialLocalizations.of(context);
    final timestamp = date == null
        ? '—'
        : '${localizations.formatShortDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}';

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        UiText(
          'Wi-Fi check',
          style: TextStyle(
            fontSize: compact ? 39 : 54,
            height: 1.05,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.9,
          ),
        ),
        const SizedBox(height: 12),
        UiText(
          'Measure your connection and find ways to improve your Wi-Fi.',
          style: TextStyle(
            fontSize: compact ? 16 : 18,
            height: 1.45,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff0065cb),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            textStyle: theme.textTheme.labelLarge!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: _state == _CheckState.checking ? null : _check,
          child: UiText(switch (_state) {
            _CheckState.ready => 'Check connection',
            _CheckState.checking => 'Checking…',
            _ => 'Check again',
          }),
        ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(gutter, compact ? 12 : 24, gutter, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const WitorWordmark(),
                      const Spacer(),
                      IconButton(
                        tooltip: 'History',
                        onPressed: _state == _CheckState.checking
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HistoryPage(
                                    _history,
                                    onClear: () {
                                      setState(() {
                                        _report = null;
                                        _previous = null;
                                        _state = _CheckState.ready;
                                      });
                                    },
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.history_rounded),
                      ),
                      IconButton(
                        tooltip: 'Check settings',
                        onPressed: _state == _CheckState.checking
                            ? null
                            : _settings,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      IconButton(
                        tooltip: 'About witor',
                        onPressed: _showInfo,
                        icon: Icon(
                          Icons.info_outline_rounded,
                          size: 22,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 20 : 34),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: compact
                            ? Alignment.bottomLeft
                            : Alignment.centerLeft,
                        end: Alignment.topRight,
                        colors: dark
                            ? const [
                                Color(0xff202d34),
                                Color(0xff19383e),
                                Color(0xff1b484a),
                              ]
                            : const [
                                Color(0xfffbfdff),
                                Color(0xffedf7f6),
                                Color(0xffc8e8df),
                              ],
                      ),
                      border: Border.all(
                        color: colors.outlineVariant,
                        width: .8,
                      ),
                    ),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 156,
                                child: WitorHeroMark(dark: dark),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  26,
                                ),
                                child: intro,
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(44, 32, 24, 32),
                            child: Row(
                              children: [
                                Expanded(flex: 6, child: intro),
                                Expanded(
                                  flex: 5,
                                  child: SizedBox(
                                    height: 236,
                                    child: WitorHeroMark(dark: dark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  SizedBox(height: compact ? 30 : 40),
                  UiText(
                    'Connection details',
                    style: TextStyle(
                      fontSize: compact ? 22 : 25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.75,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.outlineVariant,
                        width: .8,
                      ),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.hub_outlined,
                          label: 'Network type',
                          value:
                              _state == _CheckState.complete &&
                                  _report?.data['offline'] != true
                              ? value
                              : uiLabel(context, value),
                          live: true,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 65),
                          child: Divider(),
                        ),
                        _DetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Last checked',
                          value: timestamp,
                        ),
                      ],
                    ),
                  ),
                  if (_storageNote != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_storageNote!),
                    ),
                  if (_state == _CheckState.complete && _report != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.analytics_outlined),
                        title: const UiText('Check report'),
                        subtitle: Text(
                          _report!.findings.isEmpty
                              ? 'View measurements and availability'
                              : '${_report!.findings.length} findings · View details',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportPage(
                              _report!,
                              previous: _previous,
                              current: _fresh,
                              onUpdate: (updated) async {
                                if (mounted) setState(() => _report = updated);
                                if (_options.remember) {
                                  await _history.save(updated);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.live = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: live,
      child: MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(icon, color: colors.primary, size: 18),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
