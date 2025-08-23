import 'dart:convert';
import 'dart:io';

final _idRe = RegExp(r'^[a-z0-9_]+$');

List<String> parseQueue(File file) {
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

List<String> readStatus(File file) {
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

List<String> mergeStatus(
  List<String> existing,
  List<String> queue,
  Set<String> done,
) {
  final merged = List<String>.from(existing);
  for (final id in queue) {
    if (done.contains(id) && !existing.contains(id)) {
      merged.add(id);
    }
  }
  return merged;
}

void main(List<String> args) {
  final write = args.contains('--write');
  try {
    final queue = parseQueue(File('RESEARCH_QUEUE.md'));
    final done = <String>{};
    for (final id in queue) {
      if (Directory('content/$id/v1').existsSync()) {
        done.add(id);
      }
    }
    final statusFile = File('curriculum_status.json');
    final existing = readStatus(statusFile);
    final merged = mergeStatus(existing, queue, done);
    final toAppend = merged.skip(existing.length).toList();
    stdout.writeln('queue: ${queue.length}');
    stdout.writeln('done existing: ${existing.length}');
    stdout.writeln('newly done: ${toAppend.length}');
    if (toAppend.isNotEmpty) {
      stdout.writeln('would append: ${toAppend.join(', ')}');
    }
    if (write) {
      final encoder = JsonEncoder.withIndent('  ');
      final jsonStr = encoder.convert({'modules_done': merged});
      statusFile.writeAsStringSync('$jsonStr\n', encoding: ascii);
    }
    exit(0);
  } on FormatException catch (e) {
    stderr.writeln('parse error: ${e.message}');
    exit(2);
  } on IOException catch (e) {
    stderr.writeln('io error: $e');
    exit(4);
  }
}
