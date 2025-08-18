import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_filter_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  final pack1 = TrainingPackTemplateV2(
    id: 'p1',
    name: 'Pack 1',
    trainingType: TrainingType.pushFold,
    meta: {'theme': 'pushfold'},
  );
  final pack2 = TrainingPackTemplateV2(
    id: 'p2',
    name: 'Pack 2',
    trainingType: TrainingType.pushFold,
    meta: {
      'theme': ['3bet', 'ICM'],
    },
  );
  final pack3 = TrainingPackTemplateV2(
    id: 'p3',
    name: 'Pack 3',
    trainingType: TrainingType.pushFold,
  );

  test('filters by theme string case-insensitively', () {
    final res = const PackFilterService().filter(
      templates: [pack1, pack2, pack3],
      themes: {'PushFold'},
    );
    expect(res.map((e) => e.id), ['p1']);
  });

  test('filters by theme list case-insensitively', () {
    final res = const PackFilterService().filter(
      templates: [pack1, pack2, pack3],
      themes: {'icm'},
    );
    expect(res.map((e) => e.id), ['p2']);
  });
}
