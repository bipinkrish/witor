import 'package:witor/l10n/labels.dart';
import 'package:flutter/material.dart';
import '../diagnostics/history.dart';
import '../diagnostics/report.dart';
import 'report_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage(this.history, {super.key, required this.onClear});
  final CheckHistory history;
  final VoidCallback onClear;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<CheckReport>> reports = widget.history.recent();
  Future<void> _clear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const UiText('Delete all saved checks?'),
        content: const UiText('This removes report history from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const UiText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const UiText('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await widget.history.clear();
      if (mounted) {
        widget.onClear();
        setState(() => reports = widget.history.recent());
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete history.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('History')),
    body: FutureBuilder<List<CheckReport>>(
      future: reports,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not read local history.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: UiText('Saved checks will appear here.'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (i, r) in items.indexed)
              ListTile(
                leading: const Icon(Icons.wifi),
                title: Text(r.link.name ?? r.network),
                subtitle: Text(r.time.toString().split('.').first),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportPage(
                      r,
                      previous: items
                          .skip(i + 1)
                          .where(r.comparable)
                          .firstOrNull,
                    ),
                  ),
                ),
              ),
            TextButton(
              onPressed: _clear,
              child: const UiText('Delete saved checks'),
            ),
          ],
        );
      },
    ),
  );
}
