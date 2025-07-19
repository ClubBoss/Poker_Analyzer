import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';

void main() {
  test('toYaml and fromYaml round trip with postflop fields', () {
    final combos = [
      {'street': 1, 'action': 'none'},
      {'street': 1, 'action': 'check'},
      {'street': 1, 'action': 'bet'},
      {'street': 2, 'action': 'none'},
      {'street': 2, 'action': 'check'},
      {'street': 2, 'action': 'bet'},
      {'street': 3, 'action': 'none'},
      {'street': 3, 'action': 'check'},
      {'street': 3, 'action': 'bet'},
    ];

    for (var i = 0; i < combos.length; i++) {
      final c = combos[i];
      final spot = TrainingPackSpot(
        id: 's$i',
        hand: HandData(),
        board: ['Ah', 'Kd', 'Qs'],
        street: c['street'] as int,
        villainAction: c['action'] as String?,
        heroOptions: ['call', 'raise'],
      );
      final yamlMap = spot.toYaml();
      final restored = TrainingPackSpot.fromYaml(yamlMap);
      expect(restored.street, spot.street);
      expect(restored.board, spot.board);
      expect(restored.villainAction, spot.villainAction);
      expect(restored.heroOptions, spot.heroOptions);
    }
  });

  test('fromYaml applies defaults for missing fields', () {
    const yamlStr = '''
id: a1
title: Test
''';
    final map = const YamlReader().read(yamlStr);
    final spot = TrainingPackSpot.fromYaml(map);
    expect(spot.street, 0);
    expect(spot.board, isEmpty);
    expect(spot.villainAction, isNull);
    expect(spot.heroOptions, isEmpty);
  });
}
