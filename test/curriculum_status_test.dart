import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tooling/curriculum_ids.dart';

void main() {
  test('curriculum status integrity', () {
    final file = File('curriculum_status.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(data.containsKey('modules_done'), isTrue);
    final modulesDone = (data['modules_done'] as List).cast<String>();

    // No duplicates
    expect(modulesDone.length, equals(modulesDone.toSet().length));

    // Every entry valid
    for (final module in modulesDone) {
      expect(
        kCurriculumModuleIds.contains(module),
        isTrue,
        reason: 'Unknown module: $module',
      );
    }

    final next = firstMissing(modulesDone);
    print('NEXT: $next');
  });
}
