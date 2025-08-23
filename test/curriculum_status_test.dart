import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

final _idRe = RegExp(r'^[a-z0-9_]+$');

List<String> _parseQueue() {
  final file = File('RESEARCH_QUEUE.md');
  final ids = <String>[];
  for (final raw in file.readAsLinesSync()) {
    final line = ascii.decode(ascii.encode(raw));
    if (!line.startsWith('- ')) continue;
    final id = line.substring(2).trim();
    if (!_idRe.hasMatch(id)) {
      throw FormatException('Invalid module id: $id');
    }
    ids.add(id);
  }
  return ids;
}

List<String> _readStatus() {
  final file = File('curriculum_status.json');
  if (!file.existsSync()) return <String>[];
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
  final result = <String>[];
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
  test('compute NEXT from queue', () {
    final queue = _parseQueue();
    final status = _readStatus();
    expect(queue.toSet().containsAll(status), isTrue);
    var next = 'none';
    for (final id in queue) {
      if (!status.contains(id)) {
        next = id;
        break;
      }
    }
    // ignore: avoid_print
    print('NEXT: $next');
  });
}
