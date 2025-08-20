import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../tooling/curriculum_ids.dart';

List<String> _readModulesDone() {
  final text = File('curriculum_status.json').readAsStringSync();
  final map = jsonDecode(text) as Map<String, dynamic>;
  return (map['modules_done'] as List).cast<String>();
}

void main() {
  test('modules_done is strict prefix of SSOT', () {
    final done = _readModulesDone();
    final seen = <String>{};

    for (final id in done) {
      expect(seen.contains(id), isFalse, reason: 'Duplicate id: $id');
      seen.add(id);
      expect(
        kCurriculumModuleIds.contains(id),
        isTrue,
        reason: 'Unknown id: $id',
      );
    }

    for (var i = 0; i < done.length; i++) {
      expect(
        done[i],
        equals(kCurriculumModuleIds[i]),
        reason:
            'Order mismatch at $i: expected ${kCurriculumModuleIds[i]}, got ${done[i]}',
      );
    }
  });

  test('NEXT detector prints first missing by SSOT', () {
    final done = _readModulesDone();
    final next = firstMissing(done);
    if (next == null) {
      print('NEXT: done');
    } else {
      print('NEXT: $next');
      expect(
        kCurriculumModuleIds.contains(next),
        isTrue,
        reason: 'NEXT must be in SSOT',
      );
      expect(next.contains(':'), isFalse, reason: 'NEXT must not be a pack id');
    }
  });
}
