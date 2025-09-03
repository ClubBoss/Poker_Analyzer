import 'dart:io';

String idSource = 'queue';

String _ascii(String s) {
  final b = StringBuffer();
  for (final c in s.codeUnits) {
    if (c == 0x0D) continue;
    b.writeCharCode(c <= 0x7F ? c : 0x3F);
  }
  return b.toString();
}

List<String> _readQueue() {
  final f = File('RESEARCH_QUEUE.md');
  final ids = <String>[];
  for (final raw in f.readAsLinesSync()) {
    final t = _ascii(raw).trimLeft();
    if (!t.startsWith('- ')) continue;
    final id = t.substring(2).trim();
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
      throw const FormatException('Invalid module id');
    }
    ids.add(id);
  }
  if (ids.isEmpty) throw const FormatException('No modules found');
  return ids;
}

List<String> _readCurriculumFile() {
  final f = File('tooling/curriculum_ids.dart');
  if (!f.existsSync())
    throw const FormatException('missing curriculum_ids.dart');
  final txt = _ascii(f.readAsStringSync());
  // Try tolerant, ordered patterns to capture the bracket block.
  final patterns = <RegExp>[
    RegExp(
      r'const\s+List<String>\s+curriculumIds\s*=\s*\[(.*?)\];',
      dotAll: true,
    ),
    RegExp(
      r'const\s+List<String>\s+kCurriculumIds\s*=\s*\[(.*?)\];',
      dotAll: true,
    ),
    RegExp(r'const\s+List<String>\s+\w+\s*=\s*\[(.*?)\];', dotAll: true),
  ];

  // Collect all candidate matches (in order), then pick the one with most IDs.
  final candidates = <String>[];
  for (final p in patterns) {
    final ms = p.allMatches(txt).toList();
    for (final m in ms) {
      final body = m.group(1) ?? '';
      candidates.add(body);
    }
  }

  if (candidates.isEmpty) throw const FormatException('list not found');

  final tokRe = RegExp(r'"([a-z0-9_]+)"\s*,');
  List<String> best = const [];
  for (final body in candidates) {
    final ids = <String>[];
    for (final mm in tokRe.allMatches(body)) {
      ids.add(mm.group(1)!);
    }
    if (ids.length > best.length) best = ids;
  }

  if (best.isEmpty) throw const FormatException('No modules found');
  return best;
}

List<String> readCurriculumIds() {
  try {
    final ids = _readCurriculumFile();
    idSource = 'curriculum_ids.dart';
    stdout.writeln('ID SOURCE: curriculum_ids.dart');
    return ids;
  } catch (_) {
    idSource = 'queue';
    return _readQueue();
  }
}
