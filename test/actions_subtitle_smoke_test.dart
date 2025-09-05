import 'package:test/test.dart';

import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';

void main() {
  group('actions/subtitle smoke', () {
    final jamKinds = SpotKind.values.where((k) => k.name.contains('jam_vs_')).toList();

    test('every jam_vs_* has jam/fold actions in order', () {
      for (final k in jamKinds) {
        expect(actionsMap.containsKey(k), isTrue, reason: 'actionsMap missing entry for ${k.name}');
        expect(actionsMap[k], equals(['jam', 'fold']), reason: 'actionsMap[${k.name}] must be ["jam","fold"]');
      }
    });

    test('subtitle prefixes for l3 flop/turn/river jam_vs_*', () {
      for (final k in jamKinds) {
        final n = k.name;
        String? expectedPrefix;
        if (n.startsWith('l3_flop_')) expectedPrefix = 'Flop ';
        if (n.startsWith('l3_turn_')) expectedPrefix = 'Turn ';
        if (n.startsWith('l3_river_')) expectedPrefix = 'River ';
        if (expectedPrefix != null) {
          expect(subtitlePrefix.containsKey(k), isTrue, reason: 'subtitlePrefix missing entry for ${k.name}');
          expect(subtitlePrefix[k]!.startsWith(expectedPrefix), isTrue,
              reason: 'subtitlePrefix[${k.name}] must start with "$expectedPrefix"');
        }
      }
    });
  });
}

