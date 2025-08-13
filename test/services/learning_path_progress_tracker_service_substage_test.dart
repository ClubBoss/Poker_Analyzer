import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/sub_stage_model.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_progress_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tracker = LearningPathProgressTrackerService();

  final template = LearningPathTemplateV2(
    id: 'p',
    title: 'Path',
    description: '',
    stages: [
      LearningPathStageModel(
        id: 's1',
        title: 'Stage',
        description: '',
        packId: 'main',
        requiredAccuracy: 0,
        minHands: 0,
        subStages: [
          SubStageModel(
            id: 'p1',
            title: 'A',
            minHands: 5,
            requiredAccuracy: 80,
          ),
          SubStageModel(
            id: 'p2',
            title: 'B',
            minHands: 5,
            requiredAccuracy: 60,
          ),
        ],
      )
    ],
  );

  final logs = [
    SessionLog(
      tags: const [],
      sessionId: '1',
      templateId: 'p1',
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
      correctCount: 4,
      mistakeCount: 1,
    ),
    SessionLog(
      tags: const [],
      sessionId: '2',
      templateId: 'p2',
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
      correctCount: 3,
      mistakeCount: 2,
    ),
  ];

  test('computeProgressStrings aggregates subStages', () {
    final progress = tracker.computeProgressStrings(template, logs);
    expect(progress['s1'], '10 / 10 рук · 70%');
  });

  test('isPathCompleted true when all subStages complete', () {
    final aggregated = tracker.aggregateLogsByPack(logs);
    final done = tracker.isPathCompleted(template, aggregated);
    expect(done, isTrue);
  });
}
