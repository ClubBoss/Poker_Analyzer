// Compute unlockable modules from curriculum progression and status.
// Usage: dart run tooling/compute_unlocks.dart
// Pure Dart, ASCII-only, no external deps. Exit code always 0.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final ids = _readCurriculumIds();
  final idSet = ids.toSet();
  final prog = _readProgression();
  final status = _readStatus();

  final doneAll = status.modulesDone.toSet();
  final unknownDone = doneAll.where((e) => !idSet.contains(e)).toSet();
  final done = doneAll.where(idSet.contains).toSet();

  // Normalize prereqs: known ids only
  final prereqs = <String, List<String>>{
    for (final id in ids)
      id: (List<String>.from(prog.prereqs[id] ?? const <String>[])
        ..removeWhere((p) => !idSet.contains(p))),
  };

  // Unlockable if all prereqs are in done and not already done
  final unlockable = <String>[];
  final locked = <String>[];
  for (final id in ids) {
    if (done.contains(id)) continue;
    final pr = prereqs[id] ?? const <String>[];
    final ok = pr.every(done.contains);
    if (ok) {
      unlockable.add(id);
    } else {
      locked.add(id);
    }
  }

  int sumWeights(Iterable<String> list) {
    var s = 0;
    for (final id in list) {
      final w = prog.weights[id];
      if (w is int) s += w;
    }
    return s;
  }

  final weightsDone = sumWeights(done);
  final weightsUnlock = sumWeights(unlockable);

  // Output (deterministic)
  stdout.writeln('UNLOCK');
  stdout.writeln('TOTAL ${ids.length}');
  stdout.writeln('DONE ${done.length}');
  stdout.writeln('UNLOCKABLE ${unlockable.length}');
  stdout.writeln('LOCKED ${locked.length}');
  stdout.writeln('UNKNOWN_DONE ${unknownDone.length}');
  stdout.writeln('UNLOCK_LIST ${_fmtList(unlockable)}');
  stdout.writeln('LOCKED_SAMPLE ${_fmtList(locked)}');
  stdout.writeln('WEIGHTS_DONE $weightsDone');
  stdout.writeln('WEIGHTS_UNLOCKABLE $weightsUnlock');
}

String _fmtList(List<String> xs) {
  if (xs.isEmpty) return '-';
  final take = xs.take(20).join(',');
  return take.isEmpty ? '-' : take;
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
