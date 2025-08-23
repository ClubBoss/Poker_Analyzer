import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

final _idRe = RegExp(r'^[a-z0-9_]+$');

List<String> _readSsotIds() {
  final file = File('tooling/curriculum_ids.dart');
  final raw = ascii.decode(ascii.encode(file.readAsStringSync()));
  final listRe = RegExp(
    r'const\s+(?:List<String>\s+)?(?:kCurriculumIds|curriculumIds)\s*=\s*\[',
  );
  final match = listRe.firstMatch(raw);
  if (match == null) {
    throw FormatException('curriculum_ids list not found');
  }
  final start = match.end;
  final end = raw.indexOf('];', start);
  if (end == -1) {
    throw FormatException('curriculum_ids list not closed');
  }
  final body = raw.substring(start, end);
  final ids = <String>[];
  final tokenRe = RegExp(r"['\"]([a-z0-9_]+)['\"]");
  for (final m in tokenRe.allMatches(body)) {
    final id = m.group(1)!;
    if (!_idRe.hasMatch(id)) {
      throw FormatException('Invalid module id: $id');
    }
    ids.add(id);
  }
  return ids;
}

Set<String> _readStatus() {
  final file = File('curriculum_status.json');
  if (!file.existsSync()) return <String>{};
  final raw = ascii.decode(ascii.encode(file.readAsStringSync()));
  final noComments = raw
      .split('\n')
      .where((l) => !l.trim().startsWith('//'))
      .join('\n');
  final cleaned = noComments.replaceAll(',]', ']').replaceAll(',}', '}');
  final data = jsonDecode(cleaned);
  if (data is! Map || data['modules_done'] is! List) {
    throw FormatException('Invalid curriculum_status.json');
  }
  final result = <String>{};
  for (final id in data['modules_done']) {
    if (id is String && _idRe.hasMatch(id)) {
      result.add(id);
    } else {
      throw FormatException('Invalid module id in status: $id');
    }
  }
  return result;
}

void main() {
  test('compute NEXT from SSOT', () {
    final ssot = _readSsotIds();
    final status = _readStatus();
    expect(ssot.toSet().containsAll(status), isTrue);
    var next = 'none';
    for (final id in ssot) {
      if (!status.contains(id)) {
        next = id;
        break;
      }
    }
    // ignore: avoid_print
    print('NEXT: $next');
  });
}

