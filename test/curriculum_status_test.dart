import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../tooling/curriculum_ids.dart' as ssot;

List<String> _readModulesDone() {
  final text = File('curriculum_status.json').readAsStringSync();
  final map = jsonDecode(text) as Map<String, dynamic>;
  return (map['modules_done'] as List).cast<String>();
}

String? _firstMissing(List<String> done) {
  final base = ssot.kCurriculumIds;
  for (var i = 0; i < base.length; i++) {
    if (i >= done.length) return base[i];
    if (base[i] != done[i]) return base[i];
  }
  return null;
}

void main() {
  test('modules_done is strict prefix of SSOT', () {
    final done = _readModulesDone();
    final seen = <String>{};

    for (final id in done) {
      expect(seen.contains(id), isFalse, reason: 'Duplicate id: $id');
      seen.add(id);
      expect(
        ssot.kCurriculumIds.contains(id),
        isTrue,
        reason: 'Unknown id: $id',
      );
    }

    for (var i = 0; i < done.length; i++) {
      expect(
        done[i],
        equals(ssot.kCurriculumIds[i]),
        reason:
            'Order mismatch at $i: expected ${ssot.kCurriculumIds[i]}, got ${done[i]}',
      );
    }
  });

  test('NEXT detector prints first missing by SSOT', () {
    final done = _readModulesDone();
    final next = _firstMissing(done);
    if (next == null) {
      print('NEXT:ALL_DONE');
    } else {
      print('NEXT: $next');
      expect(
        ssot.kCurriculumIds.contains(next),
        isTrue,
        reason: 'NEXT must be in SSOT',
      );
      expect(next.contains(':'), isFalse, reason: 'NEXT must not be a pack id');
    }
  });
}
