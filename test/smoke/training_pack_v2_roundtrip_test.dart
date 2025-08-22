@TestOn('vm')
import 'dart:convert';
import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';

void main() {
  test('TrainingPackTemplateV2 JSON roundtrip', () {
    final src = TrainingPackTemplateV2(
      id: 't_pack_1',
      name: 'Smoke Pack',
      level: TrainingPackLevel.beginner,
      type: TrainingType.theory,
      tags: const ['preflop','icm'],
      spots: const [],
    );

    final jsonStr = jsonEncode(src.toJson());
    final back = TrainingPackTemplateV2.fromJson(jsonDecode(jsonStr));

    expect(back.id, src.id);
    expect(back.name, src.name);
    expect(back.level, src.level);
    expect(back.type, src.type);
    expect(back.tags, src.tags);
    expect(back.spots, isEmpty);
  });
}
