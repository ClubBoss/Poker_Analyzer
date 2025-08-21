import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tooling/curriculum_ids.dart' as ssot;

void main() {
  test('status matches SSOT and loaders exist', () {
    final ids = ssot.kCurriculumIds;
    expect(ids.length, equals(ids.toSet().length), reason: 'Duplicate curriculum ids');

    for (final id in ids) {
      final loader = File('lib/packs/${id}_loader.dart');
      expect(loader.existsSync(), isTrue, reason: 'Missing loader for $id');
    }

    final json = jsonDecode(File('curriculum_status.json').readAsStringSync()) as Map<String, dynamic>;
    final modules = (json['modules_done'] as List).cast<String>();
    expect(modules, equals(ids));
  });
}
