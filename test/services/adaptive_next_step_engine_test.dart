import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/adaptive_next_step_engine.dart';
import 'package:poker_analyzer/models/v3/lesson_step.dart';
import 'package:poker_analyzer/models/v3/lesson_track.dart';
import 'package:poker_analyzer/services/lesson_progress_tracker_service.dart';
import 'package:poker_analyzer/services/tag_coverage_service.dart';
import 'package:poker_analyzer/services/lesson_step_tag_service.dart';

class _FakeTagProvider implements LessonStepTagProvider {
  final Map<String, List<String>> map;
  _FakeTagProvider(this.map);
  @override
  Future<Map<String, List<String>>> getTagsByStepId() async => map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final steps = [
    LessonStep(
      id: 's1',
      title: 'one',
      introText: '',
      linkedPackId: 'p',
      meta: const {
        'schemaVersion': '3.0.0',
        'tags': ['a']
      },
    ),
    LessonStep(
      id: 's2',
      title: 'two',
      introText: '',
      linkedPackId: 'p',
      meta: const {
        'schemaVersion': '3.0.0',
        'tags': ['b']
      },
    ),
    LessonStep(
      id: 's3',
      title: 'three',
      introText: '',
      linkedPackId: 'p',
      meta: const {'schemaVersion': '3.0.0'},
    ),
  ];

  final tracks = [
    const LessonTrack(
      id: 't1',
      title: 'Track',
      description: '',
      stepIds: ['s2'],
    ),
  ];

  test('suggestNextStep prefers track steps', () async {
    SharedPreferences.setMockInitialValues({
      'lesson_selected_track': 't1',
    });
    await LessonProgressTrackerService.instance.load();
    final provider = _FakeTagProvider({
      's1': ['a'],
      's2': ['b'],
    });
    final engine = AdaptiveNextStepEngine(
      steps: steps,
      tracks: tracks,
      tagProvider: provider,
      coverage: TagCoverageService(provider: provider),
    );
    final next = await engine.suggestNextStep();
    expect(next, 's2');
  });

  test('suggestNextStep skips recent steps', () async {
    SharedPreferences.setMockInitialValues({
      'lesson_selected_track': 't1',
      'lesson_recent_steps': ['s2'],
    });
    await LessonProgressTrackerService.instance.load();
    final provider = _FakeTagProvider({
      's1': ['a'],
      's2': ['b'],
    });
    final engine = AdaptiveNextStepEngine(
      steps: steps,
      tracks: tracks,
      tagProvider: provider,
      coverage: TagCoverageService(provider: provider),
    );
    final next = await engine.suggestNextStep();
    expect(next, 's1');
  });
}
