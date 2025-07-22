import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_search_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  test('fuzzy search by title and tags', () {
    final t1 = TrainingPackTemplateV2(
      id: '1',
      name: 'Aggressive Push',
      trainingType: TrainingType.pushFold,
      tags: ['push', 'aggression'],
    );
    final t2 = TrainingPackTemplateV2(
      id: '2',
      name: 'ICM Defense',
      trainingType: TrainingType.icm,
      tags: ['icm', 'call'],
    );

    final engine = PackSearchEngine(library: [t1, t2]);
    final res1 = engine.search('agr push');
    expect(res1.first, t1);
    final res2 = engine.search('icm');
    expect(res2, contains(t2));
  });
}
