import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/skill_tag_coverage_tracker_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logPack updates counts and identifies uncovered tags', () async {
    final service = SkillTagCoverageTrackerService();
    final pack = TrainingPackModel(
      id: 'p1',
      title: 'P1',
      spots: [
        TrainingPackSpot(id: 's1', tags: ['a', 'b']),
        TrainingPackSpot(id: 's2', tags: ['b']),
      ],
    );
    await service.logPack(pack);

    final counts = await service.getTagUsageCount();
    expect(counts['a'], 1);
    expect(counts['b'], 2);

    final uncovered = await service.getUncoveredTags({'a', 'b', 'c'});
    expect(uncovered, contains('c'));
    expect(uncovered, isNot(contains('a')));
    expect(uncovered, isNot(contains('b')));
  });
}

