// dart run tooling/content_audit.dart [module_id]
import 'dart:convert';
import 'dart:io';

final asciiOk = RegExp(r'^[\x00-\x7F]+$');
final idDemo = RegExp(r'^[a-z0-9_]+:demo:\d{2}$');
final idDrill = RegExp(r'^[a-z0-9_]+:drill:\d{2}$');
final snakeToken = RegExp(r'^[a-z0-9_]+$');
final sectionHeaders = <String>[
  'What it is',
  'Why it matters',
  'Rules of thumb',
  'Mini example',
  'Common mistakes',
];

void main(List<String> args) async {
  final moduleId = args.isNotEmpty ? args.first : null;
  final modules = await _discoverModules(moduleId);
  var failed = false;
  for (final m in modules) {
    final errs = <String>[];
    errs.addAll(await _checkTheory(m));
    errs.addAll(await _checkDemos(m));
    errs.addAll(await _checkDrills(m));
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

Future<List<String>> _discoverModules(String? only) async {
  final root = Directory('content');
  if (!root.existsSync()) return [];
  final result = <String>[];
  for (final e in root.listSync()) {
    if (e is Directory) {
      final id = e.uri.pathSegments.last.replaceAll('/', '');
      if (only == null || only == id) {
        final v1 = Directory('${e.path}/v1');
        if (v1.existsSync()) result.add(id);
      }
    }
  }
  return result..sort();
}

List<String> _readLines(String path) => File(path).readAsLinesSync();

String _readAll(String path) => File(path).readAsStringSync();

List<String> _asciiErrors(String content, String label) {
  if (asciiOk.hasMatch(content)) return [];
  final bad = content.runes.where((c) => c > 0x7F).take(3).toList();
  return ['Non-ASCII in $label, codepoints: ${bad.join(", ")}'];
}

Future<List<String>> _checkTheory(String moduleId) async {
  final p = 'content/$moduleId/v1/theory.md';
  if (!File(p).existsSync()) return ['Missing $p'];
  final txt = _readAll(p);
  final errs = <String>[];
  errs.addAll(_asciiErrors(txt, 'theory.md'));
  final words = txt.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  if (words < 450 || words > 550) {
    errs.add('theory.md word count $words out of 450–550');
  }
  for (final h in sectionHeaders) {
    if (!txt.contains('\n$h\n')) {
      errs.add('Missing section header: "$h"');
    }
  }
  final isCore = moduleId.startsWith('core_');
  if (isCore && !txt.contains('\nContrast line\n')) {
    errs.add('Core module missing "Contrast line" section');
  }
  // Ban long dashes and smart quotes explicitly
  if (txt.contains('—') ||
      txt.contains('–') ||
      txt.contains('“') ||
      txt.contains('”') ||
      txt.contains('’')) {
    errs.add(
      'theory.md contains forbidden punctuation (smart quotes or long dashes)',
    );
  }
  return errs;
}

Future<List<String>> _checkDemos(String moduleId) async {
  final p = 'content/$moduleId/v1/demos.jsonl';
  if (!File(p).existsSync()) return ['Missing $p'];
  final lines = _readLines(p).where((l) => l.trim().isNotEmpty).toList();
  final errs = <String>[];
  if (lines.length < 2 || lines.length > 3) {
    errs.add('demos.jsonl must have 2–3 lines, found ${lines.length}');
  }
  final ids = <String>{};
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    errs.addAll(_asciiErrors(line, 'demos.jsonl line ${i + 1}'));
    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(line);
    } catch (_) {
      errs.add('Invalid JSON on demos line ${i + 1}');
      continue;
    }
    final id = obj['id'] as String?;
    if (id == null || !idDemo.hasMatch(id)) {
      errs.add('Invalid demo id on line ${i + 1}: "$id"');
    }
    if (!ids.add(id ?? '')) errs.add('Duplicate id on demos line ${i + 1}');
    final steps = obj['steps'];
    if (steps is! List) {
      errs.add('Missing steps[] on demos line ${i + 1}');
    } else {
      for (final s in steps) {
        if (s is! String) {
          errs.add('Non-string step on demos line ${i + 1}');
          continue;
        }
        if (s.contains('\n')) errs.add('Multiline step on demos line ${i + 1}');
        if (!asciiOk.hasMatch(s))
          errs.add('Non-ASCII step on demos line ${i + 1}');
      }
    }
  }
  return errs;
}

Future<List<String>> _checkDrills(String moduleId) async {
  final p = 'content/$moduleId/v1/drills.jsonl';
  if (!File(p).existsSync()) return ['Missing $p'];
  final lines = _readLines(p).where((l) => l.trim().isNotEmpty).toList();
  final errs = <String>[];
  if (lines.length < 12 || lines.length > 16) {
    errs.add('drills.jsonl must have 12–16 lines, found ${lines.length}');
  }
  final ids = <String>{};
  final targetsAll = <String>{};
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    errs.addAll(_asciiErrors(line, 'drills.jsonl line ${i + 1}'));
    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(line);
    } catch (_) {
      errs.add('Invalid JSON on drills line ${i + 1}');
      continue;
    }
    final id = obj['id'] as String?;
    if (id == null || !idDrill.hasMatch(id)) {
      errs.add('Invalid drill id on line ${i + 1}: "$id"');
    }
    if (!ids.add(id ?? '')) errs.add('Duplicate id on drills line ${i + 1}');
    final kind = obj['spotKind'];
    if (kind is! String || !RegExp(r'^l\d+_[a-z0-9_]+$').hasMatch(kind)) {
      errs.add('Invalid spotKind format on drills line ${i + 1}: "$kind"');
    }
    final target = obj['target'];
    if (target is! List || target.isEmpty) {
      errs.add('Missing target[] on drills line ${i + 1}');
    } else {
      for (final t in target) {
        if (t is! String || !snakeToken.hasMatch(t)) {
          errs.add(
            'Target must be snake_case token on drills line ${i + 1}: "$t"',
          );
        } else {
          targetsAll.add(t);
        }
      }
    }
    final rationale = obj['rationale'];
    if (rationale is! String ||
        rationale.contains('\n') ||
        !asciiOk.hasMatch(rationale)) {
      errs.add('Invalid rationale on drills line ${i + 1}');
    }
  }

  // Module-specific coverage checks
  if (moduleId == 'core_rules_and_setup') {
    final need = {
      'no_reopen',
      'reopen',
      'bettor_shows_first',
      'first_active_left_of_btn_shows',
    };
    for (final k in need) {
      if (!targetsAll.contains(k)) {
        errs.add('Missing coverage token in targets: $k');
      }
    }
  }

  return errs;
}
