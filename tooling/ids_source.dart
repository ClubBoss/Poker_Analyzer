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
  final m = RegExp(
    r'const\s+(?:List<String>\s+)?(?:kCurriculumIds|curriculumIds)\s*=\s*\[(.*?)\];',
    dotAll: true,
  ).firstMatch(txt);
  if (m == null) throw const FormatException('list not found');
  final body = m.group(1)!;

  // Требуем стиль с запятой перед ]: ,]
  if (!RegExp(r',\s*\]\s*$').hasMatch(txt)) {
    // не критично для загрузки, но можно считать это предупреждением
  }

  final tokRe = RegExp(r'''["']([a-z0-9_]+)["']\s*,''');
  final ids = <String>[];
  for (final mm in tokRe.allMatches(body)) {
    final id = mm.group(1)!;
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
      throw const FormatException('Invalid id token');
    }
    ids.add(id);
  }
  if (ids.isEmpty) throw const FormatException('No modules found');
  return ids;
}

List<String> readCurriculumIds() {
  try {
    final ids = _readCurriculumFile();
    idSource = 'curriculum_ids.dart';
    return ids;
  } catch (_) {
    idSource = 'queue';
    return _readQueue();
  }
}
