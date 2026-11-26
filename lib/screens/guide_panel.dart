import 'package:flutter/material.dart';
import '../diagnostics/finding.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';

class GuidePanel extends StatefulWidget {
  const GuidePanel({
    super.key,
    required this.familyGuide,
    required this.findings,
  });
  final String familyGuide;
  final List<Finding> findings;
  @override
  State<GuidePanel> createState() => _GuidePanelState();
}

class _GuidePanelState extends State<GuidePanel> {
  List<Finding>? activeSteps;
  int index = 0;
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final steps = activeSteps;
    final available = routerGuideSteps(widget.findings);
    final done = steps != null && index == steps.length;
    final step = steps != null && !done ? steps[index] : null;
    final accent = theme.brightness == Brightness.dark
        ? const Color(0xff8ae1ce)
        : const Color(0xff006958);
    final heading =
        step?.setting?.label ??
        (done ? 'Save and recheck' : 'Wireless settings guide');
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: accent, size: 19),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step != null
                              ? AppLocalizations.of(
                                  context,
                                )!.guideProgress(index + 1, steps!.length)
                              : uiLabel(context, 'Guided setup'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: uiLabel(
                          context,
                          expanded ? 'Hide guide' : 'Show guide',
                        ),
                        icon: Icon(
                          expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                        onPressed: () => setState(() => expanded = !expanded),
                      ),
                    ],
                  ),
                  if (steps != null && !done)
                    Row(
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                right: i == steps.length - 1 ? 0 : 4,
                              ),
                              height: 3,
                              decoration: BoxDecoration(
                                color: i <= index
                                    ? accent
                                    : colors.outlineVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (expanded) ...[
                    const SizedBox(height: 8),
                    UiText(
                      heading,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (step != null) ...[
                      UiText(
                        step.setting!.location,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.evidence,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(step.action, style: theme.textTheme.bodyMedium),
                    ] else if (done)
                      const UiText(
                        'Review your selections on the router page and save the changes you want. Reconnect to this Wi-Fi, then run Check again in witor to compare the results.',
                      )
                    else ...[
                      Text(widget.familyGuide),
                      if (available.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: UiText(
                            'After signing in, start the steps for your check. Note the original settings before editing.',
                          ),
                        ),
                    ],
                    if (steps != null || available.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (steps != null)
                            TextButton(
                              onPressed: () => setState(() {
                                if (index == 0) {
                                  activeSteps = null;
                                } else {
                                  index--;
                                }
                              }),
                              child: const UiText('Back'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => setState(() {
                              if (steps == null) {
                                activeSteps = available;
                                index = 0;
                              } else if (done) {
                                activeSteps = null;
                                index = 0;
                              } else {
                                index++;
                              }
                            }),
                            child: UiText(
                              steps == null
                                  ? 'Start steps'
                                  : done
                                  ? 'Finish guide'
                                  : index == steps.length - 1
                                  ? 'Review changes'
                                  : 'Next step',
                            ),
                          ),
                        ],
                      ),
                    ],
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
