import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'report.dart';

class CheckHistory extends GeneratedDatabase {
  CheckHistory([QueryExecutor? executor])
    : super(
        executor ??
            LazyDatabase(() async {
              final directory = await getApplicationSupportDirectory();
              await directory.create(recursive: true);
              return NativeDatabase.createInBackground(
                File('${directory.path}/checks.sqlite'),
              );
            }),
      );
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(
        'CREATE TABLE checks (at TEXT PRIMARY KEY, payload TEXT NOT NULL)',
      );
    },
  );

  Future<void> save(CheckReport report) => transaction(() async {
    await customStatement(
      'INSERT OR REPLACE INTO checks(at,payload) VALUES (?,?)',
      [report.data['time'], jsonEncode(report.data)],
    );
    await customStatement(
      'DELETE FROM checks WHERE at IN (SELECT at FROM checks ORDER BY at DESC LIMIT -1 OFFSET 100)',
    );
  });
  Future<List<CheckReport>> recent() async {
    final rows = await customSelect(
      'SELECT payload FROM checks ORDER BY at DESC LIMIT 100',
    ).get();
    return rows
        .map((r) => CheckReport(jsonDecode(r.read<String>('payload')) as Json))
        .toList();
  }

  Future<void> clear() => customStatement('DELETE FROM checks');
}
