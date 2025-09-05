// Export per-module progression badges (status + weights + prereqs).
// Usage:
//   dart run tooling/export_progression_badges.dart
//   dart run tooling/export_progression_badges.dart --json build/badges.json
// Pure Dart, ASCII-only, no external deps. Exit code always 0.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? jsonPath;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--json' && i + 1 < args.length) {
      jsonPath = args[++i];
    }
  }

  final ids = _readCurriculumIds();
  final idSet = ids.toSet();
  final prog = _readProgression();
  final status = _readStatus();

  final done = status.modulesDone.where(idSet.contains).toSet();

  final prereqs = <String, List<String>>{
    for (final id in ids)
      id: (List<String>.from(prog.prereqs[id] ?? const <String>[])
        ..removeWhere((p) => !idSet.contains(p))),
  };

  // Find the first pending module in curriculum order whose prereqs are done
  String nextId = '-';
  for (final id in ids) {
    if (done.contains(id)) continue;
    final pr = prereqs[id] ?? const <String>[];
    final ok = pr.every(done.contains);
    if (ok) {
      nextId = id;
      break;
    }
  }

  final rows = <Map<String, dynamic>>[];
  var cntDone = 0, cntUnlock = 0, cntLocked = 0;
  var weightsDone = 0, weightsUnlock = 0;
  for (final id in ids) {
    final pr = prereqs[id] ?? const <String>[];
    final weight = prog.weights[id] ?? 0;
    String st;
    if (done.contains(id)) {
      st = 'done';
      cntDone++;
      weightsDone += weight;
    } else {
      final ok = pr.every(done.contains);
      if (ok && id == nextId) {
        st = 'next';
      } else if (ok) {
        st = 'unlockable';
        cntUnlock++;
        weightsUnlock += weight;
      } else {
        st = 'locked';
        cntLocked++;
      }
    }
    rows.add({'module': id, 'status': st, 'weight': weight, 'prereqs': pr});
  }

  final payload = <String, dynamic>{
    'rows': rows,
    'summary': {
      'total': ids.length,
      'done': cntDone,
      'unlockable': cntUnlock,
      'locked': cntLocked,
      'next': nextId,
      'weights_done': weightsDone,
      'weights_unlockable': weightsUnlock,
    },
  };

  if (jsonPath != null) {
    final f = File(jsonPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode(payload));
    stdout.writeln(
      'BADGES total=${ids.length} done=$cntDone unlockable=$cntUnlock locked=$cntLocked next=$nextId',
    );
  } else {
    stdout.writeln(jsonEncode(payload));
  }
}

class _Prog {
  final Map<String, int> weights;
  final Map<String, List<String>> prereqs;
  _Prog(this.weights, this.prereqs);
}

_Prog _readProgression() {
  final f = File('tooling/curriculum_progression.json');
  if (!f.existsSync()) return _Prog(<String, int>{}, <String, List<String>>{});
  try {
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is! Map<String, dynamic>)
      return _Prog(<String, int>{}, <String, List<String>>{});
    final w = <String, int>{};
    final p = <String, List<String>>{};
    final wo = obj['weights'];
    if (wo is Map) {
      for (final e in wo.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is int) w[k] = v;
      }
    }
    final po = obj['prereqs'];
    if (po is Map) {
      for (final e in po.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is List) {
          final lst = <String>[];
          for (final x in v) {
            if (x is String) lst.add(x.trim());
          }
          p[k] = lst;
        }
      }
    }
    return _Prog(w, p);
  } catch (_) {
    return _Prog(<String, int>{}, <String, List<String>>{});
  }
}

class _Status {
  final List<String> modulesDone;
  _Status(this.modulesDone);
}

_Status _readStatus() {
  final f = File('curriculum_status.json');
  if (!f.existsSync()) return _Status(<String>[]);
  try {
    final raw = f.readAsStringSync();
    final sb = StringBuffer();
    for (final line in raw.split('\n')) {
      final t = line.trimLeft();
      if (t.startsWith('//') || t.startsWith('#')) continue;
      sb.writeln(line);
    }
    final obj = jsonDecode(sb.toString());
    if (obj is Map<String, dynamic>) {
      final arr = obj['modules_done'];
      if (arr is List) {
        final set = <String>{};
        for (final e in arr) {
          if (e is String) set.add(e.trim());
        }
        return _Status(set.toList());
      }
    }
  } catch (_) {
    // ignore
  }
  return _Status(<String>[]);
}

List<String> _readCurriculumIds() {
  try {
    final text = File('tooling/curriculum_ids.dart').readAsStringSync();
    final rrK = RegExp(
      r'const\s+List<String>\s+kCurriculumIds\s*=\s*\[(.*?)\];',
      dotAll: true,
    );
    final rrC = RegExp(
      r'const\s+List<String>\s+curriculumIds\s*=\s*\[(.*?)\];',
      dotAll: true,
    );
    final m = rrK.firstMatch(text) ?? rrC.firstMatch(text);
    if (m == null) return <String>[];
    final body = m.group(1)!;
    final lit = RegExp('["\\\']([^"\\\']+)["\\\']');
    final out = <String>[];
    for (final mm in lit.allMatches(body)) {
      final v = mm.group(1)!.trim();
      if (v.isNotEmpty) out.add(v);
    }
    return out;
  } catch (_) {
    return <String>[];
  }
}
