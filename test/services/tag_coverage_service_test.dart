import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/tag_coverage_service.dart';
import 'package:poker_analyzer/services/lesson_step_tag_service.dart';

class _FakeStepTagService implements LessonStepTagProvider {
  final Map<String, List<String>> map;
  _FakeStepTagService(this.map);

  @override
  Future<Map<String, List<String>>> getTagsByStepId() async => map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computeTagCoverage counts tags per step without duplicates', () async {
    final provider = _FakeStepTagService({
      'step1': ['a', 'b', 'a'],
      'step2': ['b', 'c'],
      'step3': [],
    });

    final service = TagCoverageService(provider: provider);
    final coverage = await service.computeTagCoverage();

    expect(coverage.length, 3);
    expect(coverage['a'], 1);
    expect(coverage['b'], 2);
    expect(coverage['c'], 1);
  });
}
