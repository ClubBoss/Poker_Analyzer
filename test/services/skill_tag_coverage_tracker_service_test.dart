import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/skill_tag_coverage_tracker_service.dart';
import 'package:poker_analyzer/services/training_pack_library_service.dart';

class _FakeLibraryService extends TrainingPackLibraryService {
  final List<TrainingPackModel> packs;
  _FakeLibraryService(this.packs);

  @override
  Future<List<TrainingPackModel>> getAllPacks() async => packs;
}

void main() {
  test('generateReport counts tags and finds underrepresented tags', () async {
    final library = _FakeLibraryService([
      TrainingPackModel(
        id: 'p1',
        title: 'P1',
        spots: [
          TrainingPackSpot(id: 's1', tags: ['a']),
          TrainingPackSpot(id: 's2', tags: ['b', 'c']),
        ],
      ),
      TrainingPackModel(
        id: 'p2',
        title: 'P2',
        spots: [
          TrainingPackSpot(id: 's3', tags: ['a']),
        ],
      ),
    ]);

    final service = SkillTagCoverageTrackerService(
      library: library,
      allSkillTags: {'a', 'b', 'c', 'd'},
      underrepresentedThreshold: 2,
    );

    final report = await service.generateReport();
    expect(report.tagCounts['a'], 2);
    expect(report.tagCounts['b'], 1);
    expect(report.tagCounts['c'], 1);
    expect(report.underrepresentedTags, containsAll(['b', 'c', 'd']));
    expect(report.underrepresentedTags, isNot(contains('a')));
  });
}
