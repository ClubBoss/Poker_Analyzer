// tooling/audit_skeleton.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'curriculum_ids.dart';

void main(List<String> args) {
  final ids = kCurriculumIds;

  int prefix = 0;
  for (; prefix < ids.length; prefix++) {
    final id = ids[prefix];
    final path = 'lib/packs/${id}_loader.dart';
    if (!File(path).existsSync()) {
      break;
    }
  }

  final missing = <String>[];
  for (final id in ids) {
    final path = 'lib/packs/${id}_loader.dart';
    if (!File(path).existsSync()) {
      missing.add(id);
    }
  }
  missing.sort();

  final next = prefix < ids.length ? ids[prefix] : 'ALL DONE';

  print('DONE_PREFIX=$prefix');
  print('NEXT=$next');
  print('MISSING:');
  for (final id in missing) {
    print(id);
  }

  if (args.contains('--write-status')) {
    final done = ids.take(prefix).toList();
    final encoder = const JsonEncoder.withIndent('  ');
    final json = encoder.convert({'modules_done': done}) + '\n';
    File('curriculum_status.json').writeAsStringSync(json);
  }
}
