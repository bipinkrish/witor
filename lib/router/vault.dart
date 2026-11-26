import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RouterVault {
  const RouterVault();
  static const storage = FlutterSecureStorage();
  String _key(String device, String kind) =>
      'witor.$kind.${base64Url.encode(utf8.encode(device))}';
  Future<void> remember(String device, String user, String password) => storage
      .write(key: _key(device, 'login'), value: jsonEncode([user, password]));
  Future<List<String>?> readLogin(String device) async {
    final raw = await storage.read(key: _key(device, 'login'));
    if (raw == null) return null;
    return List<String>.from(jsonDecode(raw) as List);
  }

  Future<void> forget(String device) =>
      storage.delete(key: _key(device, 'login'));
  Future<void> backup(String device, Map<String, dynamic> config) =>
      storage.write(key: _key(device, 'backup'), value: jsonEncode(config));
  Future<Map<String, dynamic>?> readBackup(String device) async {
    final raw = await storage.read(key: _key(device, 'backup'));
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> clear() async {
    final all = await storage.readAll();
    for (final key in all.keys.where((key) => key.startsWith('witor.'))) {
      await storage.delete(key: key);
    }
  }
}
