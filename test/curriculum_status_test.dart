import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('curriculum NEXT', () {
    final ids = _readCurriculumIds();
    final done = _readModulesDone();

    final total = ids.length;
    final doneSet = done.toSet();
    final doneCount = ids.where(doneSet.contains).length;
    final pendingCount = total - doneCount;

    String nextId = 'all_done';
    int nextIdx = -1;
    for (var i = 0; i < ids.length; i++) {
      if (!doneSet.contains(ids[i])) {
        nextId = ids[i];
        nextIdx = i;
        break;
      }
    }

    final upcoming = <String>[];
    if (nextIdx >= 0) {
      for (var i = nextIdx + 1; i < ids.length && upcoming.length < 10; i++) {
        final id = ids[i];
        if (!doneSet.contains(id)) upcoming.add(id);
      }
    }

    // Print the five required lines
    print('TOTAL $total');
    print('DONE $doneCount');
    print('PENDING $pendingCount');
    print('NEXT $nextId');
    print('UPCOMING ${upcoming.isEmpty ? '-' : upcoming.join(',')}');
  });
}

List<String> _readCurriculumIds() {
  try {
    final path = 'tooling/curriculum_ids.dart';
    final text = File(path).readAsStringSync();

    // Prefer explicit kCurriculumIds list; fallback to curriculumIds
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

List<String> _readModulesDone() {
  final f = File('curriculum_status.json');
  if (!f.existsSync()) return <String>[];
  try {
    // Allow comments/blank lines by stripping lines starting with // or #
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
        return set.toList();
      }
    }
  } catch (_) {
    // ignore
  }
  return <String>[];
}
