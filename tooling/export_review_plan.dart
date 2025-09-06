// Export spaced-repetition review plan and KPI seeds for lesson runner.
// Usage:
//   dart run tooling/export_review_plan.dart
//
// Inputs: build/badges.json, build/search_index.json
// - If either input is missing or unparsable: write empty payload to
//   build/review_plan.json and exit 0.
// Output: build/review_plan.json and one ASCII line:
//   UI-PLAN total=<N> next=<id_or_->_>

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final outPath = 'build/review_plan.json';
  Directory('build').createSync(recursive: true);

  final badgesFile = File('build/badges.json');
  final indexFile = File('build/search_index.json');

  if (!badgesFile.existsSync() || !indexFile.existsSync()) {
    final empty = _emptyPayload();
    File(outPath).writeAsStringSync(jsonEncode(empty));
    stdout.writeln('UI-PLAN total=0 next=_');
    return;
  }

  Map<String, dynamic> badges;
  Map<String, dynamic> index;
  try {
    badges = jsonDecode(badgesFile.readAsStringSync()) as Map<String, dynamic>;
    index = jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    final empty = _emptyPayload();
    File(outPath).writeAsStringSync(jsonEncode(empty));
    stdout.writeln('UI-PLAN total=0 next=_');
    return;
  }

  final badgeRows = (badges['rows'] is List) ? (badges['rows'] as List) : const [];
  // Build maps from search index for per-module stats
  final tokensMap = <String, int>{};
  final spotsMap = <String, int>{};
  final idxRows = (index['rows'] is List) ? (index['rows'] as List) : const [];
  for (final r in idxRows) {
    if (r is! Map) continue;
    final id = r['module'];
    if (id is! String) continue;
    final toks = <String>{};
    final sk = <String>{};
    if (r['tokens'] is List) {
      for (final t in (r['tokens'] as List)) {
        if (t is String) toks.add(t);
      }
    }
    if (r['spot_kinds'] is List) {
      for (final s in (r['spot_kinds'] as List)) {
        if (s is String) sk.add(s);
      }
    }
    tokensMap[id] = toks.length;
    spotsMap[id] = sk.length;
  }

  // Build rows for all modules from badges
  final rows = <Map<String, dynamic>>[];
  final unlockableIds = <String>[];

  for (final r in badgeRows) {
    if (r is! Map) continue;
    final id = r['module'];
    final status = r['status'];
    if (id is! String || status is! String) continue;
    if (status == 'unlockable') unlockableIds.add(id);
    final t = tokensMap[id] ?? 0;
    final s = spotsMap[id] ?? 0;
    rows.add({
      'module': id,
      'intervals': const [1, 3, 7],
      'kpi': {
        'tokens_total': t,
        'spot_kinds_total': s,
        'missed_probes': 0,
        'family_errors': 0,
        'answered': 0,
        'correct': 0,
      }
    });
  }

  // Sort rows deterministically by module id
  rows.sort((a, b) => (a['module'] as String).compareTo(b['module'] as String));

  // Determine next: badges.summary.next or first unlockable, else first module id
  String nextId = '_';
  if (badges['summary'] is Map && (badges['summary'] as Map)['next'] is String) {
    final n = (badges['summary'] as Map)['next'] as String;
    if (n.isNotEmpty && n != '_') nextId = n;
  }
  if (nextId == '_' && unlockableIds.isNotEmpty) {
    unlockableIds.sort();
    nextId = unlockableIds.first;
  }
  if (nextId == '_' && rows.isNotEmpty) {
    nextId = rows.first['module'] as String;
  }

  final payload = <String, dynamic>{
    'rows': rows,
    'summary': {'total': rows.length, 'next': rows.isEmpty ? '_' : nextId}
  };

  File(outPath).writeAsStringSync(jsonEncode(payload));
  stdout.writeln('UI-PLAN total=${rows.length} next=${rows.isEmpty ? '_' : nextId}');
}

Map<String, dynamic> _emptyPayload() => {
      'rows': const <Map<String, dynamic>>[],
      'summary': const {'total': 0, 'next': '_'},
    };

