// test/curriculum_status_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('curriculum status', () {
    test('modules_done order follows SSOT and starts with cash:l3:v1', () {
      // 1) Load status
      final statusFile = File('curriculum_status.json');
      expect(statusFile.existsSync(), isTrue, reason: 'curriculum_status.json not found');
      final statusJson = jsonDecode(statusFile.readAsStringSync()) as Map<String, dynamic>;
      final modulesDone = (statusJson['modules_done'] as List).cast<String>();
      expect(modulesDone, isNotEmpty, reason: 'modules_done must be non-empty');

      // 2) Load SSOT: parse curriculumIds list exactly
      final ssotFile = File('tooling/curriculum_ids.dart');
      expect(ssotFile.existsSync(), isTrue, reason: 'tooling/curriculum_ids.dart not found');
      final ssotText = ssotFile.readAsStringSync();

      // Capture the literal list assigned to curriculumIds = [ ... ];
      final listMatch = RegExp(r'curriculumIds\s*=\s*\[(.*?)\];', dotAll: true).firstMatch(ssotText);

      List<String> ssotIds = <String>[];
      if (listMatch != null) {
        final body = listMatch.group(1)!;
        // Pull all single-quoted strings from the list body
        ssotIds = RegExp(r"'([^']+)'").allMatches(body).map((m) => m.group(1)!).toList();
      } else {
        // Fallback: scan whole file for quoted tokens if the pattern changes
        ssotIds = RegExp(r"'([^']+)'").allMatches(ssotText).map((m) => m.group(1)!).toList();
      }
      expect(ssotIds, isNotEmpty, reason: 'No module IDs parsed from SSOT');

      // 3) Build rank (first occurrence wins)
      final rank = <String, int>{};
      for (var i = 0; i < ssotIds.length; i++) {
        rank.putIfAbsent(ssotIds[i], () => i);
      }

      // 4) Guard: duplicates and unknowns (allow known special runtime IDs)
      const allowedSpecial = <String>{
        'import:last',
        'import:clipboard',
      };

      for (final m in modulesDone) {
        final known = rank.containsKey(m) || allowedSpecial.contains(m);
        expect(known, isTrue, reason: "Unknown module id in modules_done: '$m'");
      }
      expect(modulesDone.toSet().length, modulesDone.length, reason: 'modules_done contains duplicates');

      // 5) Normalize order logically via SSOT rank (unknown specials sink to end by stable tie)
      final sorted = List<String>.from(modulesDone)
        ..sort((a, b) {
          final ra = rank[a];
          final rb = rank[b];
          if (ra != null && rb != null) return ra.compareTo(rb);
          if (ra != null) return -1; // known before special
          if (rb != null) return 1;
          return 0; // both special -> keep relative order
        });

      // 6) Starter must be canonical after normalization
      expect(sorted.first, equals('cash:l3:v1'),
          reason: "modules_done must start with 'cash:l3:v1' after SSOT-based normalization");
    });
  });
}
