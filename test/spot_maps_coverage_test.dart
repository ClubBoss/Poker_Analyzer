import 'dart:io';

import 'package:test/test.dart';

import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';

void main() {
  group('spot maps coverage', () {
    test('actionsMap and subtitlePrefix cover all SpotKind values', () {
      for (final k in SpotKind.values) {
        expect(actionsMap.containsKey(k), isTrue,
            reason: 'actionsMap missing entry for ${k.name}');
        expect(actionsMap[k], isA<List<String>>(),
            reason: 'actionsMap[${k.name}] must be a List<String>');
        expect((actionsMap[k] as List).isNotEmpty, isTrue,
            reason: 'actionsMap[${k.name}] must be non-empty');

        if (k.name.contains('jam_vs_')) {
          expect(actionsMap[k], equals(['jam', 'fold']),
              reason: 'jam_vs_* must map to ["jam","fold"]: ${k.name}');
        }

        expect(subtitlePrefix.containsKey(k), isTrue,
            reason: 'subtitlePrefix missing entry for ${k.name}');
        final sub = (subtitlePrefix[k] ?? '').toString();
        expect(sub.isNotEmpty, isTrue,
            reason: 'subtitlePrefix[${k.name}] must be non-empty');

        if (k.name.startsWith('l3_flop_')) {
          expect(sub.startsWith('Flop '), isTrue,
              reason: 'subtitlePrefix[${k.name}] must start with "Flop "');
        }
        if (k.name.startsWith('l3_turn_')) {
          expect(sub.startsWith('Turn '), isTrue,
              reason: 'subtitlePrefix[${k.name}] must start with "Turn "');
        }
        if (k.name.startsWith('l3_river_')) {
          expect(sub.startsWith('River '), isTrue,
              reason: 'subtitlePrefix[${k.name}] must start with "River "');
        }
      }
    });

    test('no legacy switch over SpotKind present in spot_specs.dart', () {
      final src = File('lib/ui/session_player/spot_specs.dart').readAsStringSync();
      expect(src.contains('switch (spot.kind'), isFalse,
          reason: 'Legacy switch(spot.kind) must not be present');
      final caseRe = RegExp(r'case\s+SpotKind\.', multiLine: true);
      expect(caseRe.hasMatch(src), isFalse,
          reason: 'Legacy case SpotKind.* must not be present');
    });
  });
}

