import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Entry representing a previously injected cluster for a user.
class _PathRegistryEntry {
  final String userId;
  final String clusterHash;
  final DateTime ts;

  _PathRegistryEntry({
    required this.userId,
    required this.clusterHash,
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'clusterHash': clusterHash,
        'ts': ts.toIso8601String(),
      };

  static _PathRegistryEntry fromJson(Map<String, dynamic> json) =>
      _PathRegistryEntry(
        userId: json['userId'] as String,
        clusterHash: json['clusterHash'] as String,
        ts: DateTime.parse(json['ts'] as String),
      );
}

/// Simple file-backed registry to keep track of recent path injections.
class PathRegistry {
  final String path;

  const PathRegistry({this.path = 'autogen_cache/path_registry.json'});

  Future<List<_PathRegistryEntry>> _load() async {
    final file = File(path);
    if (!file.existsSync()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final data = jsonDecode(raw) as List;
    return data.map((e) => _PathRegistryEntry.fromJson(e)).toList();
  }

  Future<void> _save(List<_PathRegistryEntry> entries) async {
    final file = File(path);
    file.parent.createSync(recursive: true);
    final data = entries.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> record(String userId, List<String> tags) async {
    final entries = await _load();
    final hash = hashTags(tags);
    entries.add(_PathRegistryEntry(
        userId: userId, clusterHash: hash, ts: DateTime.now()));
    await _save(entries);
  }

  Future<bool> hasRecent(
      String userId, String clusterHash, Duration within) async {
    final entries = await _load();
    final cutoff = DateTime.now().subtract(within);
    return entries.any((e) =>
        e.userId == userId &&
        e.clusterHash == clusterHash &&
        e.ts.isAfter(cutoff));
  }

  Future<int> countSince(String userId, DateTime since) async {
    final entries = await _load();
    return entries
        .where((e) => e.userId == userId && e.ts.isAfter(since))
        .length;
  }

  static String hashTags(List<String> tags) {
    final sorted = List<String>.from(tags)..sort();
    return md5.convert(utf8.encode(sorted.join('|'))).toString();
  }
}
