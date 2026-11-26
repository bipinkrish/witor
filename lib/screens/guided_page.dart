import 'package:witor/l10n/labels.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../router/observations.dart';
import '../diagnostics/finding.dart';
import 'guide_panel.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../router/router.dart';

/// Uses the subscriber's own UI. Network passwords remain inside the WebView.
class GuidedPage extends StatefulWidget {
  const GuidedPage({
    super.key,
    required this.uri,
    required this.family,
    required this.findings,
  });
  final List<Finding> findings;
  final Uri uri;
  final RouterFamily family;
  @override
  State<GuidedPage> createState() => _GuidedPageState();
}

class _GuidedPageState extends State<GuidedPage> {
  InAppWebViewController? controller;
  final observations = <Map<String, String>>[];
  Future<void> _read() async {
    try {
      final url = await controller?.getUrl();
      if (url == null ||
          url.scheme != widget.uri.scheme ||
          url.host != widget.uri.host ||
          url.port != widget.uri.port) {
        return;
      }
      final value = await controller?.evaluateJavascript(
        source: readVisibleRadio,
      );
      final parsed = value is String ? jsonDecode(value) : null;
      final fields = parsed is Map
          ? boaObservations(parsed)
          : <String, String>{};
      if (!mounted) return;
      if (fields.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open the Basic or Security settings page for a radio first.',
            ),
          ),
        );
        return;
      }
      final signature = jsonEncode(fields);
      if (!observations.any((v) => jsonEncode(v) == signature)) {
        setState(() => observations.add(fields));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Read ${fields.keys.join(', ')}.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This page did not expose supported radio controls.'),
          ),
        );
      }
    }
  }

  String? error;
  bool loading = true;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.family.label)),
    body: LayoutBuilder(
      builder: (context, available) => Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: available.maxHeight * .48),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GuidePanel(
                    familyGuide: widget.family.guide,
                    findings: [
                      ...routerFindings(observations),
                      ...widget.findings,
                    ],
                  ),
                  if (widget.family == RouterFamily.boa)
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: loading ? null : _read,
                          child: const UiText('Read visible settings'),
                        ),
                        if (observations.isNotEmpty)
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, observations),
                            child: Text(
                              'Use readings (${observations.length})',
                            ),
                          ),
                      ],
                    ),
                  if (loading && error == null) const LinearProgressIndicator(),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(error!),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InAppWebView(
              onWebViewCreated: (view) => controller = view,
              initialUrlRequest: URLRequest(url: WebUri(widget.uri.toString())),
              initialSettings: InAppWebViewSettings(
                incognito: true,
                useShouldOverrideUrlLoading: true,
                javaScriptCanOpenWindowsAutomatically: false,
                allowFileAccess: false,
                allowContentAccess: false,
              ),
              shouldOverrideUrlLoading: (controller, action) async {
                final url = action.request.url;
                final allowed =
                    url != null &&
                    url.scheme == widget.uri.scheme &&
                    url.host == widget.uri.host &&
                    url.port == widget.uri.port;
                if (!allowed && action.isForMainFrame && mounted) {
                  setState(() {
                    loading = false;
                    error =
                        'This page leads away from your router. Use the external browser if you want to continue.';
                  });
                }
                return allowed
                    ? NavigationActionPolicy.ALLOW
                    : NavigationActionPolicy.CANCEL;
              },
              onLoadStart: (c, url) {
                if (mounted) {
                  setState(() {
                    loading = true;
                    error = null;
                  });
                }
              },
              onLoadStop: (c, url) {
                if (mounted) setState(() => loading = false);
              },
              onReceivedError: (c, request, e) {
                if (request.isForMainFrame == true && mounted) {
                  setState(() {
                    error =
                        'The router page could not be loaded. Return to the router guide to open it in your browser.';
                    loading = false;
                  });
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}
