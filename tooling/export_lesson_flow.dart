// Generate a compact lesson flow artifact for the UI from build/* inputs.
// Usage:
//   dart run tooling/export_lesson_flow.dart
//
// Behavior:
// - Prefers build/badges.json and build/see_also.json. If either is missing,
//   writes an empty payload to build/lesson_flow.json and exits 0.
// - Output is deterministic and ASCII-only logging: prints one line
//   "UI-FLOW total=<N> next=<id_or_->_" and writes build/lesson_flow.json.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final badgesFile = File('build/badges.json');
  final seeAlsoFile = File('build/see_also.json');
  final outPath = 'build/lesson_flow.json';

  Directory('build').createSync(recursive: true);

  if (!badgesFile.existsSync() || !seeAlsoFile.existsSync()) {
    final empty = _emptyPayload();
    File(outPath).writeAsStringSync(jsonEncode(empty));
    stdout.writeln('UI-FLOW total=0 next=_');
    return;
  }

  Map<String, dynamic> badges;
  Map<String, dynamic> seeAlso;
  try {
    badges = jsonDecode(badgesFile.readAsStringSync()) as Map<String, dynamic>;
    seeAlso =
        jsonDecode(seeAlsoFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    // On parse errors, emit empty payload but keep exit 0 per relaxed tooling contract.
    final empty = _emptyPayload();
    File(outPath).writeAsStringSync(jsonEncode(empty));
    stdout.writeln('UI-FLOW total=0 next=_');
    return;
  }

  final badgeRows = (badges['rows'] is List)
      ? (badges['rows'] as List)
      : const [];

  // Map: module -> top-5 see_also module ids
  final seeAlsoMap = <String, List<String>>{};
  final saRows = (seeAlso['rows'] is List)
      ? (seeAlso['rows'] as List)
      : const [];
  for (final row in saRows) {
    if (row is! Map) continue;
    final m = row['module'];
    final list = row['see_also'];
    if (m is! String || list is! List) continue;
    final ids = <String>[];
    for (final e in list) {
      if (e is Map && e['module'] is String) {
        ids.add(e['module'] as String);
        if (ids.length >= 5) break; // top-5 as-is
      }
    }
    seeAlsoMap[m] = ids;
  }

  // Build rows
  final rows = <Map<String, dynamic>>[];
  int done = 0, unlockable = 0, locked = 0;
  String nextId = '_';

  for (final r in badgeRows) {
    if (r is! Map) continue;
    final id = r['module'];
    final status = r['status'];
    if (id is! String || status is! String) continue;

    if (status == 'done') done++;
    if (status == 'unlockable') unlockable++;
    if (status == 'locked') locked++;

    final row = <String, dynamic>{
      'module': id,
      'status': status,
      'flow': const ['theory', 'demos', 'drills'],
      'actionsMap': const {
        'theory': 'Read',
        'demos': 'Try demo',
        'drills': 'Start drills',
      },
      'subtitlePrefix': const {
        'theory': 'Theory',
        'demos': 'Demo',
        'drills': 'Drill',
      },
      'see_also': seeAlsoMap[id] ?? const <String>[],
    };
    rows.add(row);
  }

  // Sort by module id
  rows.sort((a, b) => (a['module'] as String).compareTo(b['module'] as String));

  // Determine next
  if (badges['summary'] is Map &&
      (badges['summary'] as Map)['next'] is String) {
    final n = (badges['summary'] as Map)['next'] as String;
    nextId = n.isEmpty ? '_' : n;
  } else {
    // Fallback: first row with status == next
    for (final r in rows) {
      if (r['status'] == 'next') {
        nextId = r['module'] as String;
        break;
      }
    }
  }

  final payload = <String, dynamic>{
    'rows': rows,
    'summary': {
      'total': rows.length,
      'done': done,
      'unlockable': unlockable,
      'locked': locked,
      'next': rows.isEmpty ? '_' : nextId,
    },
  };

  File(outPath).writeAsStringSync(jsonEncode(payload));
  stdout.writeln(
    'UI-FLOW total=${rows.length} next=${rows.isEmpty ? '_' : nextId}',
  );
}

Map<String, dynamic> _emptyPayload() => {
  'rows': const <Map<String, dynamic>>[],
  'summary': const {
    'total': 0,
    'done': 0,
    'unlockable': 0,
    'locked': 0,
    'next': '_',
  },
};
