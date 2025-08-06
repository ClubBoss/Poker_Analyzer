import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tag_coverage_report.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_set.dart';
import 'package:poker_analyzer/services/tag_balancer_engine.dart';

void main() {
  test('balance selects spots covering underrepresented tags', () {
    final spotA = TrainingPackSpot(id: 'A1', tags: ['A']);
    final spotB1 = TrainingPackSpot(id: 'B1', tags: ['B']);
    final spotB2 = TrainingPackSpot(id: 'B2', tags: ['B']);
    final spotC = TrainingPackSpot(id: 'C1', tags: ['C']);
    final template = TrainingPackTemplateV2(
      id: 'tpl',
      name: 'tpl',
      spots: [spotA, spotB1, spotB2, spotC],
      spotCount: 4,
    );
    final set = TrainingPackTemplateSet(template: template);
    final coverage = SkillTagCoverageReport(
      tagCounts: const {'A': 10, 'B': 1, 'C': 2},
      totalSpots: 13,
    );

    final engine = const TagBalancerEngine(maxBoostCount: 3);
    final boost = engine.balance(set, coverage);

    expect(boost.length, 1);
    expect(boost.first.id, 'B1');
  });
}

