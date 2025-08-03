import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/utils/template_coverage_utils.dart';

void main() {
  test('CoverageSummary calculates and applies meta', () {
    final spots = <TrainingPackSpot>[
      TrainingPackSpot(
        id: 's1',
        hand: HandData(
          heroCards: '',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: const {'0': 10, '1': 10},
          actions: {
            0: [ActionEntry(0, 0, 'push', amount: 10, ev: 1.0)],
          },
        ),
        priority: 2,
      ),
      TrainingPackSpot(
        id: 's2',
        hand: HandData(
          heroCards: '',
          position: HeroPosition.sb,
          heroIndex: 0,
          playerCount: 2,
          stacks: const {'0': 10, '1': 10},
          actions: {
            0: [ActionEntry(0, 0, 'push', amount: 10)],
          },
        ),
        priority: 3,
      ),
    ];
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 't',
      spotCount: 2,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: const [],
      spots: spots,
    );
    final summary = TemplateCoverageUtils.recountAll(tpl);
    expect(summary.ev, 2);
    expect(summary.icm, 0);
    expect(summary.total, 5);
    summary.applyTo(tpl.meta);
    expect(tpl.evCovered, 2);
    expect(tpl.icmCovered, 0);
    expect(tpl.totalWeight, 5);
  });
}
