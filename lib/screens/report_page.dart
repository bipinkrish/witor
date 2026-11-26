import 'package:witor/l10n/labels.dart';
import 'package:flutter/material.dart';
import '../diagnostics/export.dart';
import '../diagnostics/network_probe.dart';
import '../diagnostics/report.dart';
import 'router_page.dart';
import 'comparison_page.dart';
import '../router/router.dart';

class ReportPage extends StatefulWidget {
  const ReportPage(
    this.report, {
    super.key,
    this.previous,
    this.onUpdate,
    this.current = false,
  });
  final CheckReport report;
  final Future<void> Function(CheckReport)? onUpdate;
  final CheckReport? previous;
  final bool current;
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late CheckReport report = widget.report;
  bool exporting = false;
  Future<void> _export(bool pdf) async {
    setState(() => exporting = true);
    try {
      final path = await exportCheck(report, widget.previous, pdf: pdf);
      if (mounted && path != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved report · $path')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save the report. Choose another destination.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previous = widget.previous;
    final findings = report.findings;
    final theme = Theme.of(context);
    final neighbours = report.nearby.toList()
      ..sort((a, b) => (b.rssi ?? -150).compareTo(a.rssi ?? -150));
    return Scaffold(
      appBar: AppBar(
        title: const UiText('Check report'),
        actions: [
          PopupMenuButton<bool>(
            tooltip: 'Export report',
            enabled: !exporting,
            onSelected: _export,
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: UiText('Save PDF')),
              PopupMenuItem(value: false, child: UiText('Save JSON')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    report.link.name ?? report.network,
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(report.time.toString().split('.').first),
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.bar_chart_rounded),
                          title: const UiText('Before and after'),
                          subtitle: UiText(
                            previous == null
                                ? 'View your baseline check'
                                : 'Compare these two checks',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ComparisonPage(
                                before: previous,
                                after: report,
                              ),
                            ),
                          ),
                        ),
                        if (widget.current &&
                            privateGateway(report.gateway)) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.router_outlined),
                            title: const UiText('Router admin sign-in'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final result =
                                  await Navigator.push<
                                    ({
                                      List<Map<String, String>> radios,
                                      RouterSurvey? survey,
                                    })
                                  >(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RouterPage(
                                        report.gateway!,
                                        findings: findings,
                                        expectedBssid: report.link.id,
                                        expectedSsid: report.link.name,
                                      ),
                                    ),
                                  );
                              if (!mounted || result == null) return;
                              setState(
                                () => report = CheckReport({
                                  ...report.data,
                                  'routerRadios': result.radios,
                                  if (result.survey != null)
                                    'routerSurvey': result.survey!.data,
                                }),
                              );
                              try {
                                await widget.onUpdate?.call(report);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Readings added to this view. History could not be updated.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  UiText('Findings', style: theme.textTheme.titleLarge),
                  if (findings.isEmpty)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_outline),
                      title: UiText(
                        'No issue found in the available measurements.',
                      ),
                    ),
                  for (final f in findings)
                    Card(
                      child: ExpansionTile(
                        title: UiText(f.title),
                        subtitle: Text(f.evidence),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(f.action),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  UiText('Measurements', style: theme.textTheme.titleLarge),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Table(
                        columnWidths: const {0: FlexColumnWidth(1.2)},
                        children: [
                          for (final entry in report.readings.entries)
                            _row([entry.key, entry.value]),
                        ],
                      ),
                    ),
                  ),
                  if (neighbours.isNotEmpty)
                    Card(
                      child: ExpansionTile(
                        title: Text(
                          'Nearby access points · ${neighbours.length}',
                        ),
                        children: [
                          for (final n in neighbours)
                            ListTile(
                              title: Text(
                                (n.name ?? '').isEmpty
                                    ? 'Hidden network'
                                    : n.name!,
                              ),
                              subtitle: Text(
                                [
                                  n.band,
                                  if (n.channel != null) 'Channel ${n.channel}',
                                  if (n.fields['ageSeconds'] is num)
                                    "${n.fields['ageSeconds']} s old",
                                ].nonNulls.join(' · '),
                              ),
                              trailing: Text(n.signal ?? '—'),
                            ),
                        ],
                      ),
                    ),
                  if (report.data['routerSurvey'] case final Map survey)
                    Card(
                      child: ExpansionTile(
                        title: const Text('Wi-Fi measured at the router'),
                        children: [
                          if (survey['clientCount'] != null)
                            ListTile(
                              title: Text(
                                "Wireless clients seen: ${survey['clientCount']}",
                              ),
                            ),
                          for (final ap in report.routerNearby)
                            ListTile(
                              title: Text(ap.name ?? 'Hidden network'),
                              subtitle: Text(
                                [
                                  ap.band,
                                  if (ap.channel != null)
                                    'Channel ${ap.channel}',
                                  ap.signal,
                                ].nonNulls.join(' · '),
                              ),
                            ),
                          for (final note
                              in (survey['notes'] as List? ?? [])
                                  .whereType<String>())
                            ListTile(title: Text(note)),
                        ],
                      ),
                    ),
                  if (report.routerRadios.isNotEmpty)
                    Card(
                      child: ExpansionTile(
                        title: const UiText('Router configuration'),
                        children: [
                          for (final radio in report.routerRadios)
                            ListTile(
                              title: SelectableText(
                                radio.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' · '),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (report.notes.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    UiText(
                      'Measurement notes',
                      style: theme.textTheme.titleLarge,
                    ),
                    for (final e in report.notes.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.key),
                        subtitle: Text(e.value),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _row(List<String> cells, {bool heading = false}) => TableRow(
    children: [
      for (final c in cells)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            c,
            style: heading
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ),
    ],
  );
}
