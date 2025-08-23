import 'dart:convert';
import 'dart:io';

final _idRe = RegExp(r'^[a-z0-9_]+$');
final _listRe = RegExp(
  r'const\s+(?:List<String>\s+)?(?:kCurriculumIds|curriculumIds)\s*=\s*\[',
);
final _tokenRe = RegExp(r"['\"]([a-z0-9_]+)['\"]");

List<String> _parseIds(String raw) {
  final match = _listRe.firstMatch(raw);
  if (match == null) {
    throw FormatException('curriculum_ids list not found');
  }
  final start = match.end;
  final end = raw.indexOf('];', start);
  if (end == -1) {
    throw FormatException('curriculum_ids list not closed');
  }
  final body = raw.substring(start, end);
  if (!body.trimRight().endsWith(',')) {
    throw FormatException('Missing trailing comma');
  }
  final ids = <String>[];
  for (final m in _tokenRe.allMatches(body)) {
    final id = m.group(1)!;
    if (!_idRe.hasMatch(id)) {
      throw FormatException('Invalid id: $id');
    }
    ids.add(id);
  }
  return ids;
}

void main(List<String> args) {
  try {
    final raw =
        ascii.decode(ascii.encode(File('tooling/curriculum_ids.dart').readAsStringSync()));
    final ids = _parseIds(raw);
    if (ids.isEmpty) {
      stderr.writeln('No ids found');
      exit(2);
    }
    if (ids.toSet().length != ids.length) {
      stderr.writeln('Duplicate ids found');
      exit(2);
    }
    if (args.contains('--json')) {
      print(jsonEncode({'ids': ids, 'count': ids.length}));
    } else {
      print('OK (${ids.length} ids)');
    }
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(2);
  }
}

