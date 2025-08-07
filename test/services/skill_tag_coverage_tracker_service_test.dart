import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/services/skill_tag_coverage_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SkillTagCoverageTrackerService.instance.reset();
  });

  test('logPack increments counts and normalizes tags', () async {
    final service = SkillTagCoverageTrackerService.instance;
    await service.logPack(
      TrainingPackModel(
        id: 'p1',
        title: 'P1',
        spots: const [],
        tags: const ['A', 'b', 'A'],
      ),
    );
    await service.logPack(
      TrainingPackModel(
        id: 'p2',
        title: 'P2',
        spots: const [],
        tags: const ['b', 'c'],
      ),
    );

    final counts = await service.getTagUsageCount();
    expect(counts['a'], 1);
    expect(counts['b'], 2);
    expect(counts['c'], 1);
    expect(counts.containsKey('A'), isFalse);
  });

  test('getUncoveredTags returns missing required tags', () async {
    final service = SkillTagCoverageTrackerService.instance;
    await service.logPack(
      TrainingPackModel(
        id: 'p1',
        title: 'P1',
        spots: const [],
        tags: const ['a'],
      ),
    );

    final uncovered =
        await service.getUncoveredTags({'a', 'b', 'C'});
    expect(uncovered, containsAll(['b', 'c']));
    expect(uncovered.contains('a'), isFalse);
  });
}
