import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/learning_track_section_model.dart';

void main() {
  test('parses sections from json', () {
    final json = {
      'id': 'p',
      'title': 'Path',
      'description': '',
      'stages': [
        {
          'id': 's1',
          'title': 'S1',
          'description': '',
          'packId': 'p1',
          'requiredAccuracy': 80,
          'minHands': 10,
        },
        {
          'id': 's2',
          'title': 'S2',
          'description': '',
          'packId': 'p2',
          'requiredAccuracy': 70,
          'minHands': 5,
        },
      ],
      'sections': [
        {
          'id': 'sec1',
          'title': 'Section 1',
          'description': 'desc',
          'stageIds': ['s1', 's2'],
        },
      ],
    };

    final tpl = LearningPathTemplateV2.fromJson(json);
    expect(tpl.sections.length, 1);
    final sec = tpl.sections.first;
    expect(sec.id, 'sec1');
    expect(sec.stageIds, ['s1', 's2']);
  });

  test('toJson includes sections', () {
    const section = LearningTrackSectionModel(
      id: 'sec',
      title: 'T',
      description: '',
      stageIds: ['s1'],
    );
    const tpl = LearningPathTemplateV2(
      id: 'p',
      title: 't',
      description: '',
      stages: [],
      sections: [section],
    );
    final map = tpl.toJson();
    expect(map['sections'], isNotNull);
    expect((map['sections'] as List).length, 1);
  });
}
