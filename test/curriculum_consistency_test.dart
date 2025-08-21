import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../tooling/curriculum_ids.dart' as ssot;

void main() {
  test('every curriculum ID has a loader', () {
    for (final id in ssot.kCurriculumIds) {
      final file = File('lib/packs/${id}_loader.dart');
      expect(file.existsSync(), isTrue, reason: 'Missing loader for $id');
    }
  });

  test('curriculum_status.json lists all modules in SSOT order', () {
    final status = jsonDecode(File('curriculum_status.json').readAsStringSync()) as Map;
    final modules = (status['modules_done'] as List).cast<String>();
    expect(modules, equals(ssot.kCurriculumIds));
  });
}
