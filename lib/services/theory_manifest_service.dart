// lib/services/theory_manifest_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'theory_yaml_canonicalizer.dart';

class ManifestEntry {
  final String algo;
  final String hash;
  final int ver;
  final DateTime ts;

  ManifestEntry({
    required this.algo,
    required this.hash,
    required this.ver,
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
        'algo': algo,
        'hash': hash,
        'ver': ver,
        'ts': ts.toIso8601String(),
      };

  static ManifestEntry fromJson(Map<String, dynamic> json) => ManifestEntry(
        algo: json['algo'] as String,
        hash: json['hash'] as String,
        ver: json['ver'] as int,
        ts: DateTime.parse(json['ts'] as String),
      );
}

class TheoryManifestService {
  TheoryManifestService({String? path}) : _path = path ?? 'theory_manifest.json';

  final String _path;
  int version = 1;
  final Map<String, ManifestEntry> files = {};

  Future<void> load() async {
    final f = File(_path);
    if (!await f.exists()) return;
    final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    version = map['version'] as int? ?? 1;
    final fileMap = map['files'] as Map<String, dynamic>? ?? {};
    files
      ..clear()
      ..addAll(fileMap.map((k, v) => MapEntry(k, ManifestEntry.fromJson(v))));
  }

  Future<void> save() async {
    final f = File(_path);
    final map = {
      'version': version,
      'files': files.map((k, v) => MapEntry(k, v.toJson())),
    };
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(map));
  }

  Future<Map<String, ManifestEntry>> _scan(List<String> dirs) async {
    final result = <String, ManifestEntry>{};
    for (final dir in dirs) {
      final d = Directory(dir);
      if (!await d.exists()) continue;
      for (final f in d
          .listSync(recursive: true)
          .whereType<File>()
          .where((e) => e.path.endsWith('.yaml'))) {
        final rel = p.relative(f.path);
        final lines = await f.readAsLines();
        final body = lines.skip(1).join('\n');
        final map =
            jsonDecode(jsonEncode(loadYaml(body))) as Map<String, dynamic>;
        final canon = const TheoryYamlCanonicalizer().canonicalize(map);
        final hash = sha256.convert(utf8.encode(canon)).toString();
        final header = lines.isEmpty ? '' : lines.first;
        final verMatch = RegExp(r'x-ver:\s*(\d+)').firstMatch(header);
        final ver = verMatch == null ? 0 : int.parse(verMatch.group(1)!);
        final stat = await f.stat();
        result[rel] = ManifestEntry(
          algo: 'sha256-canon@v1',
          hash: hash,
          ver: ver,
          ts: stat.modified,
        );
      }
    }
    return result;
  }

  Future<void> generate(List<String> dirs) async {
    files
      ..clear()
      ..addAll(await _scan(dirs));
  }

  Future<void> update(List<String> dirs) async {
    files.addAll(await _scan(dirs));
  }

  ManifestEntry? entry(String relPath) => files[relPath];

  void updateEntry(String relPath, ManifestEntry entry) {
    files[relPath] = entry;
  }
}

