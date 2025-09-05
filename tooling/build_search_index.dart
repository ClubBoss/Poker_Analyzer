// Build a search index for tokens and spot_kinds across modules.
// Usage:
//   dart run tooling/build_search_index.dart
//   dart run tooling/build_search_index.dart --json build/search_index.json
// Pure Dart, ASCII-only, deterministic ordering. Exit code always 0.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? jsonPath;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--json' && i + 1 < args.length) jsonPath = args[++i];
  }

  final modules = _discoverModules();
  final rows = <Map<String, dynamic>>[];
  final tokenToModules = <String, Set<String>>{};
  final spotToModules = <String, Set<String>>{};

  for (final m in modules) {
    final v1 = 'content/$m/v1';
    final drillsPath = '$v1/drills.jsonl';
    final demosPath = '$v1/demos.jsonl';

    final tokens = _extractTokens(drillsPath);
    final spotKinds = <String>{};
    spotKinds.addAll(_extractSpotKinds(demosPath));
    spotKinds.addAll(_extractSpotKinds(drillsPath));

    final tokList = tokens.toList()..sort();
    final skList = spotKinds.toList()..sort();

    rows.add({'module': m, 'tokens': tokList, 'spot_kinds': skList});

    for (final t in tokList) {
      tokenToModules.putIfAbsent(t, () => <String>{}).add(m);
    }
    for (final s in skList) {
      spotToModules.putIfAbsent(s, () => <String>{}).add(m);
    }
  }

  rows.sort((a, b) => (a['module'] as String).compareTo(b['module'] as String));

  final idxToken = <String, List<String>>{
    for (final e in tokenToModules.entries) e.key: (e.value.toList()..sort()),
  };
  final idxSpot = <String, List<String>>{
    for (final e in spotToModules.entries) e.key: (e.value.toList()..sort()),
  };

  final payload = <String, dynamic>{
    'rows': rows,
    'index': {'token_to_modules': idxToken, 'spotkind_to_modules': idxSpot},
    'summary': {
      'modules': modules.length,
      'unique_tokens': tokenToModules.length,
      'unique_spot_kinds': spotToModules.length,
    },
  };

  if (jsonPath != null) {
    final f = File(jsonPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode(payload));
    stdout.writeln(
      'SEARCH modules=${modules.length} tokens=${tokenToModules.length} spot_kinds=${spotToModules.length}',
    );
  } else {
    stdout.writeln(jsonEncode(payload));
  }
}

List<String> _discoverModules() {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
    final v1 = Directory('${e.path}/v1');
    if (v1.existsSync()) out.add(id);
  }
  out.sort();
  return out;
}

Set<String> _extractTokens(String path) {
  final out = <String>{};
  final f = File(path);
  if (!f.existsSync()) return out;
  for (final line in f.readAsLinesSync()) {
    final s = line.trim();
    if (s.isEmpty) continue;
    try {
      final obj = jsonDecode(s);
      if (obj is Map<String, dynamic>) {
        final targets = obj['targets'];
        if (targets is List) {
          for (final t in targets) {
            if (t is String) out.add(t);
          }
        } else {
          final tgt = obj['target'];
          if (tgt is List) {
            for (final t in tgt) {
              if (t is String) out.add(t);
            }
          } else if (tgt is String) {
            out.add(tgt);
          }
        }
      }
    } catch (_) {}
  }
  return out;
}

Set<String> _extractSpotKinds(String path) {
  final out = <String>{};
  final f = File(path);
  if (!f.existsSync()) return out;
  for (final line in f.readAsLinesSync()) {
    final s = line.trim();
    if (s.isEmpty) continue;
    try {
      final obj = jsonDecode(s);
      if (obj is Map<String, dynamic>) {
        final sk1 = obj['spot_kind'];
        final sk2 = obj['spotKind'];
        if (sk1 is String) out.add(sk1);
        if (sk2 is String) out.add(sk2);
      }
    } catch (_) {}
  }
  return out;
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}
