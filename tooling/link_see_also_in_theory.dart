// Insert or refresh "See also" blocks in theory.md using see_also.json.
// Usage:
//   dart run tooling/link_see_also_in_theory.dart [--module <id>] [--top N] [--dry-run] [--quiet]
// Prefers build/see_also.json; if missing, computes pairs in-memory like build_see_also.dart.
// ASCII-only. Exit 0 on success; 1 on I/O errors.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? onlyModule;
  int top = 5;
  bool dry = false;
  bool quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--top' && i + 1 < args.length) {
      final v = int.tryParse(args[++i]);
      if (v != null && v > 0) top = v;
    } else if (a == '--dry-run') {
      dry = true;
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final seeAlso = _loadSeeAlso(top: top);
  final modules = seeAlso.keys.toList()..sort();
  var ioError = false;

  for (final m in modules) {
    if (onlyModule != null && m != onlyModule) continue;
    final v1 = 'content/$m/v1';
    final theoryPath = '$v1/theory.md';
    final file = File(theoryPath);
    if (!file.existsSync()) {
      if (!quiet) {
        stdout.writeln('SEEALSO $m: linked=0, replaced=0, already=0, errors=1');
      }
      ioError = true;
      continue;
    }
    List<String> lines;
    try {
      lines = file.readAsLinesSync();
    } catch (_) {
      if (!quiet) {
        stdout.writeln('SEEALSO $m: linked=0, replaced=0, already=0, errors=1');
      }
      ioError = true;
      continue;
    }

    final suggestions = seeAlso[m] ?? const <_SA>[];
    final block = _renderBlock(m, suggestions);

    final res = _applyBlock(lines, block);
    if (!dry && (res.replaced || res.linked)) {
      try {
        file.writeAsStringSync(res.newLines.join('\n'));
      } catch (_) {
        ioError = true;
      }
    }
    if (!quiet) {
      stdout.writeln(
        'SEEALSO $m: linked=${res.linked ? suggestions.length : 0}, replaced=${res.replaced ? 1 : 0}, already=${res.already ? 1 : 0}, errors=${ioError ? 1 : 0}',
      );
    }
  }

  if (ioError) exitCode = 1;
}

class _ApplyResult {
  final List<String> newLines;
  final bool linked;
  final bool replaced;
  final bool already;
  _ApplyResult(this.newLines, this.linked, this.replaced, this.already);
}

_ApplyResult _applyBlock(List<String> lines, String block) {
  final idx = _findSeeAlsoStart(lines);
  if (idx == -1) {
    // Append block with a separating blank line
    final newLines = List<String>.from(lines);
    if (newLines.isNotEmpty && newLines.last.trim().isNotEmpty) {
      newLines.add('');
    }
    newLines.addAll(block.split('\n'));
    return _ApplyResult(newLines, true, false, false);
  }
  // Existing block: capture until a non-bullet or EOF
  var end = idx + 1;
  while (end < lines.length && lines[end].startsWith('- ')) end++;
  final existing = lines.sublist(idx, end).join('\n');
  // Compare by ids order (ignore scores)
  final exIds = _idsFromBlock(existing);
  final newIds = _idsFromBlock(block);
  if (exIds.join(',') == newIds.join(',')) {
    return _ApplyResult(lines, false, false, true);
  }
  final newLines = <String>[];
  newLines.addAll(lines.sublist(0, idx));
  newLines.addAll(block.split('\n'));
  newLines.addAll(lines.sublist(end));
  return _ApplyResult(newLines, false, true, false);
}

int _findSeeAlsoStart(List<String> lines) {
  for (var i = lines.length - 1; i >= 0; i--) {
    if (lines[i].trim() == 'See also') return i;
  }
  return -1;
}

List<String> _idsFromBlock(String block) {
  final ids = <String>[];
  for (final l in block.split('\n')) {
    if (l.startsWith('- ')) {
      final m = RegExp(
        r'^-\s+([a-z0-9_]+)\s+\(score\s+\d+\)\s+\u2192\s+\.\.\/\.\.\/([a-z0-9_]+)\/v1\/theory\.md\s*$',
      ).firstMatch(l);
      // Fallback: parse left id before space
      if (m != null) {
        ids.add(m.group(1)!);
      } else {
        final mm = RegExp(r'^-\s+([a-z0-9_]+)\b').firstMatch(l);
        if (mm != null) ids.add(mm.group(1)!);
      }
    }
  }
  return ids;
}

String _renderBlock(String module, List<_SA> items) {
  final b = StringBuffer();
  b.writeln('See also');
  for (final it in items) {
    b.writeln(
      '- ${it.module} (score ${it.score}) -> ../../${it.module}/v1/theory.md',
    );
  }
  return b.toString().trimRight();
}

class _SA {
  final String module;
  final int score;
  final List<String> sharedTokens;
  final List<String> sharedSpots;
  _SA(this.module, this.score, this.sharedTokens, this.sharedSpots);
}

Map<String, List<_SA>> _loadSeeAlso({required int top}) {
  final f = File('build/see_also.json');
  if (f.existsSync()) {
    try {
      final obj = jsonDecode(f.readAsStringSync());
      if (obj is Map<String, dynamic>) {
        final rows = obj['rows'];
        if (rows is List) {
          final out = <String, List<_SA>>{};
          for (final r in rows) {
            if (r is Map) {
              final m = r['module']?.toString() ?? '';
              final sa = <_SA>[];
              final list = r['see_also'];
              if (list is List) {
                for (final e in list) {
                  if (e is Map) {
                    sa.add(
                      _SA(
                        e['module']?.toString() ?? '',
                        (e['score'] is int) ? e['score'] as int : 0,
                        <String>[],
                        <String>[],
                      ),
                    );
                  }
                }
              }
              if (m.isNotEmpty)
                out[m] = (sa.length > top ? sa.sublist(0, top) : sa);
            }
          }
          if (out.isNotEmpty) return out;
        }
      }
    } catch (_) {}
  }
  // Fallback: compute in-memory
  final data = _scanIndex();
  final ids = data.keys.toList()..sort();
  final out = <String, List<_SA>>{};
  for (final a in ids) {
    final aT = data[a]!.tokens;
    final aS = data[a]!.spots;
    final items = <_SA>[];
    for (final b in ids) {
      if (a == b) continue;
      final bT = data[b]!.tokens;
      final bS = data[b]!.spots;
      final st = _intersectSorted(aT, bT);
      final ss = _intersectSorted(aS, bS);
      final score = 2 * st.length + ss.length;
      if (score <= 0) continue;
      items.add(_SA(b, score, st, ss));
    }
    items.sort((x, y) {
      final ds = y.score.compareTo(x.score);
      if (ds != 0) return ds;
      return x.module.compareTo(y.module);
    });
    out[a] = (items.length > top ? items.sublist(0, top) : items);
  }
  return out;
}

class _ModData {
  final List<String> tokens;
  final List<String> spots;
  _ModData(this.tokens, this.spots);
}

Map<String, _ModData> _scanIndex() {
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
