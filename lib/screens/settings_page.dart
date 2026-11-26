import 'package:witor/l10n/labels.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/vault.dart';

class CheckOptions {
  const CheckOptions({
    this.detailed = true,
    this.internet = false,
    this.speed = false,
    this.remember = true,
    this.provider = 'Cloudflare',
  });
  final bool detailed, internet, speed, remember;
  final String provider;
  static Future<CheckOptions> load() async {
    final p = await SharedPreferences.getInstance();
    return CheckOptions(
      detailed: p.getBool('detailed') ?? true,
      internet: p.getBool('internet') ?? false,
      speed: p.getBool('speed') ?? false,
      remember: p.getBool('remember') ?? true,
      provider: p.getString('provider') ?? 'Cloudflare',
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    for (final e in {
      'detailed': detailed,
      'internet': internet,
      'speed': speed,
      'remember': remember,
    }.entries) {
      if (!await p.setBool(e.key, e.value)) {
        throw StateError('Could not save preferences');
      }
    }
    await p.setString('provider', provider);
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage(this.options, {super.key});
  final CheckOptions options;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool detailed = widget.options.detailed,
      internet = widget.options.internet,
      speed = widget.options.speed,
      remember = widget.options.remember;
  late String provider = widget.options.provider;
  bool saving = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Check settings')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                SwitchListTile(
                  title: const UiText('Wi-Fi details'),
                  subtitle: const UiText(
                    'Read the link and nearby access points where supported. Your operating system may request location access to identify networks.',
                  ),
                  value: detailed,
                  onChanged: (v) => setState(() => detailed = v),
                ),
                SwitchListTile(
                  title: const UiText('Internet measurements'),
                  subtitle: const UiText(
                    'Time a system DNS lookup for speed.cloudflare.com and connections to Cloudflare at 1.1.1.1. Leave off for a local-only check.',
                  ),
                  value: internet,
                  onChanged: (v) => setState(() => internet = v),
                ),
                SwitchListTile(
                  title: const UiText('Measure throughput'),
                  subtitle: Text(
                    provider == 'M-Lab NDT7'
                        ? 'M-Lab publishes test measurements and your public IP. Each direction transfers up to about 32 MiB.'
                        : 'Download 4 MiB and upload 1 MiB to Cloudflare per check. Your public IP is visible to the provider.',
                  ),
                  value: internet && speed,
                  onChanged: internet ? (v) => setState(() => speed = v) : null,
                ),
                if (internet && speed)
                  DropdownButtonFormField<String>(
                    initialValue: provider,
                    decoration: const InputDecoration(
                      labelText: 'Speed-test provider',
                    ),
                    items: [
                      for (final name in ['Cloudflare', 'M-Lab NDT7'])
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: (v) => setState(() => provider = v!),
                  ),
                SwitchListTile(
                  title: const UiText('Save checks on this device'),
                  subtitle: const UiText(
                    'Keep the latest 100 reports, including Wi-Fi names. Delete stored reports from History.',
                  ),
                  value: remember,
                  onChanged: (v) => setState(() => remember = v),
                ),
                TextButton(
                  onPressed: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const UiText(
                          'Delete all saved router accounts and backups?',
                        ),
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
                      await const RouterVault().clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved router data deleted.'),
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device keychain is unavailable.'),
                          ),
                        );
                      }
                    }
                  },
                  child: const UiText('Delete saved router data'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          final options = CheckOptions(
                            detailed: detailed,
                            internet: internet,
                            speed: speed,
                            remember: remember,
                            provider: provider,
                          );
                          try {
                            await options.save();
                            if (context.mounted) {
                              Navigator.pop(context, options);
                            }
                          } catch (_) {
                            if (context.mounted) {
                              setState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not save settings.'),
                                ),
                              );
                            }
                          }
                        },
                  child: const UiText('Save settings'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
