import 'dart:convert';
import 'dart:io';

String idSource = 'queue';

String _normalize(String s) {
  const repl = {
    '“': '"',
    '”': '"',
    '‘': "'",
    '’': "'",
    '–': '-',
    '—': '-',
    '•': '-',
  };
  var out = s;
  repl.forEach((k, v) => out = out.replaceAll(k, v));
  return out;
}

List<String>? _readCurriculumFile() {
  final f = File('tooling/curriculum_ids.dart');
  if (!f.existsSync()) return null;
  final txt = _normalize(f.readAsStringSync());
  final m = RegExp(
          r'const\s+(?:kCurriculumIds|curriculumIds)\s*=\s*\[(.*)\];',
          dotAll: true)
      .firstMatch(txt);
  if (m == null || !m.group(0)!.contains(RegExp(r',\s*\];'))) {
    throw const FormatException('Invalid curriculum_ids.dart');
  }
  final body = m.group(1)!;
  final ids = <String>[];
  for (final line in const LineSplitter().convert(body)) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('//')) continue;
    final match =
        RegExp(r"^['\"]([a-z0-9_]+)['\"],\s*(//.*)?$").firstMatch(t);
    if (match == null) throw const FormatException('Invalid curriculum_ids.dart');
    ids.add(match.group(1)!);
  }
  if (ids.isEmpty) throw const FormatException('No modules found');
  return ids;
}

List<String> _readQueue() {
  final f = File('RESEARCH_QUEUE.md');
  final txt = _normalize(f.readAsStringSync());
  final ids = <String>[];
  for (final line in const LineSplitter().convert(txt)) {
    final t = line.trim();
    if (t.startsWith('-')) {
      final id = t.substring(1).trim();
      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
        throw const FormatException('Invalid module id');
      }
      ids.add(id);
    }
  }
  if (ids.isEmpty) throw const FormatException('No modules found');
  return ids;
}

List<String> readCurriculumIds() {
  try {
    final ids = _readCurriculumFile();
    if (ids != null) {
      idSource = 'curriculum_ids.dart';
      return ids;
    }
  } catch (_) {
    // fall through to queue
  }
  idSource = 'queue';
  return _readQueue();
}
