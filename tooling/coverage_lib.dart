import 'dart:convert';
import 'dart:io';

final _ascii = AsciiCodec();

String _readAscii(String path) =>
    _ascii.decode(_ascii.encode(File(path).readAsStringSync()));

Map<String, dynamic> _defaultCoverage(String id, {String? shortScope}) {
  final coreLike = RegExp(r'^(core_|cash_|mtt_|hu_)').hasMatch(id);
  final phrases = <String>[];
  if (shortScope != null) {
    // немного автоматической конкретики из short_scope
    phrases.addAll(
      shortScope
          .split(RegExp(r'[;,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty),
    );
  }
  // строгие дефолты для структуры
  return {
    "theory_min_words": 450,
    "theory_max_words": 600,
    "must_contain_phrases": phrases,
    "require_positions": coreLike, // для большинства модулей полезно
    "demos_min": 2,
    "demos_max": 3,
    "drills_min": 12,
    "drills_max": 16,
  };
}

Map<String, String> readShortScope() {
  final f = File('tooling/short_scope.json');
  if (!f.existsSync()) return {};
  final raw = _readAscii(f.path);
  final data = jsonDecode(raw) as Map<String, dynamic>;
  return data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
}

Map<String, dynamic> loadCoverage(String id) {
  final short = readShortScope()[id];
  final file = File('tooling/coverage/$id.json');
  if (!file.existsSync()) {
    return _defaultCoverage(id, shortScope: short);
  }
  final raw = _readAscii(file.path);
  final map = jsonDecode(raw) as Map<String, dynamic>;
  // слияние с дефолтом: дефолт → поверх файл
  final base = _defaultCoverage(id, shortScope: short);
  base.addAll(map);
  return base;
}

String buildCoverageContract(String id) {
  final c = loadCoverage(id);
  final minW = c["theory_min_words"];
  final maxW = c["theory_max_words"];
  final phrases = (c["must_contain_phrases"] as List).cast<String>();
  final reqPos = c["require_positions"] == true;
  final dMin = c["demos_min"];
  final dMax = c["demos_max"];
  final rMin = c["drills_min"];
  final rMax = c["drills_max"];

  final buf = StringBuffer();
  buf.writeln('COVERAGE CONTRACT (must pass before output)');
  buf.writeln('- Word count in theory.md: $minW–$maxW words.');
  if (phrases.isNotEmpty) {
    buf.writeln('- Must include phrases/topics (case-insensitive):');
    for (final p in phrases) {
      buf.writeln('  - $p');
    }
  }
  if (reqPos) {
    buf.writeln(
      '- The mini example must use positions: UTG, MP, CO, BTN, SB, BB.',
    );
  }
  buf.writeln(
    '- demos.jsonl: $dMin–$dMax items. drills.jsonl: $rMin–$rMax items.',
  );
  buf.writeln(
    '- If any check fails, silently revise and re-run internal QA before output.',
  );
  return buf.toString();
}
