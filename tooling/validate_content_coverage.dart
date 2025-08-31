import 'dart:convert';
import 'dart:io';
import 'coverage_lib.dart';

final _ascii = AsciiCodec();
String _readAscii(String path) =>
    _ascii.decode(_ascii.encode(File(path).readAsStringSync()));

bool _hasPositions(String s) =>
    RegExp(r'\b(UTG|MP|CO|BTN|SB|BB)\b').hasMatch(s);

int _wordCount(String s) =>
    s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

List<String> _readAllow(String path) {
  final f = File(path);
  if (!f.existsSync()) return const [];
  return _readAscii(path)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && l != 'none')
      .toList();
}

List<String> _validateTheory(String text, Map<String, dynamic> cov) {
  final errs = <String>[];
  final w = _wordCount(text);
  final minW = cov['theory_min_words'] as int;
  final maxW = cov['theory_max_words'] as int;
  if (w < minW || w > maxW) {
    errs.add('theory.md words=$w not in [$minW,$maxW]');
  }
  final phrases = (cov['must_contain_phrases'] as List).cast<String>();
  for (final p in phrases) {
    if (!text.toLowerCase().contains(p.toLowerCase())) {
      errs.add('missing phrase: "$p"');
    }
  }
  if (cov['require_positions'] == true && !_hasPositions(text)) {
    errs.add('positions missing (UTG/MP/CO/BTN/SB/BB)');
  }
  return errs;
}

List<String> _validateJsonl(String path,
    {required int min, required int max, required bool isDrill, required List<String> spotAllow}) {
  final errs = <String>[];
  final f = File(path);
  if (!f.existsSync()) {
    errs.add('missing file: $path');
    return errs;
  }
  final lines = _readAscii(path)
      .split('\n')
      .where((l) => l.trim().isNotEmpty)
      .toList();
  if (lines.length < min || lines.length > max) {
    errs.add('$path count=${lines.length} not in [$min,$max]');
  }
  final idRe = RegExp(r'^[a-z0-9_]+:(demo|drill):\d{2}$');
  final targetRe = RegExp(r'^[a-z0-9_]+$');

  for (var i = 0; i < lines.length; i++) {
    final ln = lines[i];
    dynamic obj;
    try {
      obj = jsonDecode(ln);
    } catch (_) {
      errs.add('$path line ${i + 1}: invalid JSON');
      continue;
    }
    if (obj is! Map) {
      errs.add('$path line ${i + 1}: not an object');
      continue;
    }
    final id = obj['id']?.toString() ?? '';
    final sk = obj['spot_kind']?.toString() ?? '';
    if (!idRe.hasMatch(id)) errs.add('$path line ${i + 1}: bad id "$id"');
    if (sk.isEmpty) errs.add('$path line ${i + 1}: missing spot_kind');
    if (spotAllow.isNotEmpty && !spotAllow.contains(sk)) {
      errs.add('$path line ${i + 1}: spot_kind "$sk" not in allowlist');
    }
    if (isDrill) {
      final q = obj['question']?.toString() ?? '';
      final tgt = obj['target']?.toString() ?? '';
      final rat = obj['rationale']?.toString() ?? '';
      if (q.isEmpty || tgt.isEmpty || rat.isEmpty) {
        errs.add('$path line ${i + 1}: missing question/target/rationale');
      }
      if (tgt.isNotEmpty && !targetRe.hasMatch(tgt)) {
        errs.add('$path line ${i + 1}: target not snake_case');
      }
    } else {
      final steps = obj['steps'];
      if (steps is! List || steps.isEmpty || steps.any((e) => (e?.toString() ?? '').trim().isEmpty)) {
        errs.add('$path line ${i + 1}: steps missing/empty');
      }
    }
  }
  return errs;
}

void main(List<String> args) {
  if (args.length != 2 || args.first != '--id') {
    stderr.writeln('usage: dart run tooling/validate_content_coverage.dart --id <module_id>');
    exit(2);
  }
  final id = args[1];
  final cov = loadCoverage(id);

  final base = 'content/$id/v1';
  final theoryPath = '$base/theory.md';
  final demosPath = '$base/demos.jsonl';
  final drillsPath = '$base/drills.jsonl';
  final spotAllow = _readAllow('tooling/allowlists/spotkind_allowlist_${id}.txt');

  final errs = <String>[];
  // theory
  try {
    final t = _readAscii(theoryPath);
    errs.addAll(_validateTheory(t, cov));
  } catch (_) {
    errs.add('missing file: $theoryPath');
  }
  // demos
  errs.addAll(_validateJsonl(
    demosPath,
    min: cov['demos_min'] as int,
    max: cov['demos_max'] as int,
    isDrill: false,
    spotAllow: spotAllow,
  ));
  // drills
  errs.addAll(_validateJsonl(
    drillsPath,
    min: cov['drills_min'] as int,
    max: cov['drills_max'] as int,
    isDrill: true,
    spotAllow: spotAllow,
  ));

  if (errs.isEmpty) {
    print('OK id=$id');
  } else {
    for (final e in errs) {
      stderr.writeln(e);
    }
    exit(2);
  }
}
