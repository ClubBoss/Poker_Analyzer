// Explain why demo_count_bad/drill_count_bad fire per module.
// Usage:
//   dart run tooling/explain_gap_details.dart [--module <id>] [--json <path>] [--quiet]
//
// Scans content/*/v1/demos.jsonl and drills.jsonl and emits JSON:
// {
//   "rows": [
//     {"module":"<id>",
//      "demos":[{"id":"...","issues":["steps_lt_4","no_token_sanity:big_bet_75", ...]}],
//      "drills":[{"id":"...","issues":["off_tree_size:62", ...]}]
//     },
//     ...
//   ],
//   "summary":{"modules":N, "demo_issues":X, "drill_issues":Y}
// }
// Deterministic ordering; ASCII-only. Exit 0.

import 'dart:convert';
import 'dart:io';

const Set<String> _demoTokens = {
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

void main(List<String> args) {
  String? onlyModule;
  String? jsonPath;
  var quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--module' && i + 1 < args.length) {
      onlyModule = args[++i];
    } else if (a == '--json' && i + 1 < args.length) {
      jsonPath = args[++i];
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final modules = _discoverModules(onlyModule);
  final rows = <Map<String, dynamic>>[];
  var demoIssues = 0;
  var drillIssues = 0;

  for (final m in modules) {
    final demosPath = 'content/$m/v1/demos.jsonl';
    final drillsPath = 'content/$m/v1/drills.jsonl';
    final demoList = <Map<String, dynamic>>[];
    final drillList = <Map<String, dynamic>>[];

    // Demos
    if (File(demosPath).existsSync()) {
      final lines = File(demosPath).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        Map<String, dynamic>? obj;
        try {
          obj = jsonDecode(line) as Map<String, dynamic>;
        } catch (_) {
          final issues = <String>['invalid_json'];
          demoList.add({'id': 'line_${i + 1}', 'issues': issues});
          demoIssues += issues.length;
          continue;
        }
        final id = (obj['id'] is String && (obj['id'] as String).isNotEmpty)
            ? obj['id'] as String
            : 'line_${i + 1}';
        final issues = <String>[];
        final spot1 = obj['spot_kind'];
        final spot2 = obj['spotKind'];
        if (spot1 is! String && spot2 is! String) {
          issues.add('missing_spot_kind');
        }
        final steps = obj['steps'];
        if (steps is! List || steps.length < 4) {
          issues.add('steps_lt_4');
        }
        // Token sanity: list tokens from _demoTokens not found anywhere in the object
        final present = _tokensInObject(obj, _demoTokens);
        for (final tok in _demoTokens) {
          if (!present.contains(tok)) issues.add('no_token_sanity:$tok');
        }
        if (issues.isNotEmpty) {
          demoList.add({'id': id, 'issues': issues});
          demoIssues += issues.length;
        }
      }
    }

    // Drills
    if (File(drillsPath).existsSync()) {
      final lines = File(drillsPath)
          .readAsLinesSync()
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.length < 10 || lines.length > 20) {
        drillList.add({
          'id': '__count__',
          'issues': ['count_out_of_range'],
        });
        drillIssues += 1;
      }
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        Map<String, dynamic>? obj;
        try {
          obj = jsonDecode(line) as Map<String, dynamic>;
        } catch (_) {
          drillList.add({
            'id': 'line_${i + 1}',
            'issues': ['invalid_json'],
          });
          drillIssues += 1;
          continue;
        }
        final id = (obj['id'] is String && (obj['id'] as String).isNotEmpty)
            ? obj['id'] as String
            : 'line_${i + 1}';
        final issues = <String>[];
        final t = obj['target'];
        final ts = obj['targets'];
        final targetList = <String>[];
        if (t is String) targetList.add(t);
        if (t is List) {
          for (final v in t) {
            if (v is String) targetList.add(v);
          }
        }
        if (ts is List) {
          for (final v in ts) {
            if (v is String) targetList.add(v);
          }
        }
        if (targetList.isEmpty) {
          issues.add('missing_targets');
        }
        for (final tok in targetList) {
          final mSize = RegExp(r'_(\d+)$').firstMatch(tok);
          if (mSize != null) {
            final n = int.tryParse(mSize.group(1)!);
            if (n != null && n != 33 && n != 50 && n != 75) {
              issues.add('off_tree_size:$n');
            }
          }
        }
        if (issues.isNotEmpty) {
          drillList.add({'id': id, 'issues': issues});
          drillIssues += issues.length;
        }
      }
    }

    rows.add({'module': m, 'demos': demoList, 'drills': drillList});
  }

  final payload = {
    'rows': rows,
    'summary': {
      'modules': modules.length,
      'demo_issues': demoIssues,
      'drill_issues': drillIssues,
    },
  };

  if (jsonPath != null) {
    try {
      final f = File(jsonPath);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(jsonEncode(payload));
      if (!quiet) {
        stdout.writeln(
          'DETAILS modules=${modules.length} demo_issues=$demoIssues drill_issues=$drillIssues',
        );
      }
    } catch (e) {
      stderr.writeln('write error: $e');
      exitCode = 1;
    }
  } else {
    stdout.writeln(jsonEncode(payload));
  }
}

Set<String> _tokensInObject(Map<String, dynamic> obj, Set<String> tokens) {
  final found = <String>{};
  bool scan(dynamic v) {
    if (v is String) {
      for (final t in tokens) {
        if (v.contains(t)) {
          found.add(t);
        }
      }
      return false;
    } else if (v is List) {
      for (final e in v) {
        scan(e);
      }
      return false;
    } else if (v is Map) {
      for (final e in v.values) {
        scan(e);
      }
      return false;
    }
    return false;
  }

  for (final e in obj.entries) {
    scan(e.value);
  }
  return found;
}

List<String> _discoverModules(String? only) {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = _basename(e.path);
    if (id.isEmpty || id.startsWith('_')) continue;
    if (only != null && id != only) continue;
    final v1 = Directory('${e.path}/v1');
    if (v1.existsSync()) out.add(id);
  }
  out.sort();
  return out;
}

String _basename(String path) {
  final norm = path.replaceAll('\\', '/');
  var s = norm;
  if (s.endsWith('/')) s = s.substring(0, s.length - 1);
  final idx = s.lastIndexOf('/');
  return idx == -1 ? s : s.substring(idx + 1);
}
