import 'package:test/test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_progress_tracker.dart';

void main() {
  final template = LearningPathTemplateV2(
    id: 'p',
    title: 'Path',
    description: '',
    stages: const [
      LearningPathStageModel(
        id: 's1',
        title: 'S1',
        description: '',
        packId: 'starter_pushfold_10bb',
        requiredAccuracy: 0,
        minHands: 0,
      ),
      LearningPathStageModel(
        id: 's2',
        title: 'S2',
        description: '',
        packId: 'starter_pushfold_15bb',
        requiredAccuracy: 0,
        minHands: 0,
      ),
    ],
  );

  late Map<String, double> progress;
  late LearningPathProgressTracker tracker;

  setUp(() {
    progress = {'s1': 0.5, 's2': 1.0};
    tracker = LearningPathProgressTracker(
      getPath: () async => template,
      getStageProgress: (id) async => progress[id] ?? 0.0,
    );
  });

  test('getStageProgressMap returns stage map', () async {
    final map = await tracker.getStageProgressMap();
    expect(map, progress);
  });

  test('getOverallProgress averages stages', () async {
    final overall = await tracker.getOverallProgress();
    expect(overall, closeTo(0.75, 0.0001));
  });

  test('results are cached for 5 minutes', () async {
    final first = await tracker.getStageProgressMap();
    progress['s1'] = 1.0;
    final second = await tracker.getStageProgressMap();
    expect(second['s1'], first['s1']);
  });
}
