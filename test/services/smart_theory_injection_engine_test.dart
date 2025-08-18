import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/stage_type.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/training_spot_attempt.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';
import 'package:poker_analyzer/services/mistake_tag_history_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/booster_cooldown_scheduler.dart';
import 'package:poker_analyzer/services/smart_theory_injection_engine.dart';
import 'package:poker_analyzer/services/skill_gap_detector_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

class _FakeDetector extends SkillGapDetectorService {
  final List<String> tags;
  _FakeDetector(this.tags);
  @override
  Future<List<String>> getMissingTags({double threshold = 0.1}) async => tags;
}

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);
  @override
  List<TheoryMiniLessonNode> get all => lessons;
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((l) => l.id == id, orElse: () => null);
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [
    for (final t in tags) ...lessons.where((l) => l.tags.contains(t)),
  ];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [
    for (final t in tags) ...lessons.where((l) => l.tags.contains(t)),
  ];
}

TrainingSpotAttempt _attempt(String id) {
  final spot = TrainingPackSpot(id: id, hand: HandData());
  return TrainingSpotAttempt(
    spot: spot,
    userAction: 'fold',
    correctAction: 'push',
    evDiff: -1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    LearningPathStageLibrary.instance.clear();
    MiniLessonProgressTracker.instance.onLessonCompleted.listen((_) {});
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    BoosterCooldownScheduler.instance.resetForTest();
  });

  test('returns mini lesson for recent skill gap mistake', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'm1',
      title: 'Mini',
      content: 'x',
      tags: ['overpush'],
    );
    final library = _FakeLibrary([lesson]);
    final detector = _FakeDetector(['overpush']);
    LearningPathStageLibrary.instance.add(
      const LearningPathStageModel(
        id: 's1',
        title: 'S',
        description: '',
        packId: 'p1',
        requiredAccuracy: 0,
        minHands: 0,
        tags: ['overpush'],
        type: StageType.practice,
      ),
    );
    await MistakeTagHistoryService.logTags('p1', _attempt('spot1'), [
      MistakeTag.overpush,
    ]);

    final engine = SmartTheoryInjectionEngine(
      detector: detector,
      library: library,
      progress: MiniLessonProgressTracker.instance,
      cooldown: BoosterCooldownScheduler.instance,
    );

    final res = await engine.getInjectionCandidate('s1');
    expect(res?.id, 'm1');
  });

  test('returns null when cooldown active or tag seen', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'm1',
      title: 'Mini',
      content: 'x',
      tags: ['overpush'],
    );
    final library = _FakeLibrary([lesson]);
    final detector = _FakeDetector(['overpush']);
    LearningPathStageLibrary.instance.add(
      const LearningPathStageModel(
        id: 's1',
        title: 'S',
        description: '',
        packId: 'p1',
        requiredAccuracy: 0,
        minHands: 0,
        tags: ['overpush'],
        type: StageType.practice,
      ),
    );
    await MistakeTagHistoryService.logTags('p1', _attempt('spot1'), [
      MistakeTag.overpush,
    ]);
    await MiniLessonProgressTracker.instance.markViewed('m1');
    await BoosterCooldownScheduler.instance.recordDismissed('skill_gap');

    final engine = SmartTheoryInjectionEngine(
      detector: detector,
      library: library,
      progress: MiniLessonProgressTracker.instance,
      cooldown: BoosterCooldownScheduler.instance,
    );

    final res = await engine.getInjectionCandidate('s1');
    expect(res, isNull);
  });
}
