import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_library_validator.dart';
import 'package:poker_analyzer/services/learning_path_library.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/pack_library.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingPackTemplateV2 pack(
    String id, {
    TrainingType type = TrainingType.pushFold,
  }) => TrainingPackTemplateV2(id: id, name: id, trainingType: type);

  LearningPathStageModel stage(
    String id,
    String packId, {
    List<String>? tags,
    String? theoryPackId,
  }) => LearningPathStageModel(
    id: id,
    title: id,
    description: '',
    packId: packId,
    requiredAccuracy: 80,
    minHands: 10,
    tags: tags ?? const ['t'],
    theoryPackId: theoryPackId,
  );

  test('validateAll aggregates issues from multiple paths', () {
    PackLibrary.main.clear();
    PackLibrary.main.add(pack('p1'));

    LearningPathLibrary.staging.clear();
    LearningPathLibrary.staging.add(
      LearningPathTemplateV2(
        id: 'a',
        title: 'A',
        description: '',
        stages: [stage('s1', 'p1', tags: [])],
      ),
    );
    LearningPathLibrary.staging.add(
      LearningPathTemplateV2(
        id: 'b',
        title: 'B',
        description: '',
        stages: [stage('s1', 'p1')],
      ),
    );

    final issues = const LearningPathLibraryValidator().validateAll(
      LearningPathLibrary.staging,
    );
    expect(issues.length, 1);
    expect(issues.first.$1, 'a');
    expect(issues.first.$2, 'missing_tags:s1');
  });
}
