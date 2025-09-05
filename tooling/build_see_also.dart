// Build "see also" suggestions between modules based on token/spot overlaps.
// Usage:
//   dart run tooling/build_see_also.dart
//   dart run tooling/build_see_also.dart --json build/see_also.json [--top N] [--quiet]
// Prefers build/search_index.json; otherwise scans content/*/v1/.
// Pure Dart, ASCII-only. Exit code always 0.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? jsonPath;
  var top = 5;
  var quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--json' && i + 1 < args.length) {
      jsonPath = args[++i];
    } else if (a == '--top' && i + 1 < args.length) {
      final v = int.tryParse(args[++i]);
      if (v != null && v > 0) top = v;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final data = _loadSearchData();
  final modules = data.keys.toList()..sort();

  final rows = <Map<String, dynamic>>[];
  for (final a in modules) {
    final aTokens = data[a]!.tokens;
    final aSpots = data[a]!.spots;
    final items = <Map<String, dynamic>>[];
    for (final b in modules) {
      if (b == a) continue;
      final bTokens = data[b]!.tokens;
      final bSpots = data[b]!.spots;
      final sharedTokens = _intersectSorted(aTokens, bTokens);
      final sharedSpots = _intersectSorted(aSpots, bSpots);
      final score = 2 * sharedTokens.length + sharedSpots.length;
      if (score <= 0) continue;
      items.add({
        'module': b,
        'score': score,
        'shared_tokens': sharedTokens,
        'shared_spot_kinds': sharedSpots,
      });
    }
    items.sort((x, y) {
      final ds = (y['score'] as int).compareTo(x['score'] as int);
      if (ds != 0) return ds;
      return (x['module'] as String).compareTo(y['module'] as String);
    });
    final truncated = items.length > top ? items.sublist(0, top) : items;
    rows.add({'module': a, 'see_also': truncated});
  }

  final payload = <String, dynamic>{
    'rows': rows,
    'summary': {'modules': modules.length},
  };

  if (jsonPath != null) {
    final f = File(jsonPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode(payload));
    if (!quiet) stdout.writeln('SEEALSO modules=${modules.length}');
  } else {
    stdout.writeln(jsonEncode(payload));
  }
}

class _ModData {
  final List<String> tokens; // sorted unique
  final List<String> spots; // sorted unique
  _ModData(this.tokens, this.spots);
}

Map<String, _ModData> _loadSearchData() {
  final idxFile = File('build/search_index.json');
  if (idxFile.existsSync()) {
    try {
      final obj = jsonDecode(idxFile.readAsStringSync());
      if (obj is Map<String, dynamic>) {
        final rows = obj['rows'];
        if (rows is List) {
          final map = <String, _ModData>{};
          for (final r in rows) {
            if (r is Map) {
              final m = r['module']?.toString() ?? '';
              final toks = <String>[];
              final sps = <String>[];
              final rt = r['tokens'];
              if (rt is List) {
                for (final t in rt) toks.add(t.toString());
              }
              final rs = r['spot_kinds'];
              if (rs is List) {
                for (final s in rs) sps.add(s.toString());
              }
              toks.sort();
              sps.sort();
              if (m.isNotEmpty) map[m] = _ModData(toks, sps);
            }
          }
          if (map.isNotEmpty) return map;
        }
      }
    } catch (_) {}
  }
  // Fallback scan
  final modules = _discoverModules();
  final out = <String, _ModData>{};
  for (final m in modules) {
    final v1 = 'content/$m/v1';
    final drillsPath = '$v1/drills.jsonl';
    final demosPath = '$v1/demos.jsonl';
    final tokens = _extractTokens(drillsPath).toList()..sort();
    final spots = <String>{}
      ..addAll(_extractSpotKinds(demosPath))
      ..addAll(_extractSpotKinds(drillsPath));
    final sList = spots.toList()..sort();
    out[m] = _ModData(tokens, sList);
  }
  return out;
}

List<String> _intersectSorted(List<String> a, List<String> b) {
  final setB = b.toSet();
  final out = <String>[];
  for (final x in a) {
    if (setB.contains(x)) out.add(x);
  }
  return out;
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
