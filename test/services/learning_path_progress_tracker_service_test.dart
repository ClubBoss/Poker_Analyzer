import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_progress_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tracker = LearningPathProgressTrackerService();

  LearningPathTemplateV2 path0() => const LearningPathTemplateV2(
    id: 'p',
    title: 'Path',
    description: '',
    stages: [
      LearningPathStageModel(
        id: 's1',
        title: 'Stage 1',
        description: '',
        packId: 'pack1',
        requiredAccuracy: 80,
        minHands: 10,
      ),
      LearningPathStageModel(
        id: 's2',
        title: 'Stage 2',
        description: '',
        packId: 'pack2',
        requiredAccuracy: 70,
        minHands: 5,
      ),
    ],
  );

  List<SessionLog> logs0() => [
    SessionLog(
      tags: const [],
      sessionId: 'l1',
      templateId: 'pack1',
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
      correctCount: 8,
      mistakeCount: 2,
    ),
    SessionLog(
      tags: const [],
      sessionId: 'l2',
      templateId: 'pack2',
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
      correctCount: 4,
      mistakeCount: 1,
    ),
  ];

  test('aggregateLogsByPack sums counts', () {
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: 'a',
        templateId: 'pack1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 3,
        mistakeCount: 1,
      ),
      SessionLog(
        tags: const [],
        sessionId: 'b',
        templateId: 'pack1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 2,
        mistakeCount: 4,
      ),
    ];
    final map = tracker.aggregateLogsByPack(logs);
    expect(map['pack1']?.correctCount, 5);
    expect(map['pack1']?.mistakeCount, 5);
  });

  test('computeProgressStrings returns formatted strings', () {
    final path = path0();
    final logs = logs0();
    final progress = tracker.computeProgressStrings(path, logs);
    expect(progress['s1'], '10 / 10 рук · 80%');
    expect(progress['s2'], '5 / 5 рук · 80%');
  });

  test('isPathCompleted returns true when all stages passed', () {
    final path = path0();
    final aggregated = tracker.aggregateLogsByPack(logs0());
    final ok = tracker.isPathCompleted(path, aggregated);
    expect(ok, isTrue);
  });

  test('isPathCompleted false when requirements not met', () {
    final path = path0();
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: 'l1',
        templateId: 'pack1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 5,
        mistakeCount: 5,
      ),
    ];
    final aggregated = tracker.aggregateLogsByPack(logs);
    final ok = tracker.isPathCompleted(path, aggregated);
    expect(ok, isFalse);
  });
}
