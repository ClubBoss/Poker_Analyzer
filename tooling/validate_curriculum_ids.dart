import 'dart:convert';
import 'dart:io';

final _idRe = RegExp(r'^[a-z0-9_]+$');
final _listRe = RegExp(
  r'const\s+(?:List<String>\s+)?(?:kCurriculumIds|curriculumIds)\s*=\s*\[',
);

List<String> _parseIds(String raw) {
  final m = _listRe.firstMatch(raw);
  if (m == null) {
    stderr.writeln('curriculum_ids list not found');
    exit(2);
  }
  final start = m.end;
  final end = raw.indexOf('];', start);
  if (end == -1) {
    stderr.writeln('curriculum_ids list not closed');
    exit(2);
  }
  final body = raw.substring(start, end);
  final rx = RegExp(r'''["']([a-z0-9_]+)["']''');
  final ids = <String>[];
  for (final mm in rx.allMatches(body)) {
    final id = mm.group(1)!;
    if (!_idRe.hasMatch(id)) {
      stderr.writeln('Invalid id: $id');
      exit(2);
    }
    ids.add(id);
  }
  if (ids.isEmpty) {
    stderr.writeln('No ids found');
    exit(2);
  }
  if (ids.toSet().length != ids.length) {
    stderr.writeln('Duplicate ids found');
    exit(2);
  }
  return ids;
}

void main(List<String> args) {
  final jsonMode = args.contains('--json');
  final raw = File('tooling/curriculum_ids.dart').readAsStringSync();
  final ids = _parseIds(raw);
  if (jsonMode) {
    print(jsonEncode({'ids': ids, 'count': ids.length}));
  } else {
    print('OK (${ids.length} ids)');
  }
}
