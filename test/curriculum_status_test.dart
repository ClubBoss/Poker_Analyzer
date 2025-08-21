import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import '../tooling/curriculum_ids.dart'; // exposes kCurriculumIds

String firstMissing(List<String> base, List<String> done) {
  for (final id in base) {
    if (!done.contains(id)) return id;
  }
  return 'ALL_DONE';
}

void main() {
  final status =
      jsonDecode(File('curriculum_status.json').readAsStringSync())
          as Map<String, dynamic>;
  final done = (status['modules_done'] as List).cast<String>();
  final base = kCurriculumIds;

  test('status uses valid IDs only', () {
    expect(
      done.every(base.contains),
      isTrue,
      reason: 'curriculum_status.json contains unknown module IDs',
    );
  });

  test('status is a strict prefix of base order', () {
    final n = done.length < base.length ? done.length : base.length;
    for (var i = 0; i < n; i++) {
      expect(
        done[i],
        equals(base[i]),
        reason:
            'Order mismatch at index $i: expected ${base[i]}, got ${done[i]}',
      );
    }
  });

  test('compute and print NEXT', () {
    final next = firstMissing(base, done);
    // ignore: avoid_print
    print('NEXT=$next');
    if (next != 'ALL_DONE') {
      expect(base.contains(next), isTrue);
    }
  });
}
