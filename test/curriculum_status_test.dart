// test/curriculum_status_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('curriculum status', () {
    test('modules_done order follows SSOT and starts with cash:l3:v1', () {
      // 1) Load raw status
      final statusFile = File('curriculum_status.json');
      expect(statusFile.existsSync(), isTrue, reason: 'curriculum_status.json not found');
      final statusJson = jsonDecode(statusFile.readAsStringSync()) as Map<String, dynamic>;

      final modulesDone = (statusJson['modules_done'] as List).cast<String>();
      expect(modulesDone, isNotEmpty, reason: 'modules_done must be non-empty');

      // 2) Load SSOT order from tooling/curriculum_ids.dart (regex ID extraction)
      final ssotFile = File('tooling/curriculum_ids.dart');
      expect(ssotFile.existsSync(), isTrue, reason: 'tooling/curriculum_ids.dart not found');

      final ssotText = ssotFile.readAsStringSync();
      // Capture single-quoted IDs like: 'cash:l3:v1'
      final idRegex = RegExp(r"'([a-z0-9_:-]+)'");
      final ssotIds = <String>[];
      for (final m in idRegex.allMatches(ssotText)) {
        final id = m.group(1)!;
        // Heuristic: accept only ids that look like module ids with two colons
        if (id.split(':').length == 3) {
          ssotIds.add(id);
        }
      }
      expect(ssotIds, isNotEmpty, reason: 'No module IDs parsed from SSOT');

      // 3) Build rank map
      final rank = <String, int>{};
      for (var i = 0; i < ssotIds.length; i++) {
        // first occurrence wins
        rank.putIfAbsent(ssotIds[i], () => i);
      }

      // 4) Guards: unknown ids and duplicates
      for (final m in modulesDone) {
        expect(rank.containsKey(m), isTrue, reason: "Unknown module id in modules_done: '$m'");
      }
      expect(modulesDone.toSet().length, modulesDone.length, reason: 'modules_done contains duplicates');

      // 5) Normalize order logically (no disk writes)
      final sorted = List<String>.from(modulesDone)
        ..sort((a, b) => rank[a]!.compareTo(rank[b]!));

      // 6) Expect first module is the canonical starter
      expect(sorted.first, equals('cash:l3:v1'),
          reason: "modules_done must start with 'cash:l3:v1' after SSOT-based normalization");
    });
  });
}
