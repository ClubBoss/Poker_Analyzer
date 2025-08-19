import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'tooling/curriculum_ids.dart';

void main() {
test('curriculum status discipline', () {
final ids = List<String>.from(curriculumIds);

// SSOT sanity: no duplicates in curriculumIds
expect(ids.toSet().length, ids.length,
    reason: 'curriculumIds has duplicates');

// Load status JSON
final statusRaw = File('curriculum_status.json').readAsStringSync();
final status = jsonDecode(statusRaw) as Map<String, dynamic>;
final done = (status['modules_done'] as List).cast<String>();

// 1) No duplicates in modules_done
expect(done.toSet().length, done.length,
    reason: 'modules_done has duplicates');

// 2) Every done id exists in curriculumIds
final unknown =
    done.where((id) => !ids.contains(id)).toList(growable: false);
expect(unknown, isEmpty,
    reason:
        'modules_done contains ids not present in curriculumIds: $unknown');

// 3) Order of modules_done follows curriculumIds order (strictly increasing)
var lastIdx = -1;
for (final id in done) {
  final idx = ids.indexOf(id);
  expect(idx, isNot(-1), reason: 'Unknown id encountered: $id');
  expect(idx > lastIdx, isTrue,
      reason:
          'modules_done order violates curriculumIds order at "$id" (idx=$idx, lastIdx=$lastIdx)');
  lastIdx = idx;
}

// 4) Derive NEXT (first id in ids not contained in done).
final next =
    ids.firstWhere((id) => !done.contains(id), orElse: () => '');

// If NEXT exists, all previous ids before it must be done.
if (next.isNotEmpty) {
  final prev = ids.takeWhile((id) => id != next);
  final missedBeforeNext =
      prev.where((id) => !done.contains(id)).toList(growable: false);
  expect(missedBeforeNext, isEmpty,
      reason:
          'Found missing modules before NEXT: $missedBeforeNext (NEXT should be the first missing id)');
}

// Print NEXT line for convenience and tooling.
// ignore: avoid_print
print('NEXT: ${next.isNotEmpty ? next : '(none)'}');


});
}
