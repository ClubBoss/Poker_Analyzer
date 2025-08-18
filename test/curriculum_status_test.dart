// test/curriculum_status_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('curriculum status', () {
    test('modules_done follows SSOT order and starts with first canonical present', () {
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

      final listMatch = RegExp(r'curriculumIds\s*=\s*\[(.*?)\];', dotAll: true).firstMatch(ssotText);
      List<String> ssotIds = <String>[];
      if (listMatch != null) {
        final body = listMatch.group(1)!;
        ssotIds = RegExp(r"'([^']+)'").allMatches(body).map((m) => m.group(1)!).toList();
      } else {
        ssotIds = RegExp(r"'([^']+)'").allMatches(ssotText).map((m) => m.group(1)!).toList();
      }
      expect(ssotIds, isNotEmpty, reason: 'No module IDs parsed from SSOT');

      // 3) Build rank
      final rank = <String, int>{};
      for (var i = 0; i < ssotIds.length; i++) {
        rank.putIfAbsent(ssotIds[i], () => i);
      }

      // 4) Guards: duplicates and unknowns (allow special runtime IDs)
      const allowedSpecial = <String>{'import:last', 'import:clipboard'};

      for (final m in modulesDone) {
        final known = rank.containsKey(m) || allowedSpecial.contains(m);
        expect(known, isTrue, reason: "Unknown module id in modules_done: '$m'");
      }
      expect(modulesDone.toSet().length, modulesDone.length, reason: 'modules_done contains duplicates');

      // 5) Normalize order logically via SSOT rank (specials sink to end, stable tie)
      final sorted = List<String>.from(modulesDone)
        ..sort((a, b) {
          final ra = rank[a];
          final rb = rank[b];
          if (ra != null && rb != null) return ra.compareTo(rb);
          if (ra != null) return -1; // known before special
          if (rb != null) return 1;
          return 0; // both special -> keep relative order
        });

      // 6) Expected starter = first SSOT id that appears in modules_done
      String? expectedStarter;
      for (final id in ssotIds) {
        if (modulesDone.contains(id)) {
          expectedStarter = id;
          break;
        }
      }
      expect(expectedStarter, isNotNull,
          reason: 'None of the SSOT curriculum IDs are present in modules_done');

      expect(sorted.first, equals(expectedStarter),
          reason: "modules_done must start with the first canonical ID present per SSOT ordering");

      // 7) Optional: specials must not precede any canonical present IDs
      final firstSpecialIdx = sorted.indexWhere((m) => !rank.containsKey(m));
      if (firstSpecialIdx != -1) {
        final anyCanonicalAfter = sorted.skip(firstSpecialIdx).any((m) => rank.containsKey(m));
        expect(anyCanonicalAfter, isFalse,
            reason: 'Special IDs must come after all canonical IDs present');
      }
    });
  });
}
