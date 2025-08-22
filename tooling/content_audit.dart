/// Poker Analyzer content audit (strict)
/// dart run tooling/content_audit.dart [module_id]
import 'dart:convert';
import 'dart:io';

final RegExp asciiOk = RegExp(r'^[\x00-\x7F]+$');
final RegExp idDemo = RegExp(r'^([a-z0-9_]+):demo:(\d{2})$');
final RegExp idDrill = RegExp(r'^([a-z0-9_]+):drill:(\d{2})$');
final RegExp snake = RegExp(r'^[a-z0-9_]+$');

final List<String> requiredHeaders = <String>[
  'What it is',
  'Why it matters',
  'Rules of thumb',
  'Mini example',
  'Common mistakes',
];

void main(List<String> args) {
  final String? only = args.isNotEmpty ? args.first : null;
  final List<String> modules = _discoverModules(only);
  var failed = false;

  for (final m in modules) {
    final errs = <String>[];
    errs.addAll(_checkTheory(m));
    errs.addAll(_checkDemos(m));
    errs.addAll(_checkDrills(m));
    errs.addAll(_checkNoSeatEverywhere(m));

    if (errs.isEmpty) {
      stdout.writeln('OK: $m');
    } else {
      failed = true;
      stderr.writeln('FAIL: $m');
      for (final e in errs) {
        stderr.writeln('- $e');
      }
    }
  }

  if (failed) exitCode = 1;
}

List<String> _discoverModules(String? only) {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is Directory) {
      final id = e.uri.pathSegments.last.replaceAll('/', '');
      if (only == null || only == id) {
        final v1 = Directory('${e.path}/v1');
        if (v1.existsSync()) out.add(id);
      }
    }
  }
  out.sort();
  return out;
}

String _readAll(String path) => File(path).readAsStringSync();
List<String> _readLines(String path) => File(path).readAsLinesSync();

List<String> _asciiErrors(String content, String label) {
  if (asciiOk.hasMatch(content)) return <String>[];
  return <String>['Non-ASCII in $label'];
}

bool _hasPositionTokens(String s) =>
    RegExp(r'\b(UTG|MP|CO|BTN|SB|BB)\b').hasMatch(s);

Set<String> _readAllowlist(String path) {
  final f = File(path);
  if (!f.existsSync()) return <String>{};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}

List<String> _checkTheory(String moduleId) {
  final p = 'content/$moduleId/v1/theory.md';
  if (!File(p).existsSync()) return <String>['Missing $p'];

  final txt = _readAll(p);
  final errs = <String>[];

  errs.addAll(_asciiErrors(txt, 'theory.md'));
  if (RegExp(r'(?i)\bseat\s').hasMatch(txt)) {
    errs.add('theory.md must use positions, not seat numbers');
  }
  if (txt.contains('http') || txt.contains('www.')) {
    errs.add('theory.md must not contain links');
  }
  if (txt.contains('|')) {
    errs.add('theory.md must not contain vertical table pipes "|"');
  }

  final wc = txt.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  if (wc < 450 || wc > 550) {
    errs.add('theory.md word count $wc out of 450-550');
  }

  for (final h in requiredHeaders) {
    final pat = '^' + RegExp.escape(h) + r'$';
    if (!RegExp(pat, multiLine: true).hasMatch(txt)) {
      errs.add('Missing section header: "$h"');
    }
  }

  final isCore = moduleId.startsWith('core_');
  if (isCore && !RegExp(r'(?m)^Contrast line$').hasMatch(txt)) {
    errs.add('Core module missing "Contrast line" section');
  }

  if (!_hasPositionTokens(txt)) {
    errs.add('Mini example must include UTG/MP/CO/BTN/SB/BB tokens');
  }

  final lower = txt.toLowerCase();
  final mentionsSizing = RegExp(r'\bopen\b|\bbb\b').hasMatch(lower);
  if (moduleId == 'core_rules_and_setup' &&
      mentionsSizing &&
      !lower.contains('typical online')) {
    errs.add('Sizing mentioned but missing "typical online" label');
  }

  if (RegExp(r'\bEV\b').hasMatch(txt) &&
      !RegExp(r'(?m)^\s*-?\s*EV:').hasMatch(txt)) {
    errs.add('EV mentioned but Mini-glossary missing "EV:" line');
  }
  if (lower.contains('angle') &&
      !RegExp(r'(?m)^\s*-?\s*Angle shooting:').hasMatch(txt)) {
    errs.add(
      'Angle shooting mentioned but Mini-glossary missing "Angle shooting:" line',
    );
  }

  return errs;
}

List<String> _sequentialCheck(Iterable<int> ns, String label) {
  final errs = <String>[];
  if (ns.isEmpty) return errs;
  final s = ns.toList()..sort();
  for (var i = 0; i < s.length; i++) {
    if (s[i] != i + 1) {
      errs.add('$label ids must be sequential 01..NN without gaps');
      break;
    }
  }
  return errs;
}

List<String> _checkDemos(String moduleId) {
  final p = 'content/$moduleId/v1/demos.jsonl';
  if (!File(p).existsSync()) return <String>['Missing $p'];

  final lines = _readLines(p).where((l) => l.trim().isNotEmpty).toList();
  final errs = <String>[];

  if (lines.length < 2 || lines.length > 3) {
    errs.add('demos.jsonl must have 2-3 lines, found ${lines.length}');
  }

  final ids = <String>{};
  final nums = <int>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    errs.addAll(_asciiErrors(line, 'demos.jsonl line ${i + 1}'));
    if (RegExp(r'(?i)\bseat\s').hasMatch(line)) {
      errs.add('demos.jsonl line ${i + 1} uses seat numbers - use positions');
    }

    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      errs.add('Invalid JSON on demos line ${i + 1}');
      continue;
    }

    final id = obj['id'] as String?;
    final m = idDemo.firstMatch(id ?? '');
    if (id == null || m == null) {
      errs.add('Invalid demo id on line ${i + 1}: "${id ?? 'null'}"');
    } else {
      final prefix = m.group(1)!;
      if (prefix != moduleId) {
        errs.add('demo id prefix "$prefix" must match moduleId "$moduleId"');
      }
      nums.add(int.parse(m.group(2)!));
    }
    if (id != null && !ids.add(id)) {
      errs.add('Duplicate id on demos line ${i + 1}');
    }

    final steps = obj['steps'];
    if (steps is! List) {
      errs.add('Missing steps[] on demos line ${i + 1}');
    } else {
      for (final s in steps) {
        if (s is! String) {
          errs.add('Non-string step on demos line ${i + 1}');
          continue;
        }
        if (s.contains('\n')) {
          errs.add('Multiline step on demos line ${i + 1}');
        }
        if (!asciiOk.hasMatch(s)) {
          errs.add('Non-ASCII step on demos line ${i + 1}');
        }
      }
    }

    final hints = obj.containsKey('hints') ? obj['hints'] : null;
    if (hints != null) {
      if (hints is! List) {
        errs.add('hints must be array on demos line ${i + 1}');
      } else {
        for (final h in hints) {
          if (h is! String) {
            errs.add('Non-string hint on demos line ${i + 1}');
          } else {
            if (h.contains('\n')) {
              errs.add('Multiline hint on demos line ${i + 1}');
            }
            if (!asciiOk.hasMatch(h)) {
              errs.add('Non-ASCII hint on demos line ${i + 1}');
            }
          }
        }
      }
    }
  }

  errs.addAll(_sequentialCheck(nums, 'demo'));
  return errs;
}

List<String> _checkDrills(String moduleId) {
  final p = 'content/$moduleId/v1/drills.jsonl';
  if (!File(p).existsSync()) return <String>['Missing $p'];

  final lines = _readLines(p).where((l) => l.trim().isNotEmpty).toList();
  final errs = <String>[];

  if (lines.length < 12 || lines.length > 16) {
    errs.add('drills.jsonl must have 12-16 lines, found ${lines.length}');
  }

  final ids = <String>{};
  final nums = <int>[];
  final tokensAll = <String>{};

  final spotAllow = _readAllowlist(
    'tooling/allowlists/spotkind_allowlist_$moduleId.txt',
  );
  final targetAllow = _readAllowlist(
    'tooling/allowlists/target_tokens_allowlist_$moduleId.txt',
  );

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    errs.addAll(_asciiErrors(line, 'drills.jsonl line ${i + 1}'));
    if (RegExp(r'(?i)\bseat\s').hasMatch(line)) {
      errs.add('drills.jsonl line ${i + 1} uses seat numbers - use positions');
    }

    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      errs.add('Invalid JSON on drills line ${i + 1}');
      continue;
    }

    final id = obj['id'] as String?;
    final m = idDrill.firstMatch(id ?? '');
    if (id == null || m == null) {
      errs.add('Invalid drill id on drills line ${i + 1}: "${id ?? 'null'}"');
    } else {
      final prefix = m.group(1)!;
      if (prefix != moduleId) {
        errs.add('drill id prefix "$prefix" must match moduleId "$moduleId"');
      }
      nums.add(int.parse(m.group(2)!));
    }
    if (id != null && !ids.add(id)) {
      errs.add('Duplicate id on drills line ${i + 1}');
    }

    final kind = obj['spotKind'];
    if (kind is! String) {
      errs.add('Missing spotKind on drills line ${i + 1}');
    } else {
      if (!RegExp(r'^l\d+_[a-z0-9_]+$').hasMatch(kind)) {
        errs.add('Invalid spotKind format on drills line ${i + 1}: "$kind"');
      }
      if (spotAllow.isNotEmpty && !spotAllow.contains(kind)) {
        errs.add('spotKind not in allowlist on line ${i + 1}: $kind');
      }
    }

    final target = obj['target'];
    if (target is! List || target.isEmpty) {
      errs.add('Missing target[] on drills line ${i + 1}');
    } else {
      for (final t in target) {
        if (t is! String || !snake.hasMatch(t)) {
          errs.add(
            'Target must be snake_case token on drills line ${i + 1}: "$t"',
          );
        } else {
          tokensAll.add(t);
          if (targetAllow.isNotEmpty && !targetAllow.contains(t)) {
            errs.add(
              'Target token not in allowlist on drills line ${i + 1}: $t',
            );
          }
        }
      }
    }

    final rationale = obj['rationale'];
    if (rationale is! String ||
        rationale.contains('\n') ||
        !asciiOk.hasMatch(rationale)) {
      errs.add('Invalid rationale on drills line ${i + 1}');
    } else if (rationale.length > 120) {
      errs.add('Rationale too long (>120) on drills line ${i + 1}');
    }
  }

  errs.addAll(_sequentialCheck(nums, 'drill'));

  if (moduleId == 'core_rules_and_setup') {
    final need = <String>{
      'no_reopen',
      'reopen',
      'bettor_shows_first',
      'first_active_left_of_btn_shows',
      'min_raise_legal',
      'min_raise_illegal',
      'string_bet_call_only',
      'binding',
      'returned',
    };
    for (final k in need) {
      if (!tokensAll.contains(k)) {
        errs.add('Missing coverage token in targets: $k');
      }
    }
  }

  return errs;
}

List<String> _checkNoSeatEverywhere(String moduleId) {
  final errs = <String>[];
  final paths = <String>[
    'content/$moduleId/v1/theory.md',
    'content/$moduleId/v1/demos.jsonl',
    'content/$moduleId/v1/drills.jsonl',
  ];
  for (final p in paths) {
    if (!File(p).existsSync()) continue;
    final txt = _readAll(p);
    if (RegExp(r'(?i)\bseat\s').hasMatch(txt)) {
      errs.add('Found "seat" in $p - use positions UTG/MP/CO/BTN/SB/BB');
    }
  }
  return errs;
}
