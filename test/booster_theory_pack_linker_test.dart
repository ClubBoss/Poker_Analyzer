import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_theory_pack_linker.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

LearningPathStageModel _stage(String id, String tag) => LearningPathStageModel(
      id: id,
      title: id,
      description: '',
      packId: 'pack_$id',
      requiredAccuracy: 80,
      minHands: 10,
      tags: [tag],
    );

TrainingPackTemplateV2 _theory(String id, String tag) => TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.theory,
      tags: [tag],
      spots: [TrainingPackSpot(id: 's', type: 'theory', hand: HandData())],
      spotCount: 1,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('links theory pack by tag', () {
    final template = LearningPathTemplateV2(
      id: 'p',
      title: 'Path',
      description: '',
      stages: [_stage('s1', 'push'), _stage('s2', 'call')],
      sections: const [],
      tags: const [],
    );

    final library = [_theory('t1', 'push')];

    final updated = const BoosterTheoryPackLinker().link(template, library);

    expect(updated.stages.first.theoryPackId, 't1');
    expect(updated.stages.last.theoryPackId, isNull);
  });
}
