import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/widgets.dart' as pw;
import 'report.dart';

Future<Uint8List> reportBytes(
  CheckReport report,
  CheckReport? before, {
  required bool pdf,
}) async {
  final readings = report.readings;
  final previous = before?.readings;
  final Uint8List bytes;
  if (pdf) {
    final document = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
        ),
        bold: pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
        ),
        fontFallback: [
          pw.Font.ttf(
            await rootBundle.load(
              'assets/fonts/NotoSansDevanagari-Regular.ttf',
            ),
          ),
        ],
      ),
    );
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(level: 0, text: 'witor | Wi-Fi report'),
          pw.Text('Checked ${report.time.toIso8601String()}'),
          if (before != null)
            pw.Text('Compared with ${before.time.toIso8601String()}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Measurement', if (previous != null) 'Before', 'Current'],
            data: [
              for (final key in {...?previous?.keys, ...readings.keys})
                [
                  key,
                  if (previous != null) previous[key] ?? '-',
                  readings[key] ?? '-',
                ],
            ],
          ),
          for (final f in report.findings) ...[
            pw.Header(level: 2, text: f.title),
            pw.Text(f.evidence),
            pw.Text(f.action),
          ],
          for (final e in report.notes.entries)
            pw.Paragraph(text: '${e.key}: ${e.value}'),
        ],
      ),
    );
    bytes = await document.save();
  } else {
    bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert({
          'checkedAt': report.data['time'],
          'readings': readings,
          'notes': report.notes,
          if (before != null)
            'before': {'checkedAt': before.data['time'], 'readings': previous},
          'findings': [
            for (final f in report.findings)
              {'finding': f.title, 'evidence': f.evidence, 'action': f.action},
          ],
        }),
      ),
    );
  }
  return bytes;
}

Future<String?> exportCheck(
  CheckReport report,
  CheckReport? before, {
  required bool pdf,
}) async {
  final bytes = await reportBytes(report, before, pdf: pdf);
  final name = 'witor-${report.time.toUtc().millisecondsSinceEpoch}';
  final mime = pdf ? MimeType.pdf : MimeType.json;
  final extension = pdf ? 'pdf' : 'json';
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows) {
    return FileSaver.instance.saveAs(
      name: name,
      bytes: bytes,
      fileExtension: extension,
      mimeType: mime,
    );
  }
  return FileSaver.instance.saveFile(
    name: name,
    bytes: bytes,
    fileExtension: extension,
    mimeType: mime,
  );
}
