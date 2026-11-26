import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../brand.dart';
import '../diagnostics/report.dart';
import '../l10n/labels.dart';

class ComparisonPage extends StatelessWidget {
  const ComparisonPage({super.key, required this.after, this.before});
  final CheckReport after;
  final CheckReport? before;

  static String _number(num n) =>
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final base = before;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? const Color(0xff8ae1ce) : const Color(0xff006958);
    final speed = <(String, num?, num?)>[
      (
        'Wi-Fi link rate',
        base?.link.fields['txRate'] as num?,
        after.link.fields['txRate'] as num?,
      ),
      ('Download', base?.metric('down'), after.metric('down')),
      ('Upload', base?.metric('up'), after.metric('up')),
    ].where((r) => r.$2 != null && r.$3 != null).toList();
    final maxSpeed = speed.fold<num>(
      0,
      (max, r) => math.max(max, math.max(r.$2!, r.$3!)),
    );
    final locale = MaterialLocalizations.of(context);
    final day = locale.formatMediumDate(after.time);
    return Scaffold(
      appBar: AppBar(title: const WitorWordmark()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 48),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    [
                      after.link.name ?? after.network,
                      after.link.band,
                      day,
                    ].nonNulls.join('  ·  '),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 7),
                  UiText(
                    'Before and after',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (base == null)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: Icon(
                          Icons.bookmark_border_rounded,
                          color: colors.primary,
                        ),
                        title: const UiText('Your baseline check'),
                        subtitle: const UiText(
                          'Run another check on this access point after making a change to see both measurements here.',
                        ),
                      ),
                    )
                  else ...[
                    if (speed.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: dark
                                ? const [Color(0xff193a38), Color(0xff15282a)]
                                : const [Color(0xffe2f6ed), Color(0xfff0f7f7)],
                          ),
                        ),
                        child: Builder(
                          builder: (_) {
                            final (label, oldValue, newValue) = speed.first;
                            final old = oldValue!, current = newValue!;
                            final delta = current - old;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.speed_rounded, color: accent),
                                    const SizedBox(width: 9),
                                    Flexible(
                                      child: UiText(
                                        label,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _number(current),
                                        style: theme.textTheme.displayLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -2,
                                            ),
                                      ),
                                      TextSpan(
                                        text: '  Mbps',
                                        style: theme.textTheme.titleLarge,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${delta > 0 ? '+' : ''}${_number(delta)} Mbps  ·  ${uiLabel(context, 'Before')} ${_number(old)} Mbps',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: accent,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (speed.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          UiText(
                            'Speed comparison',
                            style: theme.textTheme.titleLarge,
                          ),
                          Wrap(
                            spacing: 16,
                            children: [
                              _Legend('Before', colors.outline),
                              _Legend('After', accent),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              for (final (label, old, current) in speed) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      UiText(
                                        label,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 6),
                                      for (final (name, value, tint) in [
                                        ('Before', old!, colors.outline),
                                        ('After', current!, accent),
                                      ])
                                        Semantics(
                                          label:
                                              '${uiLabel(context, name)} ${_number(value)} Mbps',
                                          excludeSemantics: true,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: FractionallySizedBox(
                                                    widthFactor: maxSpeed > 0
                                                        ? (value / maxSpeed)
                                                              .clamp(0, 1)
                                                              .toDouble()
                                                        : 0,
                                                    child: Container(
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: tint,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: 96,
                                                child: Text(
                                                  '${_number(value)} Mbps',
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (label != speed.last.$1)
                                  const Divider(height: 1),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  UiText('Measurements', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final first = base?.readings ?? {};
                      final last = after.readings;
                      return Table(
                        columnWidths: const {0: FlexColumnWidth(1.5)},
                        children: [
                          for (final row in [
                            [
                              uiLabel(context, 'Measurement'),
                              if (base != null) uiLabel(context, 'Before'),
                              uiLabel(
                                context,
                                base == null ? 'Baseline' : 'After',
                              ),
                            ],
                            for (final key in {...last.keys, ...first.keys})
                              [
                                uiLabel(context, key),
                                if (base != null) first[key] ?? '—',
                                last[key] ?? '—',
                              ],
                          ])
                            TableRow(
                              children: [
                                for (final text in row)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 4,
                                    ),
                                    child: Text(text),
                                  ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: 5),
      UiText(label),
    ],
  );
}
