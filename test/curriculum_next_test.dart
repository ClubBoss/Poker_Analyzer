import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'tooling/curriculum_ids.dart';

void main() {
  test('curriculum NEXT printer', () {
    final status =
        jsonDecode(File('curriculum_status.json').readAsStringSync())
            as Map<String, dynamic>;
    final done = (status['modules_done'] as List).cast<String>().toSet();

    String? nextId;
    for (final id in kCurriculumModuleIds) {
      if (!done.contains(id)) {
        nextId = id;
        break;
      }
    }

    print(nextId == null ? 'NEXT: done' : 'NEXT: $nextId');

    if (nextId != null) {
      expect(nextId.contains(':'), isFalse);
      expect(kCurriculumModuleIds, contains(nextId));
    }
  });
}
