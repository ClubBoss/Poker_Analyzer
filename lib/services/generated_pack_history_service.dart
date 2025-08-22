import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GeneratedPackHistoryService {
  static const _key = 'generated_pack_history';

  static Future<void> logPack({
    required String id,
    required String name,
    required String type,
    required DateTime ts,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    final info = GeneratedPackInfo(id: id, name: name, type: type, ts: ts);
    list.insert(0, jsonEncode(info.toJson()));
    if (list.length > 50) list.removeRange(50, list.length);
    await prefs.setStringList(_key, list);
  }

  static Future<List<GeneratedPackInfo>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return [
      for (final e in list)
        GeneratedPackInfo.fromJson(jsonDecode(e) as Map<String, dynamic>),
    ];
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class GeneratedPackInfo {
  final String id;
  final String name;
  final String type;
  final DateTime ts;

  GeneratedPackInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'ts': ts.toIso8601String(),
  };

  factory GeneratedPackInfo.fromJson(Map<String, dynamic> j) =>
      GeneratedPackInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        ts: DateTime.parse(j['ts'] as String),
      );
}
