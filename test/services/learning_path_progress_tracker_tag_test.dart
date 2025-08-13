import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/learning_path_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tpl1 = TrainingPackTemplateV2(
    id: 'p1',
    name: 'P1',
    trainingType: TrainingType.pushFold,
    tags: ['btn'],
    spots: [
      TrainingPackSpot(id: 's1', hand: HandData(), tags: ['btn', 'icm'])
    ],
  );
  final tpl2 = TrainingPackTemplateV2(
    id: 'p2',
    name: 'P2',
    trainingType: TrainingType.pushFold,
    tags: ['sb'],
    spots: [
      TrainingPackSpot(id: 's2', hand: HandData(), tags: ['sb'])
    ],
  );

  final path = LearningPathTemplateV2(
    id: 'path',
    title: 'Path',
    description: '',
    stages: const [
      LearningPathStageModel(
        id: 's1',
        title: 'S1',
        description: '',
        packId: 'p1',
        requiredAccuracy: 0,
        minHands: 0,
      ),
      LearningPathStageModel(
        id: 's2',
        title: 'S2',
        description: '',
        packId: 'p2',
        requiredAccuracy: 0,
        minHands: 0,
      ),
    ],
  );

  test('getTagProgressPerStage returns tag progress map', () async {
    final tracker = LearningPathProgressTracker(
      getPath: () async => path,
      getStageProgress: (_) async => 0,
      getPack: (id) async => id == 'p1' ? tpl1 : tpl2,
      getTagProgress: (tag) async {
        if (tag == 'btn') return 1.0;
        if (tag == 'icm') return 0.5;
        return 0.2;
      },
    );

    final map = await tracker.getTagProgressPerStage();
    expect(map['s1']?['btn'], 1.0);
    expect(map['s1']?['icm'], 0.5);
    expect(map['s2']?['sb'], 0.2);
  });
}
