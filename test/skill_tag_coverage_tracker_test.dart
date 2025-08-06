import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/skill_tag_coverage_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('analyze computes tag coverage', () {
    final spots = [
      TrainingPackSpot(id: '1', tags: ['push', 'call']),
      TrainingPackSpot(id: '2', tags: ['push']),
    ];
    final pack = TrainingPackModel(id: 'p1', title: 'Pack', spots: spots);
    final tracker = SkillTagCoverageTracker();
    final report = tracker.analyze(pack);
    expect(report.totalSpots, 2);
    expect(report.tagCounts['push'], 2);
    expect(report.tagCounts['call'], 1);
    final aggregate = tracker.aggregateReport;
    expect(aggregate.totalSpots, 2);
    expect(aggregate.tagCounts['push'], 2);
    expect(aggregate.tagCounts['call'], 1);
  });
}
