import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_advisor.dart';
import 'package:poker_analyzer/models/v3/lesson_step.dart';
import 'package:poker_analyzer/models/v3/lesson_track.dart';
import 'package:poker_analyzer/models/mistake_profile.dart';

void main() {
  final steps = [
    LessonStep(
      id: 's1',
      title: 'one',
      introText: '',
      linkedPackId: 'p',
      meta: const {
        'schemaVersion': '3.0.0',
        'tags': ['a'],
      },
    ),
    LessonStep(
      id: 's2',
      title: 'two',
      introText: '',
      linkedPackId: 'p',
      meta: const {
        'schemaVersion': '3.0.0',
        'tags': ['b'],
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
      title: 'T1',
      description: '',
      stepIds: ['s1', 's2'],
    ),
    const LessonTrack(id: 't2', title: 'T2', description: '', stepIds: ['s3']),
  ];

  test('prefers step with matching weak tag', () {
    final advisor = LearningPathAdvisor(steps: steps);
    final step = advisor.recommendNextStep(
      availableTracks: tracks,
      completedSteps: const {},
      profile: const MistakeProfile(weakTags: {'b'}),
    );
    expect(step?.id, 's2');
  });

  test('prefers step from started track', () {
    final advisor = LearningPathAdvisor(steps: steps);
    final step = advisor.recommendNextStep(
      availableTracks: tracks,
      completedSteps: {
        'l': {'s1'},
      },
      profile: const MistakeProfile(weakTags: {}),
    );
    expect(step?.id, 's2');
  });

  test('returns null when all steps completed', () {
    final advisor = LearningPathAdvisor(steps: steps);
    final step = advisor.recommendNextStep(
      availableTracks: tracks,
      completedSteps: {
        'l': {'s1', 's2', 's3'},
      },
      profile: const MistakeProfile(weakTags: {'a'}),
    );
    expect(step, isNull);
  });
}
