import 'dart:io';
import '../tooling/curriculum_ids.dart';

void main() {
  final ids = kCurriculumIds;
  final covered = <String>[];
  final missing = <String>[];

  for (final id in ids) {
    final f = File('lib/packs/${id}_loader.dart');
    (f.existsSync() ? covered : missing).add(id);
  }

  print('COVERED=${covered.length}/${ids.length}');
  if (covered.isNotEmpty) {
    print('--- covered ---');
    covered.forEach(print);
  }
  if (missing.isNotEmpty) {
    print('--- missing ---');
    missing.forEach(print);
  }

  // Санити-чек против curriculum_status.json
  final status = File('curriculum_status.json').readAsStringSync();
  final done = RegExp(r'"modules_done"\s*:\s*\[(.*?)\]', dotAll: true)
      .firstMatch(status)!
      .group(1)!
      .split(',')
      .map((s) => s.replaceAll(RegExp(r'[\s"\n]'), ''))
      .where((s) => s.isNotEmpty)
      .toSet();

  final fsOnly = covered.toSet().difference(done);
  final statusOnly = done.difference(covered.toSet());

  print('--- diff vs status.json ---');
  print('in FS only (have loader, not in status): ${fsOnly.length}');
  fsOnly.forEach(print);
  print('in status only (marked done, no loader): ${statusOnly.length}');
  statusOnly.forEach(print);

  if (statusOnly.isNotEmpty) {
    stderr.writeln('WARNING: status marks modules done without loaders.');
    exitCode = 1;
  }
}
