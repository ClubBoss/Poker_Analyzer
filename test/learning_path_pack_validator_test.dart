import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/generation/learning_path_pack_validator.dart';
import 'package:poker_analyzer/core/training/generation/learning_path_library_generator.dart';
import 'package:poker_analyzer/core/training/generation/learning_path_stage_template_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('packs');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('validate passes when packs exist', () {
    File('${dir.path}/main.yaml').writeAsStringSync('');
    File('${dir.path}/sub.yaml').writeAsStringSync('');
    const stages = [
      LearningPathStageTemplateInput(
        id: 's1',
        title: 'Stage',
        packId: 'main',
        subStages: [
          SubStageTemplateInput(id: 'sub1', packId: 'sub', title: 'Sub'),
        ],
      ),
    ];
    final validator = LearningPathPackValidator();
    final result = validator.validate(stages, dir);
    expect(result, isEmpty);
  });

  test('validate reports missing stage pack', () {
    final validator = LearningPathPackValidator();
    const stages = [
      LearningPathStageTemplateInput(
        id: 's1',
        title: 'Stage',
        packId: 'missing',
      ),
    ];
    final result = validator.validate(stages, dir);
    expect(result, contains('Missing pack: missing'));
  });

  test('validate reports missing subStage pack', () {
    File('${dir.path}/main.yaml').writeAsStringSync('');
    const stages = [
      LearningPathStageTemplateInput(
        id: 's1',
        title: 'Stage',
        packId: 'main',
        subStages: [
          SubStageTemplateInput(id: 'sub1', packId: 'other', title: 'Sub'),
        ],
      ),
    ];
    final validator = LearningPathPackValidator();
    final result = validator.validate(stages, dir);
    expect(result, contains('Missing subStage pack: other'));
  });
}
