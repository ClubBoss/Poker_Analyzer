import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/pack_library.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/learning_path_template_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingPackTemplateV2 pack(
    String id, {
    TrainingType type = TrainingType.pushFold,
  }) =>
      TrainingPackTemplateV2(id: id, name: id, trainingType: type);

  LearningPathStageModel stage(
    String id,
    String packId, {
    List<String>? tags,
    String? theoryPackId,
  }) =>
      LearningPathStageModel(
        id: id,
        title: id,
        description: '',
        packId: packId,
        requiredAccuracy: 80,
        minHands: 10,
        tags: tags ?? const ['t'],
        theoryPackId: theoryPackId,
      );

  test('validate detects issues', () {
    PackLibrary.main.clear();
    PackLibrary.staging.clear();
    PackLibrary.main.addAll([
      pack('p1'),
      pack('t1', type: TrainingType.theory),
    ]);

    final path = LearningPathTemplateV2(
      id: 'path',
      title: 'Path',
      description: '',
      stages: [
        stage('s1', 'p1', tags: []),
        stage('s1', 't1'),
        stage('s3', 'missing'),
        stage('s4', 't1'),
      ],
    );

    final issues = const LearningPathTemplateValidator().validate(path);
    final messages = issues.map((e) => e.message).toList();
    expect(messages, contains('missing_tags:s1'));
    expect(messages, contains('duplicate_id:s1'));
    expect(messages, contains('missing_pack:missing'));
    expect(messages, contains('missing_theory_pack_id:s4'));
  });

  test('validate returns empty list for valid path', () {
    PackLibrary.main.clear();
    PackLibrary.main.add(pack('p1'));
    final path = LearningPathTemplateV2(
      id: 'path',
      title: 'Path',
      description: '',
      stages: [stage('s1', 'p1')],
    );
    final issues = const LearningPathTemplateValidator().validate(path);
    expect(issues, isEmpty);
  });
}
