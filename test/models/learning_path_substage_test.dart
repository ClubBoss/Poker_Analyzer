import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';

void main() {
  test('parses subStages from json', () {
    final json = {
      'id': 's1',
      'title': 'Stage',
      'description': '',
      'packId': 'main',
      'requiredAccuracy': 80,
      'minHands': 10,
      'subStages': [
        {
          'id': 'p1',
          'packId': 'p1',
          'title': 'A',
          'description': 'first',
          'requiredAccuracy': 70,
          'minHands': 5,
          'unlockCondition': {'dependsOn': 'p0', 'minAccuracy': 60},
        },
        {'id': 'p2', 'packId': 'p2', 'title': 'B'},
      ],
    };
    final stage = LearningPathStageModel.fromJson(json);
    expect(stage.subStages.length, 2);
    expect(stage.subStages.first.id, 'p1');
    expect(stage.subStages.first.title, 'A');
    expect(stage.subStages.first.description, 'first');
    expect(stage.subStages.first.requiredAccuracy, 70);
    expect(stage.subStages.first.packId, 'p1');
    expect(stage.subStages.first.unlockCondition?.dependsOn, 'p0');
    expect(stage.subStages.first.unlockCondition?.minAccuracy, 60);
    expect(stage.subStages.first.objectives, isEmpty);
    expect(stage.subStages.last.minHands, 0);
  });

  test('parses subStages from yaml', () {
    const yamlStr = '''
id: s1
title: Stage
description: ''
packId: main
requiredAccuracy: 80
minHands: 10
subStages:
  - id: p1
    packId: p1
    title: A
    description: first
    requiredAccuracy: 70
    minHands: 5
    unlockCondition:
      dependsOn: p0
      minAccuracy: 60
  - id: p2
    packId: p2
    title: B
''';
    final map = const YamlReader().read(yamlStr);
    final stage = LearningPathStageModel.fromYaml(map);
    expect(stage.subStages.length, 2);
    expect(stage.subStages.first.id, 'p1');
    expect(stage.subStages.first.title, 'A');
    expect(stage.subStages.first.description, 'first');
    expect(stage.subStages.first.requiredAccuracy, 70);
    expect(stage.subStages.first.packId, 'p1');
    expect(stage.subStages.first.unlockCondition?.dependsOn, 'p0');
    expect(stage.subStages.first.unlockCondition?.minAccuracy, 60);
    expect(stage.subStages.first.objectives, isEmpty);
    expect(stage.subStages.last.id, 'p2');
    expect(stage.subStages.last.packId, 'p2');
  });
}
