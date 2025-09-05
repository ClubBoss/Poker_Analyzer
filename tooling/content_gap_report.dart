// Content GAP report CLI
// Usage: dart run tooling/content_gap_report.dart [module_id]
// - Scans content/*/v1/ and prints per-module GAPs in a stable table.
// - ASCII-only output. No external deps. Pure Dart.
// Exit code: 0 if no gaps, 1 if any gaps.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final only = args.isNotEmpty ? args.first.trim() : null;
  final modules = _discoverModules(only);
  final rows = <GapRow>[];
  var anyGaps = false;

  for (final m in modules) {
    final r = _analyzeModule(m);
    rows.add(r);
    if (r.hasGaps) anyGaps = true;
  }

  _printReport(rows);
  if (anyGaps) exitCode = 1;
}

class GapRow {
  final String module;
  final List<String> missingSections; // names from required list, or ['theory.md'] if file missing
  final bool wordcountOutOfRange; // theory.md
  final bool imagesMissing; // theory.md
  final bool demoCountBad; // demos.jsonl missing or count invalid or content invalid
  final bool drillCountBad; // drills.jsonl missing or count invalid or content invalid
  final bool invalidSpotKind; // any spot_kind not in allowlist (demos/drills)
  final bool invalidTargets; // drills target outside allowlist
  final bool duplicateIds; // duplicates across demos+drills in this module
  final bool offTreeSizes; // drills target contains size token not in 33/50/75

  const GapRow({
    required this.module,
    required this.missingSections,
    required this.wordcountOutOfRange,
    required this.imagesMissing,
    required this.demoCountBad,
    required this.drillCountBad,
    required this.invalidSpotKind,
    required this.invalidTargets,
    required this.duplicateIds,
    required this.offTreeSizes,
  });

  bool get hasGaps =>
      missingSections.isNotEmpty ||
      wordcountOutOfRange ||
      imagesMissing ||
      demoCountBad ||
      drillCountBad ||
      invalidSpotKind ||
      invalidTargets ||
      duplicateIds ||
      offTreeSizes;
}

// Required sections in theory.md
const List<String> _requiredSections = <String>[
  'What it is',
  'Why it matters',
  'Rules of thumb',
  'Mini example',
  'Common mistakes',
  'Mini-glossary',
  'Contrast',
];

// Demos token sanity: must contain at least one token from this set in any string field
const Set<String> _demoTokenSanity = {
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

final RegExp _asciiOk = RegExp(r'^[\x00-\x7F]+
$');

List<String> _discoverModules(String? only) {
  final root = Directory('content');
  if (!root.existsSync()) return <String>[];
  final out = <String>[];
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final id = e.uri.pathSegments.last.replaceAll('/', '');
    if (id.isEmpty || id.startsWith('_')) continue; // skip reference dirs
    if (only != null && only != id) continue;
    final v1 = Directory('${e.path}/v1');
    if (v1.existsSync()) out.add(id);
  }
  out.sort();
  return out;
}

GapRow _analyzeModule(String moduleId) {
  final versionDir = 'content/$moduleId/v1';

  // Theory checks
  final theoryPath = '$versionDir/theory.md';
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
    // ASCII-only guard for stability
    if (!_asciiOk.hasMatch(txt)) {
      // We don't have a separate key for non-ascii; fold into missingSections signal
      if (!missingSections.contains('non_ascii')) missingSections.add('non_ascii');
    }

    // Required headers presence (exact lines)
    for (final h in _requiredSections) {
      final pat = RegExp('^' + RegExp.escape(h) + r'$', multiLine: true);
      if (!pat.hasMatch(txt)) missingSections.add(h);
    }

    // Word count
    final wc = txt.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wc < 400 || wc > 700) wordcountOutOfRange = true;

    // Images [[IMAGE: ...]]
    final imageCount = RegExp(r'\[\[IMAGE:\s*[^\]]+\]\]').allMatches(txt).length;
    imagesMissing = imageCount == 0;
  }

  // Allowlists
  final spotAllow = _readAllowlist('tooling/allowlists/spotkind_allowlist_$moduleId.txt');
  final targetAllow = _readAllowlist('tooling/allowlists/target_tokens_allowlist_$moduleId.txt');

  // Demos checks
  final demosPath = '$versionDir/demos.jsonl';
  var demoCountBad = false;
  var invalidSpotKind = false;
  final idSeen = <String>{};
  var duplicateIds = false;
  var demosTokenOk = false; // at least one entry hits sanity tokens

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
      final line = lines[i];
      Map<String, dynamic> obj;
      try {
        obj = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        demoCountBad = true;
        continue;
      }
      final id = obj['id'];
      if (id is! String || id.isEmpty) {
        demoCountBad = true;
      } else {
        if (!idSeen.add(id)) duplicateIds = true;
      }
      final spot = _firstString(obj, ['spot_kind', 'spotKind']);
      if (spot == null || (spotAllow.isNotEmpty && !spotAllow.contains(spot))) {
        invalidSpotKind = true;
      }
      final steps = obj['steps'];
      if (steps is! List || steps.length < 4) demoCountBad = true;

      // Token sanity: any of the tokens appear in any string field (id/steps/hints/spot_kind)
      if (!demosTokenOk) {
        if (_objectHasToken(obj, _demoTokenSanity)) demosTokenOk = true;
      }
    }

    // If demos exist but token sanity not hit, mark demos as bad
    if (!demosTokenOk) demoCountBad = true;
  }

  // Drills checks
  final drillsPath = '$versionDir/drills.jsonl';
  var drillCountBad = false;
  var invalidTargets = false;
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
      final line = lines[i];
      Map<String, dynamic> obj;
      try {
        obj = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        drillCountBad = true;
        continue;
      }
      final id = obj['id'];
      if (id is! String || id.isEmpty) {
        drillCountBad = true;
      } else {
        if (!idSeen.add(id)) duplicateIds = true;
      }
      final spot = _firstString(obj, ['spot_kind', 'spotKind']);
      if (spot == null || (spotAllow.isNotEmpty && !spotAllow.contains(spot))) {
        invalidSpotKind = true;
      }
      // target may be a string or a list of strings
      final t = obj['target'];
      final targets = <String>[];
      if (t is String) {
        targets.add(t);
      } else if (t is List) {
        for (final v in t) {
          if (v is String) targets.add(v);
        }
      } else {
        drillCountBad = true;
      }

      if (targets.isEmpty) drillCountBad = true;

      for (final tok in targets) {
        if (targetAllow.isNotEmpty && !targetAllow.contains(tok)) {
          invalidTargets = true;
        }
        final n = _numericSuffix(tok);
        if (n != null && (n != 33 && n != 50 && n != 75)) {
          offTreeSizes = true;
        }
      }
    }
  }

  return GapRow(
    module: moduleId,
    missingSections: missingSections,
    wordcountOutOfRange: wordcountOutOfRange,
    imagesMissing: imagesMissing,
    demoCountBad: demoCountBad,
    drillCountBad: drillCountBad,
    invalidSpotKind: invalidSpotKind,
    invalidTargets: invalidTargets,
    duplicateIds: duplicateIds,
    offTreeSizes: offTreeSizes,
  );
}

Set<String> _readAllowlist(String path) {
  final f = File(path);
  if (!f.existsSync()) return <String>{};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}

String? _firstString(Map<String, dynamic> obj, List<String> keys) {
  for (final k in keys) {
    final v = obj[k];
    if (v is String) return v;
  }
  return null;
}

int? _numericSuffix(String s) {
  final m = RegExp(r'_(\d+)$').firstMatch(s);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

bool _objectHasToken(Map<String, dynamic> obj, Set<String> tokens) {
  bool _scan(dynamic v) {
    if (v is String) {
      for (final t in tokens) {
        if (v.contains(t)) return true;
      }
      return false;
    } else if (v is List) {
      for (final e in v) {
        if (_scan(e)) return true;
      }
      return false;
    } else if (v is Map) {
      for (final e in v.values) {
        if (_scan(e)) return true;
      }
      return false;
    }
    return false;
  }

  for (final e in obj.entries) {
    if (_scan(e.value)) return true;
  }
  return false;
}

void _printReport(List<GapRow> rows) {
  // Stable header and order
  stdout.writeln('module|missing_sections|wordcount_out_of_range|images_missing|demo_count_bad|drill_count_bad|invalid_spot_kind|invalid_targets|duplicate_ids|off_tree_sizes');
  for (final r in rows) {
    final missing = r.missingSections.isEmpty
        ? '-'
        : r.missingSections.join(',');
    stdout.writeln(
      '${r.module}|$missing|${_b(r.wordcountOutOfRange)}|${_b(r.imagesMissing)}|${_b(r.demoCountBad)}|${_b(r.drillCountBad)}|${_b(r.invalidSpotKind)}|${_b(r.invalidTargets)}|${_b(r.duplicateIds)}|${_b(r.offTreeSizes)}',
    );
  }
}

String _b(bool v) => v ? '1' : '0';
