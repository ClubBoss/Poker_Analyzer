import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_sub_stage.dart';

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
          'title': 'A',
          'packId': 'p1',
          'requiredAccuracy': 70,
          'minHands': 5,
        },
        {
          'title': 'B',
          'packId': 'p2'
        }
      ]
    };
    final stage = LearningPathStageModel.fromJson(json);
    expect(stage.subStages.length, 2);
    expect(stage.subStages.first.title, 'A');
    expect(stage.subStages.first.requiredAccuracy, 70);
    expect(stage.subStages.last.minHands, isNull);
  });
}
