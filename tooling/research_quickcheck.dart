// Research draft quick check (path-scoped content validator).
// Usage:
//   dart run tooling/research_quickcheck.dart /abs/path/to/draft_root
// Expects modules under <root>/content/<module>/v1/ with theory.md, demos.jsonl, drills.jsonl.
// Zips are not supported; unzip first. ASCII-only output. No new deps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tooling/research_quickcheck.dart <root> [--json path] [--quiet]',
    );
    exit(2);
  }

  String root = args.first.trim();
  String? jsonPath;
  bool quiet = false;
  for (var i = 1; i < args.length; i++) {
    final a = args[i];
    if (a == '--quiet') quiet = true;
    if (a == '--json' && i + 1 < args.length) jsonPath = args[++i];
  }

  final modules = _discoverModules(root);
  final rows = <_Row>[];
  var anyGaps = false;
  for (final m in modules) {
    final r = _analyzeModule(root, m);
    rows.add(r);
    if (r.hasGaps) anyGaps = true;
  }

  final totals = _computeTotals(rows);

  if (jsonPath != null) {
    final payload = {
      'rows': rows
          .map(
            (r) => {
              'module': r.module,
              'missing_sections': r.missingSections,
              'wordcount_out_of_range': r.wordcountOutOfRange,
              'images_missing': r.imagesMissing,
              'demo_count_bad': r.demoCountBad,
              'drill_count_bad': r.drillCountBad,
              'duplicate_ids': r.duplicateIds,
              'off_tree_sizes': r.offTreeSizes,
            },
          )
          .toList(),
      'totals': totals,
    };
    try {
      final f = File(jsonPath!);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(jsonEncode(payload));
    } catch (_) {}
  }

  if (!quiet) {
    _printTable(rows);
  }

  if (anyGaps) exitCode = 1;
}

class _Row {
  final String module;
  final List<String> missingSections;
  final bool wordcountOutOfRange;
  final bool imagesMissing;
  final bool demoCountBad;
  final bool drillCountBad;
  final bool duplicateIds;
  final bool offTreeSizes;
  const _Row({
    required this.module,
    required this.missingSections,
    required this.wordcountOutOfRange,
    required this.imagesMissing,
    required this.demoCountBad,
    required this.drillCountBad,
    required this.duplicateIds,
    required this.offTreeSizes,
  });
  bool get hasGaps =>
      missingSections.isNotEmpty ||
      wordcountOutOfRange ||
      imagesMissing ||
      demoCountBad ||
      drillCountBad ||
      duplicateIds ||
      offTreeSizes;
}

List<String> _discoverModules(String root) {
  final base = Directory(_join(root, 'content'));
  if (!base.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in base.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
    final v1 = Directory(_join(e.path, 'v1'));
    if (v1.existsSync()) out.add(id);
  }
  out.sort();
  return out;
}

_Row _analyzeModule(String root, String moduleId) {
  final v1 = _join(root, 'content', moduleId, 'v1');

  // Theory
  final theoryPath = _join(v1, 'theory.md');
  final theoryFile = File(theoryPath);
  var missingSections = <String>[];
  var wordcountOutOfRange = false;
  var imagesMissing = false;

  if (!theoryFile.existsSync()) {
    missingSections = ['theory.md'];
    wordcountOutOfRange = true;
    imagesMissing = true;
  } else {
    final txt = theoryFile.readAsStringSync();
    if (!_isAscii(txt)) missingSections.add('non_ascii');
    const req = [
      'What it is',
      'Why it matters',
      'Rules of thumb',
      'Mini example',
      'Common mistakes',
      'Mini-glossary',
      'Contrast',
    ];
    for (final h in req) {
      if (!RegExp(
        '^' + RegExp.escape(h) + r'$',
        multiLine: true,
      ).hasMatch(txt)) {
        missingSections.add(h);
      }
    }
    final wc = txt.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wc < 400 || wc > 700) wordcountOutOfRange = true;
    imagesMissing = RegExp(r'\[\[IMAGE:\s*[^\]]+\]\]').allMatches(txt).isEmpty;
  }

  // Demos
  final demosPath = _join(v1, 'demos.jsonl');
  var demoCountBad = false;
  final idsSeen = <String>{};
  var duplicateIds = false;
  var demosTokenOk = false;
  const tokenSet = {
    'small_cbet_33',
    'half_pot_50',
    'big_bet_75',
    'probe_turns',
    'delay_turn',
    'double_barrel_good',
    'triple_barrel_scare',
    'call',
    'fold',
    'overfold_exploit',
  };
  if (!File(demosPath).existsSync()) {
    demoCountBad = true;
  } else {
    final lines = File(demosPath)
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2 || lines.length > 3) demoCountBad = true;
    for (var i = 0; i < lines.length; i++) {
      try {
        final obj = jsonDecode(lines[i]) as Map<String, dynamic>;
        final id = obj['id'];
        if (id is String) {
          if (!idsSeen.add(id)) duplicateIds = true;
        } else {
          demoCountBad = true;
        }
        final spot = obj['spot_kind'] ?? obj['spotKind'];
        if (spot is! String) demoCountBad = true;
        final steps = obj['steps'];
        if (steps is! List || steps.length < 4) demoCountBad = true;
        if (!demosTokenOk) {
          if (_objectHasToken(obj, tokenSet)) demosTokenOk = true;
        }
      } catch (_) {
        demoCountBad = true;
      }
    }
    if (!demosTokenOk) demoCountBad = true;
  }

  // Drills
  final drillsPath = _join(v1, 'drills.jsonl');
  var drillCountBad = false;
  var offTreeSizes = false;
  if (!File(drillsPath).existsSync()) {
    drillCountBad = true;
  } else {
    final lines = File(drillsPath)
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 10 || lines.length > 20) drillCountBad = true;
    for (var i = 0; i < lines.length; i++) {
      try {
        final obj = jsonDecode(lines[i]) as Map<String, dynamic>;
        final id = obj['id'];
        if (id is String) {
          if (!idsSeen.add(id)) duplicateIds = true;
        } else {
          drillCountBad = true;
        }
        final targets = obj['targets'];
        if (targets is! List || targets.isEmpty) {
          drillCountBad = true;
        } else {
          for (final t in targets) {
            if (t is String) {
              final m = RegExp(r'_(\d+)$').firstMatch(t);
              if (m != null) {
                final v = int.tryParse(m.group(1)!);
                if (v != 33 && v != 50 && v != 75) offTreeSizes = true;
              }
            }
          }
        }
      } catch (_) {
        drillCountBad = true;
      }
    }
  }

  return _Row(
    module: moduleId,
    missingSections: missingSections,
    wordcountOutOfRange: wordcountOutOfRange,
    imagesMissing: imagesMissing,
    demoCountBad: demoCountBad,
    drillCountBad: drillCountBad,
    duplicateIds: duplicateIds,
    offTreeSizes: offTreeSizes,
  );
}

Map<String, int> _computeTotals(List<_Row> rows) {
  final totals = <String, int>{
    'missing_sections': 0,
    'wordcount_out_of_range': 0,
    'images_missing': 0,
    'demo_count_bad': 0,
    'drill_count_bad': 0,
    'duplicate_ids': 0,
    'off_tree_sizes': 0,
  };
  for (final r in rows) {
    if (r.missingSections.isNotEmpty)
      totals['missing_sections'] = totals['missing_sections']! + 1;
    if (r.wordcountOutOfRange)
      totals['wordcount_out_of_range'] = totals['wordcount_out_of_range']! + 1;
    if (r.imagesMissing)
      totals['images_missing'] = totals['images_missing']! + 1;
    if (r.demoCountBad)
      totals['demo_count_bad'] = totals['demo_count_bad']! + 1;
    if (r.drillCountBad)
      totals['drill_count_bad'] = totals['drill_count_bad']! + 1;
    if (r.duplicateIds) totals['duplicate_ids'] = totals['duplicate_ids']! + 1;
    if (r.offTreeSizes)
      totals['off_tree_sizes'] = totals['off_tree_sizes']! + 1;
  }
  return totals;
}

void _printTable(List<_Row> rows) {
  stdout.writeln(
    'module|missing_sections|wordcount_out_of_range|images_missing|demo_count_bad|drill_count_bad|duplicate_ids|off_tree_sizes',
  );
  for (final r in rows) {
    final miss = r.missingSections.isEmpty ? '-' : r.missingSections.join(',');
    stdout.writeln(
      '${r.module}|$miss|${_b(r.wordcountOutOfRange)}|${_b(r.imagesMissing)}|${_b(r.demoCountBad)}|${_b(r.drillCountBad)}|${_b(r.duplicateIds)}|${_b(r.offTreeSizes)}',
    );
  }
}

String _b(bool v) => v ? '1' : '0';

bool _isAscii(String s) {
  for (final c in s.codeUnits) {
    if (c > 0x7F) return false;
  }
  return true;
}

bool _objectHasToken(Map<String, dynamic> obj, Set<String> tokens) {
  bool scan(dynamic v) {
    if (v is String) {
      for (final t in tokens) {
        if (v.contains(t)) return true;
      }
      return false;
    }
    if (v is List) {
      for (final e in v) {
        if (scan(e)) return true;
      }
      return false;
    }
    if (v is Map) {
      for (final e in v.values) {
        if (scan(e)) return true;
      }
      return false;
    }
    return false;
  }

  for (final e in obj.entries) {
    if (scan(e.value)) return true;
  }
  return false;
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}

String _join(String a, [String? b, String? c, String? d]) {
  final parts = <String>[a];
  if (b != null) parts.add(b);
  if (c != null) parts.add(c);
  if (d != null) parts.add(d);
  return parts.join('/').replaceAll('///', '/').replaceAll('//', '/');
}
