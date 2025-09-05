// Validate curriculum progression structure and print a summary.
// Usage: dart run tooling/validate_progression.dart
// Pure Dart, ASCII-only, no external deps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final ids = _readCurriculumIds();
  final data = _readProgression();

  final idSet = ids.toSet();
  final weights = data.weights;
  final prereqs = data.prereqs;

  // Unknown ids collection (keys and referenced prereqs)
  final unknown = <String>{};
  for (final k in weights.keys) {
    if (!idSet.contains(k)) unknown.add(k);
  }
  for (final k in prereqs.keys) {
    if (!idSet.contains(k)) unknown.add(k);
    for (final p in prereqs[k]!) {
      if (!idSet.contains(p)) unknown.add(p);
    }
  }

  // Count edges (all listed prereqs, including unknown)
  var edgeCount = 0;
  for (final v in prereqs.values) edgeCount += v.length;

  // Normalize prereqs to known ids only
  final prKnown = <String, List<String>>{
    for (final id in ids)
      id: (List<String>.from(prereqs[id] ?? const <String>[])
        ..removeWhere((p) => !idSet.contains(p))),
  };

  // Cycle detection on graph: module -> prereqs
  final cycleNodes = _detectCycles(ids, prKnown);

  // Roots: ids with no prereqs
  final roots = ids
      .where((id) => (prKnown[id] ?? const <String>[]).isEmpty)
      .toList();

  // Reachability from roots using edges prereq -> module (invert dependency)
  final deps = <String, List<String>>{for (final id in ids) id: <String>[]};
  for (final m in ids) {
    for (final p in prKnown[m]!) {
      deps[p]!.add(m);
    }
  }
  final reachable = <String>{};
  void dfsReach(String s) {
    if (!reachable.add(s)) return;
    for (final v in deps[s]!) dfsReach(v);
  }

  for (final r in roots) dfsReach(r);
  final unreachable = ids.where((id) => !reachable.contains(id)).toList();

  // Print summary (stable order)
  stdout.writeln('PROGRESSION');
  stdout.writeln('IDS ${ids.length}');
  stdout.writeln('PREREQS $edgeCount');
  stdout.writeln('ROOTS ${roots.length}');
  stdout.writeln('CYCLES ${cycleNodes.length}');
  stdout.writeln('UNKNOWN ${unknown.length}');
  stdout.writeln('UNREACHABLE ${unreachable.length}');
  stdout.writeln('ROOT_LIST ${_fmtList(roots)}');
  stdout.writeln('CYCLE_NODES ${_fmtList(cycleNodes)}');
  stdout.writeln('UNREACHABLE_LIST ${_fmtList(unreachable)}');

  if (cycleNodes.isNotEmpty || unknown.isNotEmpty || unreachable.isNotEmpty) {
    exitCode = 1;
  }
}

String _fmtList(List<String> xs) {
  if (xs.isEmpty) return '-';
  final take = xs.take(20).join(',');
  return take.isEmpty ? '-' : take;
}

class _ProgData {
  final Map<String, int> weights;
  final Map<String, List<String>> prereqs;
  _ProgData(this.weights, this.prereqs);
}

_ProgData _readProgression() {
  final f = File('tooling/curriculum_progression.json');
  if (!f.existsSync())
    return _ProgData(<String, int>{}, <String, List<String>>{});
  try {
    final obj = jsonDecode(f.readAsStringSync());
    if (obj is! Map<String, dynamic>)
      return _ProgData(<String, int>{}, <String, List<String>>{});
    final w = <String, int>{};
    final p = <String, List<String>>{};
    final wo = obj['weights'];
    if (wo is Map) {
      for (final e in wo.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is int) w[k] = v; // ignore non-int values
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
    return _ProgData(w, p);
  } catch (_) {
    return _ProgData(<String, int>{}, <String, List<String>>{});
  }
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

List<String> _detectCycles(List<String> ids, Map<String, List<String>> pr) {
  final index = {for (var i = 0; i < ids.length; i++) ids[i]: i};
  final state = <String, int>{}; // 0=unvisited,1=visiting,2=done
  final stack = <String>[];
  final cyc = <String>{};

  bool dfs(String u) {
    final st = state[u] ?? 0;
    if (st == 1) {
      final pos = stack.indexOf(u);
      if (pos >= 0) cyc.addAll(stack.sublist(pos));
      return true;
    }
    if (st == 2) return false;
    state[u] = 1;
    stack.add(u);
    for (final v in pr[u] ?? const <String>[]) {
      if (v == u) {
        cyc.add(u);
        continue;
      }
      dfs(v);
    }
    stack.removeLast();
    state[u] = 2;
    return false;
  }

  for (final id in ids) {
    if ((state[id] ?? 0) == 0) dfs(id);
  }

  // Return in curriculum order
  final list = cyc.toList();
  list.sort((a, b) => (index[a] ?? 1 << 30).compareTo(index[b] ?? 1 << 30));
  return list;
}
