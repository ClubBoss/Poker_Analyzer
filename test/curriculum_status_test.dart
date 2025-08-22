// Pure-Dart test that prints NEXT and never fails because of missing content.
// It only asserts JSON shape. Order SSOT = tooling/curriculum_ids.dart (append-only).

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('curriculum status: print NEXT based on SSOT order', () async {
    // 1) Load status
    final statusFile = File('curriculum_status.json');
    expect(await statusFile.exists(), isTrue,
        reason: 'curriculum_status.json is required');
    final statusJson = json.decode(await statusFile.readAsString());
    expect(statusJson, isA<Map>());
    expect(statusJson['modules_done'], isA<List>(),
        reason: 'modules_done must be a JSON array');

    final done = <String>{
      ...((statusJson['modules_done'] as List).whereType<String>())
    };

    // 2) Load SSOT order from tooling/curriculum_ids.dart (append-only)
    final idsFile = File('tooling/curriculum_ids.dart');
    expect(await idsFile.exists(), isTrue,
        reason: 'tooling/curriculum_ids.dart is the SSOT for order');
    final src = await idsFile.readAsString();

    // Extract list literal like: const kCurriculumIds = [ 'id_a', "id_b", ... ];
    final listMatch = RegExp(
      r'''(?:kCurriculumIds|curriculumIds)\s*=\s*\[(.*?)\];''',
      dotAll: true,
    ).firstMatch(src);

    List<String> allIds;
    if (listMatch != null) {
      final body = listMatch.group(1)!;
      // Pick both 'id' and "id"
      allIds = RegExp(r"""'([a-z0-9_]+)'|"([a-z0-9_]+)"""")
          .allMatches(body)
          .map((m) => (m.group(1) ?? m.group(2))!)
          .toList(growable: false);
    } else {
      // Fallback: any quoted snake_case tokens
      final matches =
          RegExp(r'''["']([a-z0-9_]+)["']''').allMatches(src).toList();
      allIds = matches.map((m) => m.group(1)!).toSet().toList();
    }

    expect(allIds.isNotEmpty, isTrue,
        reason: 'No curriculum IDs found in tooling/curriculum_ids.dart');

    // 3) Compute NEXT
    String? next;
    for (final id in allIds) {
      if (!done.contains(id)) {
        next = id;
        break;
      }
    }

    // 4) Print NEXT line for downstream parsing
    // ignore: avoid_print
    print(next == null ? 'NEXT = <none>' : 'NEXT = $next');

    // No failing assertions beyond shape checks.
  });
}
